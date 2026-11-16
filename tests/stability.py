#!/usr/bin/env python3
"""Regression scenarios for shared settings, hostile IPC, updates and CI gates.
All writes use temporary files; all system/package commands are mocked.
"""
import contextlib
import io
import json
import os
from pathlib import Path
import runpy
import socket
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]
LIB = ROOT / 'rootfs/usr/libexec/vabu'


def load(name):
    result=runpy.run_path(str(LIB / name), run_name='test_module')
    if name=='update':
        # CI may run as root; every event record must remain inside this test's XDG directory.
        result['EVENTS']['record'].__globals__['folder']=lambda system=False:Path(os.environ['XDG_STATE_HOME'])/'vabu'
    return result


class Stability(unittest.TestCase):
    def test_parallel_settings_patches_do_not_lose_other_process_changes(self):
        with tempfile.TemporaryDirectory() as folder:
            env = {'PATH':'/usr/bin:/bin', 'XDG_CONFIG_HOME':folder}
            processes = []
            for n in range(16):
                proc = subprocess.Popen([sys.executable, '-I', str(LIB/'config-store'), 'shell', 'patch'], env=env,
                                        stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
                proc.stdin.write(json.dumps({'concurrent' + str(n):n}) + '\n'); proc.stdin.close()
                processes.append(proc)
            for proc in processes:
                proc.wait(timeout=15)
                self.assertEqual(proc.returncode, 0, proc.stderr.read())
                proc.stdout.close(); proc.stderr.close()
            data = json.loads((Path(folder)/'vabu/shell.json').read_text())
            for n in range(16): self.assertEqual(data['concurrent' + str(n)], n)
            self.assertEqual(data['_schemaVersion'], 1)
            self.assertEqual((Path(folder)/'vabu/shell.json').stat().st_mode & 0o777, 0o600)

    def test_invalid_settings_preserve_original_and_restore_only_on_request(self):
        transact = load('config-store')['transact']
        with tempfile.TemporaryDirectory() as folder, patch.dict(os.environ, {'XDG_CONFIG_HOME':folder}):
            transact('shell','patch',{'theme':'koyu'})
            transact('shell','patch',{'showSeconds':True})
            path = Path(folder)/'vabu/shell.json'; path.write_text('broken source')
            result = transact('shell','read')
            self.assertFalse(result['writable']); self.assertTrue(result['canRecover'])
            self.assertEqual(result['values']['theme'],'koyu')
            self.assertFalse(transact('shell','patch',{'theme':'acik'})['ok'])
            self.assertEqual(path.read_text(),'broken source')
            self.assertTrue(transact('shell','recover')['ok'])
            self.assertEqual(json.loads(path.read_text())['theme'],'koyu')
            preserved = list(path.parent.glob('shell.json.broken-*'))
            self.assertEqual(len(preserved),1); self.assertEqual(preserved[0].read_text(),'broken source')

    def test_wrong_types_and_future_schema_never_overwrite_settings(self):
        transact = load('config-store')['transact']
        with tempfile.TemporaryDirectory() as folder, patch.dict(os.environ, {'XDG_CONFIG_HOME':folder}):
            transact('shell','patch',{'theme':'acik'})
            path = Path(folder)/'vabu/shell.json'; initial=path.read_bytes()
            for change in ({'pinned':[None]}, {'textScale':True}, {'clipboardEnabled':'yes'}, {'acLock':-1}, {'sidebarWidth':float('nan')}):
                with self.assertRaises(ValueError): transact('shell','patch',change)
                self.assertEqual(path.read_bytes(),initial)
            for malformed in ('null','[]','{"_schemaVersion":2}'):
                path.write_text(malformed)
                self.assertFalse(transact('shell','read')['ok'])
                self.assertEqual(path.read_text(),malformed)

    def test_settings_symlink_is_not_followed(self):
        transact = load('config-store')['transact']
        with tempfile.TemporaryDirectory() as folder, patch.dict(os.environ, {'XDG_CONFIG_HOME':folder}):
            base=Path(folder); (base/'vabu').mkdir(); victim=base/'untouched'; victim.write_text('{"theme":"acik"}')
            (base/'vabu/shell.json').symlink_to(victim)
            self.assertFalse(transact('shell','patch',{'theme':'koyu'})['ok'])
            self.assertEqual(victim.read_text(),'{"theme":"acik"}')

    def test_settings_delete_and_unknown_keys_are_preserved_correctly(self):
        transact=load('config-store')['transact']
        with tempfile.TemporaryDirectory() as folder, patch.dict(os.environ, {'XDG_CONFIG_HOME':folder}):
            transact('shell','patch',{'theme':'koyu','extensionSetting':{'value':False}})
            data=transact('shell','patch',{'theme':None})['values']
            self.assertNotIn('theme',data); self.assertEqual(data['extensionSetting'],{'value':False})

    def test_niri_settings_use_workspace_validation(self):
        transact=load('config-store')['transact']
        with tempfile.TemporaryDirectory() as folder, patch.dict(os.environ, {'XDG_CONFIG_HOME':folder}):
            transact('niri','patch',{'gaps':16})
            with self.assertRaises(ValueError): transact('niri','patch',{'workspaces':[{'name':'bad\nrule'}]})
            self.assertEqual(transact('niri','read')['values']['gaps'],16)

    def test_clipboard_bad_clients_do_not_terminate_server(self):
        tools=load('clipboard')
        with tempfile.TemporaryDirectory(prefix='vabu-ipc-',dir='/tmp') as folder:
            base=Path(folder); runtime=base/'run'; runtime.mkdir(mode=0o700); bindir=base/'bin'; bindir.mkdir()
            paste=bindir/'wl-paste'; paste.write_text('#!/usr/bin/python3\nimport time\ntime.sleep(60)\n'); paste.chmod(0o755)
            env={'PATH':str(bindir)+':/usr/bin:/bin', 'XDG_RUNTIME_DIR':str(runtime)}
            proc=subprocess.Popen([sys.executable,'-I',str(LIB/'clipboard'),'serve'],env=env,stdout=subprocess.PIPE,stderr=subprocess.PIPE,text=True)
            try:
                first=proc.stdout.readline()
                self.assertTrue(first,proc.stderr.read() if proc.poll() is not None else 'No startup record')
                token=json.loads(first)['socket']; endpoint=runtime/token/'control'
                for payload in (b'[]', b'null', b'{}', b'"text"', b'\xff', b'{bad', b'{"action":"copy","id":[]}', b'x'*(16384*7+514)):
                    with socket.socket(socket.AF_UNIX) as client:
                        client.settimeout(5); client.connect(str(endpoint))
                        try: client.sendall(payload); client.shutdown(socket.SHUT_WR); response=client.recv(256)
                        except (BrokenPipeError,ConnectionResetError): response=b''
                        if response: self.assertFalse(json.loads(response)['ok'])
                    proc.stdout.readline()
                    self.assertIsNone(proc.poll())
                # A client that connects but never completes its request times out locally.
                with socket.socket(socket.AF_UNIX) as client:
                    client.settimeout(5); client.connect(str(endpoint)); self.assertFalse(json.loads(client.recv(256))['ok'])
                proc.stdout.readline()
                # Disconnect before the reply: broken pipe is contained too.
                with socket.socket(socket.AF_UNIX) as client:
                    client.connect(str(endpoint)); client.sendall(b'{"action":"clear"}')
                proc.stdout.readline()
                with patch.dict(os.environ,env,clear=True): tools['send'](token,{'action':'clear'})
                self.assertEqual(json.loads(proc.stdout.readline())['entries'],[])
                self.assertIsNone(proc.poll())
            finally:
                proc.terminate(); proc.wait(timeout=5); proc.stdout.close(); proc.stderr.close()

    def test_workspace_explicit_identity_escapes_regex_and_limits_shared_ids(self):
        tools=load('workspaces')
        app={'desktopId':'org.editor.App','appId':'editor+beta','title':'A [document]'}
        result=tools['render']({'workspaces':[{'name':'Code','apps':[app]}]})
        self.assertIn('editor\\\\+beta',result); self.assertIn('title=',result)
        self.assertNotIn('^org\\\\.editor',result)
        app={'desktopId':'so.vabu.Settings','appId':'org.quickshell'}
        with self.assertRaises(ValueError): tools['validate']({'workspaces':[{'name':'Code','apps':[app]}]})
        with self.assertRaises(ValueError): tools['validate']({'workspaces':[{'name':'a','apps':['editor']},{'name':'b','apps':['editor']}]})

    def test_workspace_metadata_includes_startup_wmclass(self):
        render=load('workspaces')['render']
        with tempfile.TemporaryDirectory() as folder:
            applications=Path(folder)/'applications'; applications.mkdir()
            (applications/'org.example.Editor.desktop').write_text('[Desktop Entry]\nStartupWMClass=EditorLegacy\n')
            with patch.dict(os.environ, {'XDG_DATA_HOME':folder,'XDG_DATA_DIRS':folder}):
                result=render({'workspaces':[{'name':'Code','apps':['org.example.Editor']}]})
            self.assertIn('^EditorLegacy$',result); self.assertEqual(result.count('match app-id='),2)

    def test_workspace_startup_uses_desktop_id_from_explicit_mapping(self):
        main=load('workspaces')['main']
        with tempfile.TemporaryDirectory() as folder:
            config=Path(folder)/'vabu'; config.mkdir()
            (config/'shell.json').write_text('{"restoreWorkspaceApps":true}')
            (config/'niri.json').write_text(json.dumps({'workspaces':[{'name':'a','apps':[{'desktopId':'org.App','appId':'different'}]}]}))
            with patch.dict(os.environ,{'XDG_CONFIG_HOME':folder}), patch.object(sys,'argv',['workspaces','launch']),patch('subprocess.Popen') as launch:
                main()
            self.assertEqual(launch.call_args.args[0],['gtk-launch','org.App'])

    def test_optional_inactive_service_is_available_not_failed(self):
        check=load('desktop-tools')['service_check']
        with patch.dict(check.__globals__,{'run':lambda _: (0,'LoadState=loaded\nActiveState=inactive\nUnitFileState=static')}):
            self.assertEqual(check('portal','Portal','portal.service',True,True)['state'],'available')
            self.assertEqual(check('locking','Lock','lock.service',True,False)['state'],'attention')

    def test_service_failure_missing_and_unreadable_are_distinct(self):
        check=load('desktop-tools')['service_check']
        for output,code,expected in [('LoadState=loaded\nActiveState=failed',0,'failed'),('LoadState=not-found',0,'unconfigured'),('',1,'unknown'),('LoadState=loaded\nActiveState=inactive\nUnitFileState=disabled',0,'unconfigured')]:
            with patch.dict(check.__globals__,{'run':lambda _,c=code,o=output:(c,o)}):
                self.assertEqual(check('updates','Updates','timer',timer=True)['state'],expected)

    def test_reboot_query_requires_structured_confirmation(self):
        reboot=load('system-check')['reboot']
        with patch.object(Path,'exists',return_value=False):
            for code,output,expected in [(0,'[{"reboot_required":false}]','not-required'),(1,'[{"reboot_required":true}]','required'),(1,'Unknown command','unknown'),(0,'[]','unknown'),(127,'','unknown'),(0,'[{"reboot_required":true}]','unknown')]:
                with patch.dict(reboot.__globals__,{'run':lambda _,c=code,o=output:(c,o)}):self.assertEqual(reboot(),expected)

    def test_recovery_inventory_never_claims_boot_or_full_restore(self):
        recovery=load('system-check')['recovery']
        def fake(command):
            if command[0]=='rpm':return 0,'6.1.test.x86_64\n../../unsafe\n'
            return 0,'{"filesystems":[{"target":"/boot","fstype":"ext4"}]}'
        with patch.dict(recovery.__globals__,{'run':fake}),patch.object(Path,'is_file',return_value=True),patch.object(Path,'is_dir',return_value=True):
            result=recovery()
        self.assertEqual(len(result['kernels']),1); self.assertTrue(result['matchingKernelFiles'])
        self.assertTrue(result['separateBoot']); self.assertFalse(result['fullRestoreSupported'])
        self.assertEqual(result['state'],'files-present')

    def test_update_failure_is_nonzero_and_stops_after_failed_rpm(self):
        update=load('update')['update']
        with tempfile.TemporaryDirectory() as folder,patch.dict(os.environ,{'XDG_STATE_HOME':folder}),patch('subprocess.run',return_value=subprocess.CompletedProcess([],17)) as run,contextlib.redirect_stdout(io.StringIO()):
            self.assertEqual(update(),1)
            result=json.loads((Path(folder)/'vabu/update-result.json').read_text())
        self.assertEqual(run.call_count,1); self.assertEqual(result['state'],'failed'); self.assertEqual(result['phases'][0]['exitCode'],17)

    def test_flatpak_failure_is_not_reported_as_update_success(self):
        update=load('update')['update']
        codes=[0,8,0]
        with tempfile.TemporaryDirectory() as folder,patch.dict(os.environ,{'XDG_STATE_HOME':folder}),patch('subprocess.run',side_effect=lambda _:subprocess.CompletedProcess([],codes.pop(0))),contextlib.redirect_stdout(io.StringIO()):
            self.assertEqual(update(),1)
            result=json.loads((Path(folder)/'vabu/update-result.json').read_text())
        self.assertEqual(result['state'],'failed'); self.assertEqual(len(result['phases']),3)

    def test_update_success_requires_all_three_phases(self):
        update=load('update')['update']
        with tempfile.TemporaryDirectory() as folder,patch.dict(os.environ,{'XDG_STATE_HOME':folder}),patch('subprocess.run',return_value=subprocess.CompletedProcess([],0)),contextlib.redirect_stdout(io.StringIO()):
            self.assertEqual(update(),0)
            result=json.loads((Path(folder)/'vabu/update-result.json').read_text())
        self.assertEqual(result['state'],'success');self.assertEqual(len(result['phases']),3)

    def test_update_cancellation_and_stale_record_are_not_success(self):
        tools=load('update')
        with tempfile.TemporaryDirectory() as folder,patch.dict(os.environ,{'XDG_STATE_HOME':folder}),patch('subprocess.run',side_effect=KeyboardInterrupt),contextlib.redirect_stdout(io.StringIO()):
            self.assertEqual(tools['update'](),1)
            self.assertEqual(tools['status']()['state'],'interrupted')
            tools['save']({'format':1,'state':'running','phases':[]})
            self.assertEqual(tools['status']()['state'],'interrupted')

    def test_qml_gate_rejects_missing_logs_and_missing_completion(self):
        check=runpy.run_path(str(ROOT/'tests/qml-check.py'))['check']
        with tempfile.TemporaryDirectory() as folder:
            base=Path(folder)
            for name in ('derle','shell','settings','greeter','shell-niri','shell-kilit'):(base/(name+'.log')).write_text('started\n')
            self.assertTrue(check(base))
            (base/'derle.log').write_text('DERLEME-BITTI 94 dosya, 0 hatalı\n')
            self.assertEqual(check(base),[])
            (base/'shell.log').write_text('TypeError: x is undefined')
            self.assertTrue(check(base))
            (base/'shell.log').unlink(); self.assertTrue(check(base))

    def test_recovery_of_corrupt_settings_does_not_enable_clipboard(self):
        transact=load('config-store')['transact']
        with tempfile.TemporaryDirectory() as folder,patch.dict(os.environ,{'XDG_CONFIG_HOME':folder}):
            transact('shell','patch',{'clipboardEnabled':True,'restoreWorkspaceApps':True})
            transact('shell','patch',{'theme':'koyu'})
            (Path(folder)/'vabu/shell.json').write_text('bad data')
            for action in ('read','recover'):
                result=transact('shell',action)
                self.assertFalse(result['values']['clipboardEnabled'])
                self.assertFalse(result['values']['restoreWorkspaceApps'])

    def test_release_gate_rejects_missing_wrong_and_pending_records(self):
        tools=runpy.run_path(str(ROOT/'tools/validate-release.py'))
        validate=tools['validate']; commit='a'*40
        checks={name:{'status':'passed','evidence':'https://example.org/test-run'} for name in tools['REQUIRED']}
        record={'format':1,'sourceCommit':commit,'fedora':'45','architectures':{'x86_64':checks}}
        self.assertTrue(validate(record,commit,'x86_64','45'))
        for changed in ({}, {**record,'sourceCommit':'b'*40}, {**record,'fedora':'44'}):
            with self.assertRaises(ValueError): validate(changed,commit,'x86_64','45')
        with self.assertRaises(ValueError):validate(record,commit,'aarch64','45')
        checks['lock-suspend']['status']='pending'
        with self.assertRaises(ValueError):validate(record,commit,'x86_64','45')

    def test_clipboard_queue_sends_in_order_and_rejects_locked_requests(self):
        import re
        import shutil
        source=(ROOT/'shell/Clipboard.qml').read_text()
        functions=source[source.index('    function action('):source.index('    function reconcile(')]
        script="""const assert=require('node:assert/strict');
        let wanted=true, socket='session', queue=[], error='';
        const root={}; let ticks=0; const pump={restart(){ticks++}};
        const request={running:false,command:[]};
        """+functions+"""
        action('copy','first'); action('delete','second');
        next(); assert.deepEqual(request.command.slice(1),['copy','session','first']);
        next(); assert.equal(queue.length,1);
        request.running=false; next();assert.deepEqual(request.command.slice(1),['delete','session','second']);
        wanted=false;action('copy','private'); assert.equal(queue.length,0);
        wanted=true;action('delete','stale');socket='new-session';request.running=false;next();assert.equal(request.running,false);
        """
        result=subprocess.run([shutil.which('node'),'-e',script],capture_output=True,text=True)
        self.assertEqual(result.returncode,0,result.stderr)

    def test_invalid_monitor_records_do_not_replace_last_valid_settings(self):
        transact=load('config-store')['transact']
        with tempfile.TemporaryDirectory() as folder,patch.dict(os.environ,{'XDG_CONFIG_HOME':folder}):
            original=[{'name':'DP-1','mode':'1920x1080@60.000','scale':1.25,'x':0,'y':0}]
            transact('niri','patch',{'outputs':original})
            for outputs in ([{}],[{'name':12}],[{'name':'DP-1','scale':True}],[{'name':'DP-1','mode':'bad" config'}],[{'name':'DP-1','x':float('inf')}]):
                with self.assertRaises(ValueError):transact('niri','patch',{'outputs':outputs})
            self.assertEqual(transact('niri','read')['values']['outputs'],original)
            with self.assertRaises(ValueError):transact('shell','patch',{'displayProfiles':[{'name':'a','outputs':None}]})


if __name__=='__main__': unittest.main(verbosity=2)
