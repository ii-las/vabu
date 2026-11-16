#!/usr/bin/env python3
"""Offline feature and safety regressions. No host updates, devices, clipboard or network."""
import contextlib
import io
import json
import os
from pathlib import Path
import re
import runpy
import shutil
import subprocess
import tempfile
import unittest
from unittest.mock import patch

ROOT=Path(__file__).resolve().parents[1]
LIB=ROOT/'rootfs/usr/libexec/vabu'
TEMPLATE=ROOT/'rootfs/usr/share/vabu/niri/config.kdl.in'


def module(name):return runpy.run_path(str(LIB/name),run_name='expansion_tests')


class Expansion(unittest.TestCase):
 def test_custom_power_minutes_are_not_displayed_as_never(self):
  source=(ROOT/'shell/SettingsPower.qml').read_text()
  expression=re.search(r'readonly property var choices: (.*)',source)[1]
  script='const assert=require("node:assert/strict"); for (const minutes of [1,3,120]) { const choices='+expression+'; assert.equal(choices[choices.indexOf(minutes)], minutes); }'
  result=subprocess.run([shutil.which('node'),'-e',script],capture_output=True,text=True)
  self.assertEqual(result.returncode,0,result.stderr)
  self.assertIn('running: Config.ready && !Config.values.onboardingDone',(ROOT/'shell/shell.qml').read_text())

 def test_failed_mount_query_remains_unknown(self):
  recovery=module('system-check')['recovery']
  with patch.dict(recovery.__globals__,{'run':lambda args:(0,'6.1.test.x86_64\n') if args[0]=='rpm' else (127,'')}),patch.object(Path,'is_file',return_value=False),patch.object(Path,'is_dir',return_value=False):
   self.assertIsNone(recovery()['separateBoot'])

 def test_static_lint_failure_and_missing_binary_are_fatal(self):
  source=(ROOT/'.github/workflows/rpm.yml').read_text()
  fragment=source[source.index('          set +e\n'):source.index('\n      - uses: actions/upload-artifact',source.index('          set +e\n'))]
  with tempfile.TemporaryDirectory() as folder:
   script='\n'.join(line[10:] for line in fragment.splitlines()).replace('/tmp/qmllint.txt',str(Path(folder)/'lint.log'))
   tool=Path(folder)/'lint';tool.write_text('#!/bin/sh\nexit 4\n');tool.chmod(0o755)
   for binary,code in ((str(tool),4),(str(Path(folder)/'absent'),127)):
    result=subprocess.run(['bash','-c',script],env={'PATH':'/usr/bin:/bin','QMLLINT':binary},capture_output=True)
    self.assertEqual(result.returncode,code)

 def test_shortcut_conflicts_aliases_and_reserved_lock_are_rejected(self):
  validate=module('shortcuts')['validate'];text=TEMPLATE.read_text()
  for changes in ({'terminal':'Super+Space'},{'terminal':'Mod+Alt+L'},{'terminal':'Alt+T'},{'terminal':'Mod+T;evil'},{'terminal':'Mod+NotARealKey'},{'unknown':'Mod+T'}):
   with self.assertRaises(ValueError):validate(text,changes)
  self.assertEqual(validate(text,{'terminal':'Mod+Ctrl+T'})['terminal'],'Mod+Ctrl+T')

 def test_shortcut_rewrite_changes_only_the_selected_action(self):
  rewrite=module('shortcuts')['rewrite'];text=TEMPLATE.read_text()
  result=rewrite(text,{'terminal':'Mod+Ctrl+T'})
  self.assertIn('Mod+Ctrl+T hotkey-overlay-title="Terminal" { spawn "foot";',result)
  self.assertIn('Super+Alt+L hotkey-overlay-title="Ekranı kilitle"',result)
  self.assertIn('Mod+Space hotkey-overlay-title="Ara ve başlat"',result)
  self.assertEqual(rewrite(text,{}),text)

 def test_shortcuts_are_validated_by_the_common_settings_writer(self):
  transact=module('config-store')['transact']
  with tempfile.TemporaryDirectory() as folder,patch.dict(os.environ,{'XDG_CONFIG_HOME':folder}):
   with self.assertRaises(ValueError):transact('niri','patch',{'shortcuts':{'terminal':'Mod+Space'}})
   result=transact('niri','patch',{'shortcuts':{'terminal':'Mod+Ctrl+T'}})
   self.assertEqual(result['values']['shortcuts']['terminal'],'Mod+Ctrl+T')

 def test_settings_export_excludes_private_and_active_session_fields(self):
  tools=module('preferences')
  with tempfile.TemporaryDirectory() as folder,patch.dict(os.environ,{'XDG_CONFIG_HOME':folder}):
   tools['STORE']['transact']('shell','patch',{'theme':'koyu','clipboardEnabled':True,'restoreWorkspaceApps':True,'focusUntil':1000000,'location':{'lat':41,'lon':29},'privateExtension':'secret'})
   destination=Path(folder)/'export.json';tools['export']('shell',str(destination))
   values=json.loads(destination.read_text())['values']
   self.assertEqual(values,{'theme':'koyu'})
   self.assertEqual(destination.stat().st_mode & 0o777,0o600)

 def test_settings_import_previews_then_applies_only_reviewed_fields(self):
  tools=module('preferences')
  with tempfile.TemporaryDirectory() as folder,patch.dict(os.environ,{'XDG_CONFIG_HOME':folder}):
   transact=tools['STORE']['transact'];transact('shell','patch',{'theme':'acik','showSeconds':True})
   source=Path(folder)/'import.json';source.write_text(json.dumps({'format':'vabu-preferences-1','document':'shell','values':{'theme':'koyu'}}))
   result=tools['preview'](source.as_uri())
   self.assertEqual(result['changes'],[{'key':'theme','before':'acik','after':'koyu'}])
   self.assertEqual(transact('shell','read')['values']['theme'],'acik')
   tools['apply'](str(source),result['fileDigest'],result['baseDigest'])
   values=transact('shell','read')['values'];self.assertEqual(values['theme'],'koyu');self.assertTrue(values['showSeconds'])

 def test_changed_import_file_or_current_settings_requires_new_preview(self):
  tools=module('preferences')
  with tempfile.TemporaryDirectory() as folder,patch.dict(os.environ,{'XDG_CONFIG_HOME':folder}):
   source=Path(folder)/'import.json';record={'format':'vabu-preferences-1','document':'shell','values':{'theme':'koyu'}};source.write_text(json.dumps(record))
   preview=tools['preview'](str(source));record['values']['theme']='otomatik';source.write_text(json.dumps(record))
   with self.assertRaises(ValueError):tools['apply'](str(source),preview['fileDigest'],preview['baseDigest'])
   preview=tools['preview'](str(source));tools['STORE']['transact']('shell','patch',{'showSeconds':True})
   with self.assertRaises(ValueError):tools['apply'](str(source),preview['fileDigest'],preview['baseDigest'])
   self.assertNotIn('theme',tools['STORE']['transact']('shell','read')['values'])

 def test_import_rejects_sensitive_fields_remote_urls_and_invalid_types(self):
  tools=module('preferences')
  with tempfile.TemporaryDirectory() as folder:
   source=Path(folder)/'import.json'
   for values in ({'clipboardEnabled':True},{'theme':[]},{'notificationPolicies':{'app':'unknown'}},{'theme':None}):
    source.write_text(json.dumps({'format':'vabu-preferences-1','document':'shell','values':values}))
    with self.assertRaises(ValueError):tools['read_record'](str(source))
   with self.assertRaises(ValueError):tools['path_for']('https://example.org/settings.json')
   with self.assertRaises(ValueError):tools['path_for']('file://remote/settings.json')
   source.unlink();os.mkfifo(source)
   with self.assertRaises(ValueError):tools['read_record'](str(source))

 def test_monitor_identity_follows_connector_change_without_serial_storage(self):
  tools=module('display-profiles');monitor={'make':'Example','model':'Panel','serial':'private-serial'}
  profile=tools['save']({'DP-1':{'scale':1.25}}, {'DP-1':monitor})
  self.assertNotIn('private-serial',json.dumps(profile))
  result=tools['resolve'](profile,{'DP-3':monitor})
  self.assertEqual(result['outputs'],{'DP-3':{'scale':1.25}})

 def test_ambiguous_missing_and_extra_monitors_are_not_applied(self):
  tools=module('display-profiles');monitor={'make':'Example','model':'Panel','serial':'same'}
  profile=tools['save']({'DP-1':{'scale':1}}, {'DP-1':monitor})
  for connected in ({},{'DP-2':monitor,'DP-3':monitor},{'DP-2':{'make':'Other'}}):
   with self.assertRaises(ValueError):tools['resolve'](profile,connected)
  profile=tools['save']({'DP-1':{}},{'DP-1':{}})
  with self.assertRaises(ValueError):tools['resolve'](profile,{'DP-1':{}})

 def test_notification_policies_validate_and_match_desktop_suffix(self):
  validate=module('config-store')['validate']
  with self.assertRaises(ValueError):validate('shell',{'notificationPolicies':{'app':'execute'}})
  source=(ROOT/'shell/Notifs.qml').read_text();functions=source[source.index('    function keyFor('):source.index('    function dismissPopup(')]
  script='const assert=require("node:assert/strict");const Config={values:{notificationPolicies:{"org.App":"block","name:Legacy":"silent"}}};'+functions+';assert.equal(policyFor({desktopEntry:"org.App.desktop"}),"block");assert.equal(policyFor({appName:"Legacy"}),"silent");assert.equal(policyFor({appName:"Other"}),"show");'
  result=subprocess.run([shutil.which('node'),'-e',script],capture_output=True,text=True)
  self.assertEqual(result.returncode,0,result.stderr)

 def test_update_history_is_bounded_and_redacted_for_both_scopes(self):
  tools=module('update-events')
  with tempfile.TemporaryDirectory() as folder:
   def destination(system=False):return Path(folder)/('system' if system else 'user')
   with patch.dict(tools['record'].__globals__,{'folder':destination}),patch('os.geteuid',return_value=0):
    for n in range(55):tools['record']({'state':'success','startedAt':n,'phases':[{'phase':'rpm','exitCode':0}],'password':'secret','log':'private'},'external-rpm')
    rows=tools['history']();self.assertEqual(len(rows),50);self.assertNotIn('secret',json.dumps(rows));self.assertNotIn('private',json.dumps(rows))
    self.assertEqual((destination(True)/'update-history.json').stat().st_mode & 0o777,0o644)
   with patch.dict(tools['record'].__globals__,{'folder':destination}),patch('os.geteuid',return_value=1000):
    tools['record']({'state':'failed','startedAt':100,'phases':[{'phase':'flatpak-user','exitCode':1}]},'background-flatpak')
    self.assertEqual(tools['history']()[0]['source'],'background-flatpak')
    self.assertEqual((destination()/ 'update-history.json').stat().st_mode & 0o777,0o600)

 def test_history_updates_same_operation_instead_of_duplicating_it(self):
  tools=module('update-events')
  with tempfile.TemporaryDirectory() as folder,patch.dict(tools['record'].__globals__,{'folder':lambda system=False:Path(folder)}):
   token=tools['record']({'state':'running','startedAt':1},'manual')
   tools['record']({'state':'failed','startedAt':1,'phases':[{'phase':'rpm','exitCode':9}]},'manual',token)
   self.assertEqual(len(tools['history']()),1);self.assertEqual(tools['history']()[0]['state'],'failed')

 def test_background_update_failure_is_recorded_and_nonzero(self):
  tools=module('update-events')
  with tempfile.TemporaryDirectory() as folder,patch.dict(tools['run'].__globals__,{'folder':lambda system=False:Path(folder)}),patch('subprocess.run',return_value=subprocess.CompletedProcess([],8)):
   self.assertEqual(tools['run']('background-flatpak'),8)
   self.assertEqual(tools['history']()[0]['state'],'failed')

 def test_dnf_hook_rejects_injected_ids_before_running_commands(self):
  main=module('transaction-hook')['main']
  with patch('subprocess.run') as run:
   with self.assertRaises(ValueError):main(['post','1;bad','a'*32])
   with self.assertRaises(ValueError):main(['post','1','bad'])
   run.assert_not_called()

 def test_snapshot_usage_missing_data_is_unknown_and_never_triggers_cleanup(self):
  tools=module('desktop-measures')
  calls=[]
  def fake(args):
   calls.append(args)
   if args[0]=='snapper':return 0,'{"root":[{"number":1}]}'
   return 0,'Size Used Avail Use%\n100 30 70 30%'
  with patch.dict(tools['snapshots'].__globals__['TOOLS'],{'run':fake}),patch.object(Path,'read_text',side_effect=OSError):
   result=tools['snapshots']()
  self.assertIsNone(result['snapshots'][0]['usedSpace']);self.assertEqual(result['disk']['available'],70)
  self.assertFalse(any('delete' in arg or 'cleanup' in arg for args in calls for arg in args))

 def test_measurement_sampling_is_bounded_private_and_contains_no_app_titles(self):
  tools=module('desktop-measures')
  fake=lambda:{'processes':[{'memoryMiB':10,'cpu':1,'name':'qs'}],'battery':[{'watts':2.5}]}
  with tempfile.TemporaryDirectory() as folder,patch.dict(os.environ,{'XDG_STATE_HOME':folder}),patch.dict(tools['TOOLS'],{'performance':fake,'run':lambda args:(0,'Startup finished in 2s (kernel) + 3s (userspace) = 5s\n')}):
   result=tools['sample'](2,0)
   self.assertEqual(result['memoryMiB'],10);self.assertEqual(result['batteryWatts'],2.5);self.assertEqual(result['bootSeconds'],5)
   path=Path(folder)/'vabu/measurements.json';self.assertEqual(path.stat().st_mode & 0o777,0o600)
   self.assertNotIn('name',path.read_text())
   with self.assertRaises(ValueError):tools['sample'](1000,0)

 def test_focus_timer_can_be_started_and_stopped_without_losing_panel_preference(self):
  source=(ROOT/'shell/Config.qml').read_text()
  start=re.search(r'function focusFor\(minutes\) \{([^\n]+)',source)[0]
  stop=re.search(r'function stopFocus\(\) \{([^\n]+)',source)[0]
  script='const assert=require("node:assert/strict");let values={sidebarCompact:false};const store={patch(changes){values=Object.assign(values,changes)}};'+start+stop+';const before=Date.now();focusFor(25);assert.equal(values.focusMode,false);assert.ok(values.focusUntil >= before+25*60000);stopFocus();assert.equal(values.focusUntil,null);assert.equal(values.sidebarCompact,false);'
  result=subprocess.run([shutil.which('node'),'-e',script],capture_output=True,text=True)
  self.assertEqual(result.returncode,0,result.stderr)

 def test_missing_process_measurements_are_not_zero(self):
  tools=module('desktop-measures')
  with tempfile.TemporaryDirectory() as folder,patch.dict(os.environ,{'XDG_STATE_HOME':folder}),patch.dict(tools['TOOLS'],{'performance':lambda:{'processes':[],'battery':[]},'run':lambda args:(127,'')}):
   result=tools['sample'](2,0)
  self.assertIsNone(result['memoryMiB']);self.assertIsNone(result['cpuLifetimePercent']);self.assertIsNone(result['batteryWatts']);self.assertIsNone(result['bootSeconds'])

 def test_dnf_hook_preserves_snapshot_pair_and_reports_observation(self):
  main=module('transaction-hook')['main'];records=[];snapshots=[]
  events={'record':lambda data,source,token=None:(records.append((data,source,token)) or 'a'*32),'read':lambda system:[{'id':'a'*32,'startedAt':1}]}
  with patch.dict(main.__globals__,{'EVENTS':events,'snap':lambda args:(snapshots.append(args) or '12')}),patch.object(Path,'is_file',return_value=True),contextlib.redirect_stdout(io.StringIO()) as output:
   main(['pre']);main(['post','12','a'*32])
  self.assertIn('tmp.vabu_pre=12',output.getvalue());self.assertIn('--pre-number',snapshots[1]);self.assertEqual(records[-1][0]['state'],'observed');self.assertEqual(records[-1][0]['phases'],[])

 def test_notification_block_silent_and_critical_focus_behavior(self):
  source=(ROOT/'shell/Notifs.qml').read_text();marker='onNotification: n => {'
  body=source[source.index(marker)+len(marker):source.rfind('        }')]
  script='const assert=require("node:assert/strict");const NotificationUrgency={Critical:1};let policy="show";const root={all:[],popups:[],effectiveDnd:true,policyFor(){return policy},dismissPopup(){}};function receive(n){'+body+'};function n(urgency){return {urgency,tracked:false,closed:{connect(){}},dismiss(){this.dismissed=true}}};let item=n(1);policy="block";receive(item);assert.equal(item.dismissed,true);assert.equal(item.tracked,false);item=n(1);policy="silent";receive(item);assert.equal(item.tracked,true);assert.equal(root.popups.length,0);item=n(1);policy="show";receive(item);assert.equal(root.popups.length,1);root.popups=[];receive(n(0));assert.equal(root.popups.length,0);'
  result=subprocess.run([shutil.which('node'),'-e',script],capture_output=True,text=True)
  self.assertEqual(result.returncode,0,result.stderr)

 def test_shortcut_rewrite_preserves_custom_user_bindings(self):
  rewrite=module('shortcuts')['rewrite']
  text=TEMPLATE.read_text()+'\n// user\nbinds {\n    Mod+Return { spawn "my-personal-terminal"; }\n}\n'
  result=rewrite(text,{'terminal':'Super+Ctrl+T'})
  self.assertIn('Mod+Ctrl+T hotkey-overlay-title="Terminal"',result)
  self.assertTrue(result.endswith('// user\nbinds {\n    Mod+Return { spawn "my-personal-terminal"; }\n}\n'))

 def test_boot_time_milliseconds_are_not_reported_as_zero(self):
  tools=module('desktop-measures')
  with tempfile.TemporaryDirectory() as folder,patch.dict(os.environ,{'XDG_STATE_HOME':folder}),patch.dict(tools['TOOLS'],{'performance':lambda:{'processes':[],'battery':[]},'run':lambda args:(0,'Startup finished in 500ms = 500ms\n')}):
   result=tools['sample'](2,0)
  self.assertEqual(result['bootSeconds'],0.5)

 def test_first_run_waits_for_a_valid_settings_reply(self):
  source=(ROOT/'shell/JsonStore.qml').read_text();start=source.index('onExited: code => {')+len('onExited: code => {');end=source.index('\n        }\n    }\n    Timer {',start);body=source[start:end]
  script='const assert=require("node:assert/strict");let root;const result={text:""};const deadline={stop(){}},watched={reload(){}},pump={restart(){}};function receive(code){'+body+'};function check(text,code,expected){root={active:{action:"read"},values:{},writable:true,ready:false};result.text=text;receive(code);assert.equal(root.writable,expected)};check(JSON.stringify({ok:true,values:{onboardingDone:true},writable:true}),0,true);check(JSON.stringify({ok:false,error:"failed"}),1,false);check("[]",0,false);check("broken",0,false);check(JSON.stringify({ok:true}),0,false);check(JSON.stringify({ok:true,values:{},writable:"false"}),0,false);'
  result=subprocess.run([shutil.which('node'),'-e',script],capture_output=True,text=True)
  self.assertEqual(result.returncode,0,result.stderr)


if __name__=='__main__':unittest.main(verbosity=2)
