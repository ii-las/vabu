#!/usr/bin/env python3
"""Offline desktop feature tests. No live services, clipboard or network are used."""
import hashlib
import io
import json
import os
from pathlib import Path
import re
import runpy
import shutil
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]
LIB = ROOT / 'rootfs/usr/libexec/vabu'


def module(path):
    return runpy.run_path(str(path), run_name='vabu_tests')


class DesktopFeatures(unittest.TestCase):
    def test_idle_battery_and_ac_are_independent_and_bounded(self):
        args = module(LIB / 'idle')['arguments']
        values = {'batteryLock':2, 'acLock':15, 'batteryScreen':1, 'acSuspend':30}
        battery = args(values, True)
        ac = args(values, False)
        self.assertIn('120', battery)
        self.assertNotIn('900', battery)
        self.assertIn('900', ac)
        self.assertIn('1800', ac)
        self.assertIn('before-sleep', battery)
        self.assertIn('/usr/libexec/vabu/lock && systemctl suspend', ac)
        self.assertEqual(args({'acLock': '$(bad)'}, False), args({}, False))
        self.assertEqual(args({'acLock': -5}, False), args({}, False))
        self.assertNotIn('timeout', args({'acLock':0,'acScreen':0,'acSuspend':0}, False))

    def test_workspace_renderer_escapes_names_and_matches_app_ids_exactly(self):
        render = module(LIB / 'workspaces')['render']
        data = {'workspaces':[{'name':'Kod "bir"', 'apps':['org.example.Editor']} ]}
        text = render(data)
        self.assertIn('workspace "Kod \\"bir\\""', text)
        self.assertIn('^org\\\\.example\\\\.Editor$', text)
        self.assertNotIn('spawn', text)
        self.assertEqual(render({}), '')

    def test_workspace_validation_rejects_commands_and_duplicates(self):
        validate = module(LIB / 'workspaces')['validate']
        for data in ({'workspaces':[{'name':'a','apps':['$(curl bad)']}]},
                     {'workspaces':[{'name':'a'},{'name':'a'}]},
                     {'workspaces':[{'name':'a\nspawn "bad"'}]},
                     {'workspaces':[{'name':'a','apps':['-evil']}]},
                     {'workspaces':'bad'}, []):
            with self.assertRaises(ValueError): validate(data)

    def test_workspace_startup_is_opt_in_and_uses_desktop_ids(self):
        tools = module(LIB / 'workspaces')
        with tempfile.TemporaryDirectory() as folder:
            config = Path(folder) / 'vabu'; config.mkdir()
            (config / 'niri.json').write_text(json.dumps({'workspaces':[{'name':'Code','apps':['org.example.Editor']}] }))
            with patch.dict(os.environ, {'XDG_CONFIG_HOME':folder}), patch.object(sys, 'argv', ['workspaces','launch']), patch('subprocess.Popen') as spawn:
                tools['main']()
                spawn.assert_not_called()
                (config / 'shell.json').write_text('{"restoreWorkspaceApps":true}')
                tools['main']()
                self.assertEqual(spawn.call_args.args[0], ['gtk-launch','org.example.Editor'])

    def test_diagnostic_report_excludes_raw_status_output(self):
        tools = module(LIB / 'desktop-tools')
        def fake(args, timeout=5):
            return (0, '1.0-1') if args[0] == 'rpm' else (0, 'secret-user secret-ssid 192.0.2.1')
        # Functions hold the runpy global namespace rather than the returned copy.
        with patch.dict(tools['report'].__globals__, {'run':fake}):
            report = json.dumps(tools['report']())
        self.assertNotIn('secret-', report)
        self.assertNotIn('192.0.2.1', report)
        self.assertNotIn('hostname', report)
        self.assertIn('versions', report)

    def test_lid_invalid_request_is_rejected_before_filesystem_mutation(self):
        lid = module(LIB / 'desktop-tools')['lid']
        with patch('os.geteuid',return_value=0), patch.object(Path,'mkdir') as mkdir:
            with self.assertRaises(ValueError): lid('$(bad)','suspend')
            mkdir.assert_not_called()
        with patch('os.geteuid',return_value=1000), patch.object(Path,'mkdir') as mkdir:
            with self.assertRaises(ValueError): lid('ignore','suspend')
            mkdir.assert_not_called()

    def test_performance_parser_is_allowlisted(self):
        performance = module(LIB / 'desktop-tools')['performance']
        with patch.dict(performance.__globals__, {'run':lambda args: (0, 'qs 1.5 102400\nniri 2.0 204800\nsecret-app 50 10000')}), patch.object(Path,'glob',return_value=[]):
            data = performance()
        self.assertEqual([p['name'] for p in data['processes']], ['qs','niri'])
        self.assertEqual(data['processes'][0]['memoryMiB'],100)

    def test_clipboard_sensitive_capture_never_reads_or_sends_data(self):
        capture = module(LIB / 'clipboard')['capture']
        with patch.dict(os.environ, {'CLIPBOARD_STATE':'sensitive'}), patch('subprocess.run') as proc:
            capture(); proc.assert_not_called()
        with patch.dict(os.environ, {'CLIPBOARD_STATE':'data'}), patch('subprocess.run',return_value=subprocess.CompletedProcess([],0,b'x-kde-passwordManagerHint\ntext/plain')):
            with patch.dict(capture.__globals__, {'send':lambda *_: self.fail('Sensitive capture forwarded')}):
                capture()

    def test_clipboard_capture_rejects_private_keys_and_oversized_content(self):
        capture = module(LIB / 'clipboard')['capture']
        for value in (b'-----BEGIN OPENSSH PRIVATE KEY-----\nsecret', b'x'*16385):
            stdin = type('Input',(),{'buffer':io.BytesIO(value)})()
            with patch.dict(os.environ, {'CLIPBOARD_STATE':'data'}), patch.object(sys,'stdin',stdin), patch('subprocess.run',return_value=subprocess.CompletedProcess([],0,b'text/plain')):
                with patch.dict(capture.__globals__, {'send':lambda *_:self.fail('Unsafe content forwarded')}):
                    capture()

    def test_clipboard_server_limits_clears_and_keeps_content_out_of_argv(self):
        tools = module(LIB / 'clipboard')
        with tempfile.TemporaryDirectory(prefix='vabu-clip-test-',dir='/tmp') as folder:
            base = Path(folder); runtime=base/'run'; runtime.mkdir(mode=0o700)
            bindir=base/'bin'; bindir.mkdir(); logfile=base/'argv'
            paste=bindir/'wl-paste'
            paste.write_text('#!/usr/bin/python3\nimport time\ntime.sleep(60)\n'); paste.chmod(0o755)
            copy=bindir/'wl-copy'
            copy.write_text('#!/usr/bin/python3\nimport os,sys\nopen(os.environ["MOCK_LOG"],"w").write(repr(sys.argv))\nsys.stdin.buffer.read()\n');copy.chmod(0o755)
            env={'PATH':str(bindir)+':/usr/bin:/bin','XDG_RUNTIME_DIR':str(runtime),'MOCK_LOG':str(logfile)}
            proc=subprocess.Popen([sys.executable,'-I',str(LIB/'clipboard'),'serve'],env=env,stdout=subprocess.PIPE,stderr=subprocess.PIPE,text=True)
            try:
                first=json.loads(proc.stdout.readline()); token=first['socket']
                with patch.dict(os.environ,env,clear=True):
                    for n in range(25):
                        tools['send'](token,{'action':'add','text':f'private-value-{n}'})
                        latest=json.loads(proc.stdout.readline())
                    self.assertEqual(len(latest['entries']),20)
                    tools['send'](token,{'action':'copy','id':latest['entries'][0]['id']});proc.stdout.readline()
                    self.assertNotIn('private-value',logfile.read_text())
                    tools['send'](token,{'action':'clear'}); latest=json.loads(proc.stdout.readline())
                    self.assertEqual(latest['entries'],[])
                    self.assertEqual([f.name for f in (runtime/token).iterdir()],['control'])
            finally:
                proc.terminate(); proc.wait(timeout=5)
                proc.stdout.close(); proc.stderr.close()
            self.assertFalse((runtime/token).exists())

    def test_iso_key_preparation_requires_pin_before_fetch(self):
        prepare=module(ROOT/'tools/prepare-iso-keys.py')['prepare']
        with patch('urllib.request.urlopen') as fetch:
            with self.assertRaises(ValueError): prepare('/unused','/unused','45','ii-las','')
            fetch.assert_not_called()

    def test_iso_key_mismatch_does_not_write_trust_material(self):
        prepare=module(ROOT/'tools/prepare-iso-keys.py')['prepare']
        with tempfile.TemporaryDirectory() as folder:
            base=Path(folder);keys=base/'official';(keys/'fedora').mkdir(parents=True);(keys/'rpmfusion').mkdir()
            armor=b'-----BEGIN PGP PUBLIC KEY BLOCK-----\ntest key'
            for name in ('fedora/RPM-GPG-KEY-fedora-45-primary','rpmfusion/RPM-GPG-KEY-rpmfusion-free-fedora-45','rpmfusion/RPM-GPG-KEY-rpmfusion-nonfree-fedora-45'):
                (keys/name).write_bytes(armor)
            destination=base/'description'
            with self.assertRaises(ValueError):prepare(destination,keys,'45','ii-las','0'*64,fetch=lambda _:armor)
            self.assertFalse(destination.exists())
            prepare(destination,keys,'45','ii-las',hashlib.sha256(armor).hexdigest(),fetch=lambda _:armor)
            self.assertEqual(len(list((destination/'keys').iterdir())),4)

    def test_iso_signature_verification_and_key_sources_are_mandatory(self):
        image=ET.parse(ROOT/'iso/config.kiwi').getroot()
        self.assertEqual(image.findtext('preferences/rpm-check-signatures'),'true')
        for repo in image.findall('repository'):
            self.assertTrue(repo.find('source/signing').get('key').startswith('this://keys/'))
        source=(ROOT/'.github/workflows/iso-build.yml').read_text()
        self.assertIn('actions/attest@v4',source)
        self.assertIn('steps.provenance.outcome !=',source)

    def test_all_settings_pages_exist_and_clipboard_is_opt_in(self):
        source=(ROOT/'shell/settings.qml').read_text()
        for page in re.findall(r'file:\s*"([^"]+)"',source): self.assertTrue((ROOT/'shell'/page).is_file(),page)
        config=(ROOT/'shell/Config.qml').read_text()
        self.assertIn('clipboardEnabled: values.clipboardEnabled === true',config)
        self.assertIn('restoreWorkspaceApps', (ROOT/'rootfs/usr/libexec/vabu/workspaces').read_text())
        self.assertIn('!Ui.locked',(ROOT/'shell/Clipboard.qml').read_text())

    def test_language_switch_preserves_unknown_user_text(self):
        source=(ROOT/'shell/Lang.qml').read_text()
        dictionary=json.loads(source[source.index('({')+1:source.index(')\n    function t')])
        script='const assert=require("node:assert/strict");const english='+json.dumps(dictionary)+';let language="en";'+re.search(r'function t\(text\) \{[^\n]+',source)[0]
        script+=';assert.equal(t("Ayarlar"),"Settings");assert.equal(t("My custom workspace"),"My custom workspace");language="tr";assert.equal(t("Ayarlar"),"Ayarlar");'
        result=subprocess.run([shutil.which('node'),'-e',script],capture_output=True,text=True)
        self.assertEqual(result.returncode,0,result.stderr)

    def test_open_window_search_matches_titles_and_app_names(self):
        source=(ROOT/'shell/Apps.qml').read_text()
        function=source[source.index('    function searchWindows('):source.index('    function open(')]
        script='const assert=require("node:assert/strict");const Niri={windows:[{id:1,title:"Budget 2026",app_id:"calc",is_focused:false},{id:2,title:"Readme",app_id:"editor",is_focused:true}]};function nameFor(id){return id==="calc"?"Calculator":"Editor"} function forWindow(){return null}'+function
        script+=';assert.deepEqual(searchWindows("budget").map(w=>w.id),[1]);assert.deepEqual(searchWindows("calculator").map(w=>w.id),[1]);assert.equal(searchWindows("")[0].id,2);'
        result=subprocess.run([shutil.which('node'),'-e',script],capture_output=True,text=True)
        self.assertEqual(result.returncode,0,result.stderr)

    def test_clipboard_and_window_titles_are_plain_text(self):
        for file in ('PillButton.qml','Group.qml','ListRow.qml'):
            self.assertIn('textFormat: Text.PlainText',(ROOT/'shell'/file).read_text())
        self.assertNotIn('Lang.t(root.label)',(ROOT/'shell/PillButton.qml').read_text())

    def test_qml_function_bodies_compile_as_javascript(self):
        # This is syntax coverage only; it is not a Qt/Quickshell runtime test.
        functions=[]
        for path in (ROOT/'shell').glob('*.qml'):
            source=path.read_text()
            pattern=r'\bfunction\s+\w+\s*\([^)]*\)\s*(?::\s*\w+)?\s*\{'
            for match in re.finditer(pattern,source):
                start=match.start(); i=match.end(); depth=1; quote=None
                while i<len(source) and depth:
                    c=source[i]
                    if quote:
                        if c=='\\': i+=2;continue
                        if c==quote:quote=None
                    elif source.startswith('//',i):
                        end=source.find('\n',i);i=len(source) if end<0 else end;continue
                    elif source.startswith('/*',i):
                        end=source.find('*/',i+2);i=len(source) if end<0 else end+2;continue
                    elif c in ('"',"'",'`'):quote=c
                    elif c=='{':depth+=1
                    elif c=='}':depth-=1
                    i+=1
                self.assertEqual(depth,0,path.name+': unbalanced function')
                text=source[start:i]
                text=re.sub(r'(?<=\w):\s*(?:string|bool|int|real|var)\b','',text)
                text=re.sub(r'\)\s*:\s*(?:void|string|bool|int|real|var)\s*\{',') {',text)
                functions.append((path.name,text))
        script='const vm=require("node:vm"); for (const [file,text] of '+json.dumps(functions)+') { try {new vm.Script(text)} catch(e) {console.error(file,e.message);process.exitCode=1;} }'
        result=subprocess.run([shutil.which('node'),'-e',script],capture_output=True,text=True)
        self.assertEqual(result.returncode,0,result.stderr)


if __name__=='__main__':unittest.main(verbosity=2)
