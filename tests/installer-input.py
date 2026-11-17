#!/usr/bin/env python3
"""Real Calamares input regression; isolated Fedora CI only, no install jobs.

Run inside tests/ekran.sh's disposable Wayland + D-Bus session. AT-SPI reads
actual widgets, while a virtual pointer and wtype deliver real input events.
No clipboard, block devices, mount operations or account creation are used.
"""
import json
import os
from pathlib import Path
import shutil
import socket
import struct
import subprocess
import sys
import tempfile
import time


def virtual_pointer():
    """Keep a pointer device alive in the disposable headless compositor.

    IPC cursor commands alone do not advertise wl_seat pointer capability.
    The tiny wire client keeps the device alive and delivers its mouse events.
    Protocol: swaywm/wlr-protocols/unstable/wlr-virtual-pointer-unstable-v1.xml
    """
    connection = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    connection.settimeout(5)
    connection.connect(str(Path(os.environ['XDG_RUNTIME_DIR']) / os.environ['WAYLAND_DISPLAY']))

    def send(obj, opcode, payload):
        connection.sendall(struct.pack('=II', obj, ((8 + len(payload)) << 16) | opcode) + payload)

    def receive(count):
        data = b''
        while len(data) < count:
            part = connection.recv(count - len(data))
            if not part:
                raise RuntimeError('Headless compositor disconnected')
            data += part
        return data

    def roundtrip(callback, collect=False):
        send(1, 0, struct.pack('=I', callback))  # wl_display.sync
        globals_ = {}
        while True:
            obj, word = struct.unpack('=II', receive(8))
            size, opcode = word >> 16, word & 65535
            if not 8 <= size <= 65535:
                raise RuntimeError('Invalid Wayland fixture response')
            payload = receive(size - 8)
            if obj == 1 and opcode == 0:
                raise RuntimeError('Wayland rejected virtual pointer fixture')
            if collect and obj == 2 and opcode == 0:
                name, length = struct.unpack_from('=II', payload)
                interface = payload[8:8 + length - 1].decode('ascii')
                globals_[interface] = name
            if obj == callback and opcode == 0:
                return globals_

    try:
        send(1, 1, struct.pack('=I', 2))  # wl_display.get_registry
        globals_ = roundtrip(3, collect=True)
        interface = b'zwlr_virtual_pointer_manager_v1\0'
        name = globals_.get(interface[:-1].decode())
        if name is None:
            raise RuntimeError('Virtual pointer protocol unavailable in isolated compositor')
        padded = interface + b'\0' * (-len(interface) % 4)
        send(2, 0, struct.pack('=II', name, len(interface)) + padded + struct.pack('=II', 1, 4))
        send(4, 0, struct.pack('=II', 0, 5))  # create pointer on the default seat
        roundtrip(6)
        return connection, send
    except Exception:
        connection.close()
        raise


def main():
    if sys.platform != 'linux' or os.environ.get('VABU_TEST_ISOLATED') != '1':
        raise SystemExit('Only runs in isolated Linux CI.')
    import pyatspi

    out = Path(sys.argv[1]).resolve()
    out.mkdir(parents=True, exist_ok=True)
    source = Path(__file__).resolve().parents[1] / 'iso/root/etc/calamares'
    # Enforce the production module selection, including its exec counterpart.
    settings = (source / 'settings.conf').read_text()
    if settings.count('      - users\n') != 2 or '      - usersq\n' in settings:
        raise RuntimeError('Production show and exec must use the same native users module.')

    def run(*args):
        return subprocess.run(args, check=True, timeout=8, stdout=subprocess.DEVNULL)

    def walk(node):
        yield node
        for child in node:
            if child is not None:
                yield from walk(child)

    def nodes():
        desktop = pyatspi.Registry.getDesktop(0)
        for app in desktop:
            if app is not None and 'calamares' in app.name.lower():
                yield from walk(app)

    def wait_for(find, description, seconds=15):
        deadline = time.monotonic() + seconds
        while time.monotonic() < deadline:
            if proc.poll() is not None:
                raise RuntimeError('Calamares exited before ' + description)
            value = find()
            if value:
                return value
            time.sleep(.2)
        raise RuntimeError('Timed out: ' + description)

    def buttons():
        return [n for n in nodes() if n.getRole() == pyatspi.ROLE_PUSH_BUTTON
                and n.getState().contains(pyatspi.STATE_SHOWING)]

    def click(widget):
        rect = widget.queryComponent().getExtents(pyatspi.DESKTOP_COORDS)
        print('Click geometry:', widget.name, rect.x, rect.y, rect.width, rect.height, flush=True)
        if rect.width <= 0 or rect.height <= 0:
            raise RuntimeError('Widget has no clickable rectangle: ' + widget.name)
        # Send real virtual-device events, including frame boundaries, rather
        # than compositor cursor commands which can omit device capabilities.
        outputs = json.loads(subprocess.check_output(['swaymsg', '-t', 'get_outputs', '-r'], text=True))
        active = [o for o in outputs if o['active']]
        if len(active) != 1:
            raise RuntimeError('Input fixture requires one isolated output')
        bounds = active[0]['rect']
        timestamp = int(time.monotonic() * 1000) & 0xffffffff
        pointer_send(5, 1, struct.pack('=IIIII', timestamp,
                     rect.x + rect.width // 2, rect.y + rect.height // 2,
                     bounds['width'], bounds['height']))
        pointer_send(5, 4, b'')
        time.sleep(.15)
        pointer_send(5, 2, struct.pack('=III', timestamp + 1, 272, 1))
        pointer_send(5, 4, b'')
        time.sleep(.08)
        pointer_send(5, 2, struct.pack('=III', timestamp + 2, 272, 0))
        pointer_send(5, 4, b'')
        time.sleep(.2)

    def entries():
        return [n for n in nodes() if n.getRole() in (pyatspi.ROLE_TEXT, pyatspi.ROLE_ENTRY, pyatspi.ROLE_PASSWORD_TEXT)
                and n.getState().contains(pyatspi.STATE_EDITABLE)
                and n.getState().contains(pyatspi.STATE_SHOWING)
                and n.getState().contains(pyatspi.STATE_ENABLED)]

    def text(widget):
        return widget.queryText().getText(0, -1)

    def fill(widget, value, secret=False):
        click(widget)
        run('wtype', '-s', '300', '-M', 'ctrl', '-k', 'a', '-m', 'ctrl', '-k', 'BackSpace', '-d', '30', value)
        if secret:
            wait_for(lambda: widget.queryText().characterCount == len(value), 'password key input')
        else:
            wait_for(lambda: text(widget) == value, 'field key input: ' + value)

    def shot(name):
        run('grim', str(out / name))

    with tempfile.TemporaryDirectory(prefix='vabu-installer-input-') as folder:
        fixture = Path(folder) / 'calamares'
        shutil.copytree(source, fixture)
        # -c changes Calamares' entire data directory, not just settings.conf.
        # Reuse the installed, read-only Qt imports without copying vendor files.
        qml = Path('/usr/share/calamares/qml')
        if not qml.is_dir():
            raise RuntimeError('Installed Calamares QML imports are missing')
        (fixture / 'qml').symlink_to(qml, target_is_directory=True)
        # These are view-only modules. No exec sequence exists, even if a test
        # accidentally activates Next. In particular no partition/mount/users job.
        (fixture / 'settings.conf').write_text('''modules-search: [ local, /usr/lib64/calamares/modules ]
sequence:
  - show: [ users, summaryq ]
branding: vabu
prompt-install: true
dont-chroot: false
oem-setup: false
disable-cancel: false
disable-cancel-during-exec: true
hide-back-and-next-during-exec: true
quit-at-end: false
''')
        # The isolated account form is page zero, whereas production reaches
        # it after partition. Keep the same navigation controls visible without
        # requiring unrelated pages or any disk module in this regression.
        navigation = fixture / 'branding/vabu/calamares-navigation.qml'
        nav = navigation.read_text()
        nav = nav.replace('visible: ViewManager.backAndNextVisible && ViewManager.currentStepIndex > 0\n'
                          '                 && (ViewManager.nextEnabled || ViewManager.backEnabled)',
                          'visible: ViewManager.backAndNextVisible')
        navigation.write_text(nav)
        style = fixture / 'branding/vabu/stylesheet.qss'
        style.write_text(style.read_text().replace('/etc/calamares/branding/vabu/',
                                                   str(fixture / 'branding/vabu') + '/'))
        view = os.environ.get('VABU_TEST_VIEW', '')
        if view:
            navigation.write_text((source / 'branding/vabu/calamares-navigation.qml').read_text())
            if view not in ('welcomeq', 'finishedq'):
                raise RuntimeError('Unsupported view fixture')
            settings_file = fixture / 'settings.conf'
            settings_file.write_text(settings_file.read_text().replace('[ users, summaryq ]',
                                    '[ ' + view + ', users ]'))
            # Tests do not probe storage/network or execute the installer.
            (fixture / 'modules/welcomeq.conf').write_text('qmlSearch: both\nrequirements:\n  check: []\n  required: []\n')
        env = dict(os.environ, QT_LINUX_ACCESSIBILITY_ALWAYS_ON='1', QT_ACCESSIBILITY='1')
        with (out / 'calamares-input.log').open('w') as log:
            pointer, pointer_send = virtual_pointer()
            # A real desktop keeps a keyboard attached. wtype otherwise removes
            # the seat's final keyboard after every command, which resets focus
            # on Qt's embedded Wayland surfaces between Tab/Escape events.
            # This device sends no keys during the bounded test; teardown stops it.
            keyboard_device = subprocess.Popen(['wtype', '-s', '180000', '-k', 'Shift_L'],
                                               stdout=subprocess.DEVNULL, stderr=log)
            time.sleep(.3)
            proc = subprocess.Popen(['calamares', '-d', '-c', str(fixture)], env=env, stdout=log, stderr=subprocess.STDOUT)
            try:
                if view:
                    expected = 'Vabu’yu kur' if view == 'welcomeq' else 'Yeniden başlat'
                    wait_for(lambda: any(b.name == expected for b in buttons()), view + ' loaded')
                    time.sleep(.5)
                    shot('view.png')
                    if view == 'welcomeq':
                        combo = wait_for(lambda: next((n for n in nodes() if n.getRole() == pyatspi.ROLE_COMBO_BOX), None),
                                         'language chooser')
                        click(combo)
                        time.sleep(.3)
                        shot('language-popup.png')
                        run('wtype', '-s', '300', '-k', 'Escape')
                        time.sleep(.3)
                        shot('language-closed.png')
                        # Traverse to a real Qt button and activate with Space.
                        for _ in range(12):
                            run('wtype', '-s', '300', '-k', 'Tab')
                            time.sleep(.1)
                            target = next((b for b in buttons() if b.name == expected
                                           and b.getState().contains(pyatspi.STATE_FOCUSED)), None)
                            if target and target.getState().contains(pyatspi.STATE_FOCUSED):
                                shot('keyboard-focus.png')
                                run('wtype', '-s', '300', '-k', 'space')
                                wait_for(lambda: len(entries()) == 5, 'welcome keyboard navigation')
                                break
                        else:
                            raise RuntimeError('Welcome primary button is not keyboard reachable')
                    print('Installer view loaded and controls checked:', view)
                    return
                fields = wait_for(lambda: entries() if len(entries()) >= 5 else None, 'native account fields')
                if len(fields) != 5:
                    raise RuntimeError('Expected precisely three identity and two password fields; got ' + str(len(fields)))
                shot('50-kurulum-hesap-bos.png')
                full, login, host, password, repeat = fields
                fill(full, 'Vabu Input Test')
                fill(login, 'vabuinputtest')
                fill(host, 'vabu-input-test')
                # Synthetic strings only in this disposable, jobless test process.
                fill(password, 'Test-Only-9347', secret=True)
                fill(repeat, 'Different-9347', secret=True)
                # Next must remain disabled for different passwords. Read actual
                # navigation accessibility state, rather than assuming a screenshot passed.
                next_button = wait_for(lambda: next((b for b in buttons() if 'Next' in b.name or 'Install' in b.name), None), 'navigation button')
                if next_button.getState().contains(pyatspi.STATE_ENABLED):
                    raise RuntimeError('Next accepted mismatching passwords')
                shot('52-kurulum-parola-uyusmazligi.png')
                fill(repeat, 'Test-Only-9347', secret=True)
                wait_for(lambda: next_button.getState().contains(pyatspi.STATE_ENABLED), 'matching password validation')
                # Clicking a different field and returning with Tab must preserve text.
                click(full)
                run('wtype', '-s', '300', '-k', 'Tab')
                if [text(n) for n in (full, login, host)] != ['Vabu Input Test', 'vabuinputtest', 'vabu-input-test']:
                    raise RuntimeError('Identity text lost on focus change')
                # Real pointer + keyboard toggle on a native checkbox; restore its state.
                checkbox = next((n for n in nodes() if n.getRole() == pyatspi.ROLE_CHECK_BOX
                                 and n.getState().contains(pyatspi.STATE_SHOWING)
                                 and n.getState().contains(pyatspi.STATE_ENABLED)), None)
                if checkbox is None:
                    raise RuntimeError('No accessible account checkbox')
                was_checked = checkbox.getState().contains(pyatspi.STATE_CHECKED)
                click(checkbox)
                wait_for(lambda: checkbox.getState().contains(pyatspi.STATE_CHECKED) != was_checked,
                         'checkbox mouse toggle')
                run('wtype', '-s', '300', '-k', 'space')
                wait_for(lambda: checkbox.getState().contains(pyatspi.STATE_CHECKED) == was_checked,
                         'checkbox keyboard toggle')
                shot('51-kurulum-hesap-giris.png')
                # A laptop-sized output must keep all five fields reachable.
                run('swaymsg', 'output', 'HEADLESS-1', 'resolution', '2048x1536', 'scale', '2')
                time.sleep(1)
                bounds = json.loads(subprocess.check_output(['swaymsg', '-t', 'get_outputs', '-r'], text=True))[0]['rect']
                for widget in fields:
                    rect = widget.queryComponent().getExtents(pyatspi.DESKTOP_COORDS)
                    if not (rect.width >= 200 and rect.height >= 32 and rect.x >= 0 and rect.y >= 0
                            and rect.x + rect.width <= bounds['width'] and rect.y + rect.height <= bounds['height']):
                        raise RuntimeError('Account field outside laptop viewport: ' + str(rect))
                fill(host, 'vabu-small-screen')
                wait_for(lambda: next_button.getState().contains(pyatspi.STATE_ENABLED), 'small viewport validation')
                shot('53-kurulum-hesap-1024.png')
                # Only view modules exist. Next can show the summary but cannot install.
                click(next_button)
                wait_for(lambda: not entries(), 'summary navigation')
                time.sleep(.5)
                shot('54-kurulum-ozet.png')
                back = wait_for(lambda: next((b for b in buttons() if 'Back' in b.name), None), 'back button')
                click(back)
                wait_for(lambda: len(entries()) == 5, 'return to accounts')
                if text(entries()[2]) != 'vabu-small-screen':
                    raise RuntimeError('Account values lost when navigating back')
                run('swaymsg', 'output', 'HEADLESS-1', 'resolution', '2880x1800', 'scale', '2')
                (out / 'calamares-input.json').write_text(json.dumps({
                    'module': 'users', 'mouseAndKeyboard': True, 'fields': 5,
                    'mismatchedPasswordBlocked': True, 'matchingPasswordAccepted': True,
                    'checkboxMouseAndKeyboard': True, 'smallViewport': '1024x768',
                    'navigationPreservesInput': True,
                    'installJobs': [], 'installationStarted': False,
                }, indent=2) + '\n')
                print('Calamares input: mouse, keyboard, identity persistence and password validation passed.')
            except Exception:
                try:
                    shot('failed-calamares-input.png')
                    print((out / 'calamares-input.log').read_text()[-6000:])
                    print('Accessible controls:', [(n.getRoleName(), n.name) for n in nodes()
                           if n.getRole() in (pyatspi.ROLE_PUSH_BUTTON, pyatspi.ROLE_TEXT, pyatspi.ROLE_ENTRY, pyatspi.ROLE_PASSWORD_TEXT)])
                finally:
                    raise
            finally:
                proc.terminate()
                try:
                    proc.wait(timeout=5)
                except subprocess.TimeoutExpired:
                    proc.kill()
                    proc.wait(timeout=5)
                keyboard_device.terminate()
                keyboard_device.wait(timeout=5)
                pointer.close()


if __name__ == '__main__':
    main()
