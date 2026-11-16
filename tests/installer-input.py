#!/usr/bin/env python3
"""Real Calamares input regression; isolated Fedora CI only, no install jobs.

Run inside tests/ekran.sh's disposable Wayland + D-Bus session. AT-SPI reads
actual widgets, while sway and wtype deliver real mouse and keyboard events.
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
    The tiny wire client only creates a device; sway IPC still sends events.
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
        return connection
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
        run('swaymsg', 'seat', 'seat0', 'cursor', 'set',
            str(rect.x + rect.width // 2), str(rect.y + rect.height // 2))
        run('swaymsg', 'seat', 'seat0', 'cursor', 'press', 'button1')
        run('swaymsg', 'seat', 'seat0', 'cursor', 'release', 'button1')
        time.sleep(.2)

    def entries():
        return [n for n in nodes() if n.getRole() in (pyatspi.ROLE_ENTRY, pyatspi.ROLE_PASSWORD_TEXT)
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
  - show: [ welcomeq, users, summaryq ]
branding: vabu
prompt-install: true
dont-chroot: false
oem-setup: false
disable-cancel: false
disable-cancel-during-exec: true
hide-back-and-next-during-exec: true
quit-at-end: false
''')
        (fixture / 'modules/welcomeq.conf').write_text('''qmlSearch: both
requirements:
  required: []
  check: []
''')
        env = dict(os.environ, QT_LINUX_ACCESSIBILITY_ALWAYS_ON='1', QT_ACCESSIBILITY='1')
        with (out / 'calamares-input.log').open('w') as log:
            pointer = virtual_pointer()
            proc = subprocess.Popen(['calamares', '-d', '-c', str(fixture)], env=env, stdout=log, stderr=subprocess.STDOUT)
            try:
                start = wait_for(lambda: next((b for b in buttons() if b.name == 'Vabu’yu kur' and b.getState().contains(pyatspi.STATE_ENABLED)), None), 'welcome install button', 25)
                # Let the welcome page's 400 ms entry animation finish.
                time.sleep(.6)
                shot('50-kurulum-hosgeldin.png')
                click(start)
                fields = wait_for(lambda: entries() if len(entries()) >= 5 else None, 'native account fields')
                if len(fields) != 5:
                    raise RuntimeError('Expected precisely three identity and two password fields; got ' + str(len(fields)))
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
                fill(repeat, 'Test-Only-9347', secret=True)
                wait_for(lambda: next_button.getState().contains(pyatspi.STATE_ENABLED), 'matching password validation')
                # Clicking a different field and returning with Tab must preserve text.
                click(full)
                run('wtype', '-s', '300', '-k', 'Tab')
                if [text(n) for n in (full, login, host)] != ['Vabu Input Test', 'vabuinputtest', 'vabu-input-test']:
                    raise RuntimeError('Identity text lost on focus change')
                shot('51-kurulum-hesap-giris.png')
                (out / 'calamares-input.json').write_text(json.dumps({
                    'module': 'users', 'mouseAndKeyboard': True, 'fields': 5,
                    'mismatchedPasswordBlocked': True, 'matchingPasswordAccepted': True,
                    'installJobs': [], 'installationStarted': False,
                }, indent=2) + '\n')
                print('Calamares input: mouse, keyboard, identity persistence and password validation passed.')
            except Exception:
                try:
                    shot('failed-calamares-input.png')
                    print((out / 'calamares-input.log').read_text()[-6000:])
                    print('Accessible controls:', [(n.getRoleName(), n.name) for n in nodes()
                           if n.getRole() in (pyatspi.ROLE_PUSH_BUTTON, pyatspi.ROLE_ENTRY)])
                finally:
                    raise
            finally:
                proc.terminate()
                try:
                    proc.wait(timeout=5)
                except subprocess.TimeoutExpired:
                    proc.kill()
                    proc.wait(timeout=5)
                pointer.close()


if __name__ == '__main__':
    main()
