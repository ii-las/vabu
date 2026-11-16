#!/usr/bin/env python3
"""Offline regressions: all desktop/system commands are fakes in a private temp dir."""
import ast
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import time
import unittest
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]
HELPER = ROOT / 'rootfs/usr/libexec/vabu/display-preview'
MOCK = r'''#!/usr/bin/python3
import json, os, pathlib, re, subprocess, sys, tempfile
name = pathlib.Path(sys.argv[0]).name
args = sys.argv[1:]
with open(os.environ['MOCK_LOG'], 'a') as f:
    f.write(json.dumps([name, *args]) + '\n')
if name == 'niri':
    if args == ['msg', '-j', 'outputs']:
        print(json.dumps({'DP-1': {'logical': {'scale': 1, 'x': 0, 'y': 0}, 'current_mode': 0,
              'modes': [{'width': 1920, 'height': 1080, 'refresh_rate': 60000}], 'vrr_enabled': False}}))
    elif args[:1] == ['-c'] and os.environ.get('GREETER_LAUNCHED'):
        pathlib.Path(os.environ['VABU_GREETER_STATUS']).write_text('launched\n')
    elif args[:1] == ['validate']:
        sys.exit(1 if os.environ.get('INVALID_CONFIG') else 0)
    elif '1280x720@60.000' in args and os.environ.get('FAIL_MODE'):
        sys.exit(1)
elif name == 'jq':
    try: data = json.loads(pathlib.Path(args[-1]).read_text())
    except (ValueError, OSError): sys.exit(1)
    if args[0] == '-e':
        if args[1].startswith('has('): sys.exit(0 if 'xkbLayout' in data else 1)
        sys.exit(0 if isinstance(data, dict) else 1)
    if '.outputs' in args[1]: sys.exit(0)
    key = re.search(r'\.([a-zA-Z]+)', args[1]).group(1)
    value = data.get(key)
    if value is not None: print(json.dumps(value) if isinstance(value, (bool,int,float)) else value)
elif name == 'mktemp':
    if args == ['-d']:
        print(tempfile.mkdtemp(dir=os.environ['HOME'])); sys.exit(0)
    if args[0].startswith('--suffix='):
        fd, path = tempfile.mkstemp(suffix=args[0].split('=',1)[1], dir=os.environ['HOME'])
    else:
        template = pathlib.Path(args[0])
        fd, path = tempfile.mkstemp(prefix=template.name.replace('XXXXXX',''), dir=template.parent)
    os.close(fd)
    print(path)
elif name == 'qs':
    if os.environ.get('QS_FAIL'): sys.exit(1)
    if args[-1] == 'isSecure': print('false' if os.environ.get('INSECURE') else 'true')
elif name == 'timeout':
    sys.exit(subprocess.run(args[1:], env=os.environ).returncode)
elif name == 'dnf': sys.exit(int(os.environ.get('DNF_RC', '0')))
elif name == 'flatpak': pass
elif name == 'curl': sys.exit(1)
elif name == 'rpm': sys.exit(1)
elif name == 'lspci':
    if os.environ.get('NVIDIA'): print('01:00.0 VGA compatible controller [0300]: NVIDIA [10de:1234]')
elif name == 'foot': pass
elif name in ('sudo', 'pkexec', 'snapper', 'systemctl', 'swaylock', 'fuzzel', 'sleep', 'vabu-drivers', 'lsmod', 'mokutil', 'tuigreet'): pass
else: sys.exit('Unexpected mock command: ' + name)
'''


class Reliability(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory(prefix='vabu-test-')
        self.base = Path(self.tmp.name)
        self.bin = self.base / 'bin'
        self.bin.mkdir()
        self.runtime = self.base / 'run'
        self.runtime.mkdir(mode=0o700)
        self.log = self.base / 'commands'
        for name in ('niri', 'qs', 'timeout', 'dnf', 'flatpak', 'curl', 'rpm', 'lspci',
                     'jq', 'mktemp', 'foot', 'sudo', 'pkexec', 'snapper', 'systemctl', 'swaylock', 'fuzzel',
                     'sleep', 'vabu-drivers', 'lsmod', 'mokutil', 'tuigreet'):
            f = self.bin / name
            f.write_text(MOCK)
            f.chmod(0o755)
        # No inherited desktop/session variables, credentials or tool configuration.
        self.env = {'PATH': str(self.bin) + ':/usr/bin:/bin', 'HOME': str(self.base),
                    'XDG_RUNTIME_DIR': str(self.runtime), 'MOCK_LOG': str(self.log), 'LANG': 'C'}

    def tearDown(self):
        # Finish any detached guard before deleting its private runtime directory.
        for directory in self.runtime.glob('vabu-display-*'):
            self.helper('revert', directory.name, check=False)
        self.tmp.cleanup()

    def calls(self):
        return [json.loads(line) for line in self.log.read_text().splitlines()] if self.log.exists() else []

    def run_script(self, path, *args):
        return subprocess.run(['/bin/bash', str(ROOT / path), *args], env=self.env,
                              capture_output=True, text=True, timeout=15)

    def helper(self, *args, check=True):
        result = subprocess.run([sys.executable, '-I', str(HELPER), *args], env=self.env,
                                capture_output=True, text=True, timeout=45)
        if check:
            self.assertEqual(result.returncode, 0, result.stderr)
        return result

    def preview(self):
        draft = {'DP-1': {'mode': '1280x720@60.000', 'scale': 1.25,
                          'x': 10, 'y': 0, 'vrr': False, 'off': False}}
        return self.helper('preview', json.dumps(draft)).stdout.strip()

    def test_rollback_never_runs_privileged_or_restore_commands(self):
        result = self.run_script('rootfs/usr/bin/vabu', 'rollback', '12')
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(self.calls(), [])
        self.assertIn('/boot', result.stderr)

    def test_doctor_failure_returns_nonzero(self):
        self.assertNotEqual(self.run_script('rootfs/usr/bin/vabu', 'doctor').returncode, 0)

    def test_launcher_falls_back_on_failed_ipc(self):
        # The installed path check is true on Fedora; exercise the complete decision with
        # a private substitute rather than creating anything under /usr/share.
        source = (ROOT / 'rootfs/usr/bin/vabu-launcher').read_text()
        source = source.replace('/usr/share/vabu/shell', str(self.base))
        script = self.base / 'launcher'
        script.write_text(source)
        self.env['QS_FAIL'] = '1'
        result = self.run_script(script, '--install')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.calls()[-1][0], 'fuzzel')

    def test_lock_waits_for_secure_confirmation(self):
        result = self.run_script('rootfs/usr/libexec/vabu/lock')
        self.assertEqual(result.returncode, 0, result.stderr)
        calls = self.calls()
        self.assertTrue(any(c[0] == 'qs' and c[-1] == 'isSecure' for c in calls))
        self.assertFalse(any(c[0] == 'swaylock' for c in calls))

    def test_lock_falls_back_when_ipc_is_unavailable(self):
        self.env['QS_FAIL'] = '1'
        self.assertEqual(self.run_script('rootfs/usr/libexec/vabu/lock').returncode, 0)
        self.assertEqual(self.calls()[-1][0], 'swaylock')

    def test_preview_reverts_after_parent_has_exited(self):
        token = self.preview()
        self.assertTrue((self.runtime / token).is_dir())
        self.helper('revert', token)
        self.assertTrue(any(c[:5] == ['niri', 'msg', 'output', 'DP-1', 'mode']
                            and c[-1] == '1920x1080@60.000' for c in self.calls()))

    def test_concurrent_preview_is_rejected_without_mutating_outputs(self):
        token = self.preview()
        before = len([c for c in self.calls() if c[:3] == ['niri', 'msg', 'output']])
        result = self.helper('preview', json.dumps({'DP-1': {'mode': '1280x720@60.000'}}), check=False)
        self.assertNotEqual(result.returncode, 0)
        after = len([c for c in self.calls() if c[:3] == ['niri', 'msg', 'output']])
        self.assertEqual(before, after)
        self.helper('keep', token)

    def test_lock_does_not_accept_unconfirmed_request(self):
        self.env['INSECURE'] = '1'
        result = self.run_script('rootfs/usr/libexec/vabu/lock')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.calls()[-1][0], 'swaylock')

    def test_preview_keep_does_not_restore(self):
        token = self.preview()
        self.helper('keep', token)
        self.assertFalse(any(c[-1:] == ['1920x1080@60.000'] for c in self.calls()))

    def test_preview_timeout_restores_without_ui(self):
        token = self.preview()
        end = time.monotonic() + 20
        while (self.runtime / token).exists() and time.monotonic() < end:
            time.sleep(0.1)
        self.assertFalse((self.runtime / token).exists())
        self.assertTrue(any(c[-1:] == ['1920x1080@60.000'] for c in self.calls()))

    def test_preview_rejects_all_outputs_off(self):
        result = self.helper('preview', json.dumps({'DP-1': {'off': True}}), check=False)
        self.assertNotEqual(result.returncode, 0)
        self.assertFalse(any(c[:3] == ['niri', 'msg', 'output'] for c in self.calls()))

    def test_preview_failed_apply_restores_original(self):
        self.env['FAIL_MODE'] = '1'
        result = self.helper('preview', json.dumps({'DP-1': {'mode': '1280x720@60.000'}}), check=False)
        self.assertNotEqual(result.returncode, 0)
        end = time.monotonic() + 5
        while list(self.runtime.glob('vabu-display-*')) and time.monotonic() < end:
            time.sleep(0.05)
        self.assertTrue(any(c[-1:] == ['1920x1080@60.000'] for c in self.calls()))

    def test_preview_rejects_malformed_state_without_mutation(self):
        for state in ({'DP-1': None}, {'DP-1': {'scale': -1}}, {'unknown': {}}):
            self.assertNotEqual(self.helper('preview', json.dumps(state), check=False).returncode, 0)
        self.assertFalse(any(c[:3] == ['niri', 'msg', 'output'] for c in self.calls()))
        self.assertNotEqual(self.helper(check=False).returncode, 0)

    def test_preview_rejects_token_path_traversal(self):
        self.assertNotEqual(self.helper('keep', '../outside', check=False).returncode, 0)

    def test_shell_error_handles_quoted_state_path(self):
        self.env['QS_FAIL'] = '1'
        self.env['XDG_STATE_HOME'] = str(self.base / "state's directory")
        self.assertEqual(self.run_script('rootfs/usr/libexec/vabu/shell-run').returncode, 0)
        call = self.calls()[-1]
        self.assertEqual(call[0], 'foot')
        self.assertIn("state's directory", call[-1])
        self.assertNotIn("state's directory", call[call.index('-c') + 1])

    def config_setup(self):
        config = self.base / '.config'
        (config / 'vabu').mkdir(parents=True)
        (config / 'niri').mkdir()
        self.env['XDG_CONFIG_HOME'] = str(config)
        self.env['VABU_NIRI_TEMPLATE'] = str(ROOT / 'rootfs/usr/share/vabu/niri/config.kdl.in')
        return config

    def test_invalid_json_preserves_existing_niri_config(self):
        config = self.config_setup()
        out = config / 'niri/config.kdl'
        out.write_text('// VABU-AYARLAR-YÖNETİR\noriginal\n')
        (config / 'vabu/niri.json').write_text('{broken')
        result = self.run_script('rootfs/usr/libexec/vabu/niri-config')
        self.assertEqual(result.returncode, 2)
        self.assertEqual(out.read_text(), '// VABU-AYARLAR-YÖNETİR\noriginal\n')

    def test_validation_failure_preserves_existing_niri_config(self):
        config = self.config_setup()
        out = config / 'niri/config.kdl'
        out.write_text('// VABU-AYARLAR-YÖNETİR\noriginal\n')
        self.env['INVALID_CONFIG'] = '1'
        result = self.run_script('rootfs/usr/libexec/vabu/niri-config')
        self.assertEqual(result.returncode, 2)
        self.assertIn('original', out.read_text())

    def test_generated_config_keeps_user_block_and_false_settings(self):
        config = self.config_setup()
        out = config / 'niri/config.kdl'
        out.write_text('// VABU-AYARLAR-YÖNETİR\n// VABU-KULLANICI-BAŞLANGIÇ\n// custom setting\n// VABU-KULLANICI-SON\n')
        (config / 'vabu/niri.json').write_text('{"animations": false, "naturalScroll": false}')
        result = self.run_script('rootfs/usr/libexec/vabu/niri-config')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn('// custom setting', out.read_text())
        self.assertIn('animations {\n    off', out.read_text())
        self.assertNotIn('natural-scroll', out.read_text())
        self.assertEqual(list(out.parent.glob('.vabu-config.*')), [])

    def greeter_script(self):
        target = self.base / 'greeter.qml'; target.touch()
        source = (ROOT / 'rootfs/usr/libexec/vabu/greeter').read_text().replace('/usr/share/vabu/shell/greeter.qml', str(target))
        script = self.base / 'greeter'; script.write_text(source)
        return script

    def test_graphical_greeter_failure_falls_back_to_text(self):
        result = self.run_script(self.greeter_script())
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.calls()[-1][0], 'tuigreet')

    def test_authenticated_greeter_exits_without_second_login(self):
        self.env['GREETER_LAUNCHED'] = '1'
        result = self.run_script(self.greeter_script())
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertFalse(any(c[0] == 'tuigreet' for c in self.calls()))

    def test_default_keymap_is_inherited_from_system(self):
        config = self.config_setup()
        result = self.run_script('rootfs/usr/libexec/vabu/niri-config')
        self.assertEqual(result.returncode, 0, result.stderr)
        text = (config / 'niri/config.kdl').read_text()
        self.assertNotIn('layout "us,tr"', text)
        self.assertNotIn('@@', text)

    def test_sources_parse_without_executing_installers(self):
        for folder in ('rootfs', 'shell-system', 'iso', 'tests', 'tools'):
            for path in (ROOT / folder).rglob('*'):
                if not path.is_file(): continue
                text = path.read_text(errors='replace')
                if text.startswith(('#!/usr/bin/env bash', '#!/bin/bash')):
                    result = subprocess.run(['/bin/bash', '-n', str(path)], capture_output=True, text=True)
                    self.assertEqual(result.returncode, 0, result.stderr)
                if path.suffix == '.py' or text.startswith('#!/usr/bin/python3'):
                    ast.parse(text, filename=str(path))
                if path.suffix in ('.kiwi', '.svg'):
                    ET.fromstring(text)

    def test_update_exit_codes_in_javascript_runtime(self):
        import re
        source = (ROOT / 'shell/SettingsUpdates.qml').read_text()
        handlers = re.findall(r'onExited: code => \{(.*?)\n        \}', source, re.S)
        self.assertEqual(len(handlers), 3)
        script = "const assert = require('node:assert/strict'); const rpmErr={text:'depo hatası'}, flatErr={text:'ağ hatası'}; let page;\n"
        script += 'function rpmExit(code) {' + handlers[0] + '}\n'
        script += 'function flatExit(code) {' + handlers[1] + '}\n'
        script += "for (const code of [0,100]) { page={rpm:[1],rpmError:''}; rpmExit(code); assert.equal(page.rpmError,''); assert.equal(page.rpm.length,1); }\n"
        script += "for (const code of [1,-1]) { page={rpm:[1],rpmError:''}; rpmExit(code); assert.equal(page.rpmError,'depo hatası'); assert.equal(page.rpm.length,0); }\n"
        script += "page={flat:[1],flatError:''}; flatExit(1); assert.equal(page.flatError,'ağ hatası'); assert.equal(page.flat.length,0);\n"
        result = subprocess.run([shutil.which('node'), '-e', script], capture_output=True, text=True)
        self.assertEqual(result.returncode, 0, result.stderr)

    def test_qml_logic_in_javascript_runtime(self):
        node = shutil.which('node')
        self.assertIsNotNone(node, 'Node is required for the QML JavaScript regressions.')
        apps = (ROOT / 'shell/Apps.qml').read_text()
        functions = apps[apps.index('    function score('):apps.index('    function launch(')]
        net = (ROOT / 'shell/Net.qml').read_text()
        split = net[net.index('    function splitNm('):net.index('    function refresh(')]
        script = '''const assert = require('node:assert/strict');
const all = [{id:'browser',name:'Firefox'}, {id:'editor',name:'Editor'}];
const frequent = all; const launches = {editor: 50};
''' + functions + split + r'''
assert.deepEqual(search('fire').map(x => x.id), ['browser']);
assert.deepEqual(search('unrelated'), []);
assert.equal(search('').length, 2);
assert.deepEqual(splitNm('wifi:connected:office\\:west'), ['wifi','connected','office:west']);
'''
        result = subprocess.run([node, '-e', script], capture_output=True, text=True)
        self.assertEqual(result.returncode, 0, result.stderr)


if __name__ == '__main__':
    unittest.main(verbosity=2)
