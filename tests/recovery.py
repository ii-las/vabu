#!/usr/bin/env python3
"""Recovery state-machine tests on private ordinary directories only.
Btrfs, live boot checks, syncfs and atomic exchange are simulated. No block device,
mount, format, host /boot, EFI, RPM, chroot or network operation is executed.
"""
import contextlib
import io
import json
import os
from pathlib import Path
import runpy
import shutil
import stat
from types import SimpleNamespace
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch
import uuid

ROOT=Path(__file__).resolve().parents[1]
LIB=ROOT/'rootfs/usr/libexec/vabu'
ENGINE=runpy.run_path(str(LIB/'recovery'),run_name='recovery_tests')
FS=ENGINE['FS'];REAL_RENAME=os.rename
IDS={'root':'11111111-1111-1111-1111-111111111111','boot':'22222222-2222-2222-2222-222222222222','efi':'aaaa-bbbb','encryption':None}


class InjectedCrash(OSError):pass


class FakeBackend:
 def __init__(self,base):self.base=base;self.events=0;self.fail_after=None
 def guard(self):pass
 def layout(self,top,boot,efi,write=False):
  for value in (top,boot,efi):
   if not Path(value).is_relative_to(self.base):raise AssertionError('Test escaped temporary directory')
  return dict(IDS)
 def command(self,args):
  if args[:4]==['btrfs','subvolume','list','-o']:return ''
  raise AssertionError('Unexpected system command: '+str(args))
 def subvolume(self,path):return json.loads((Path(path)/'.fake-volume').read_text())
 def readonly(self,path):return self.subvolume(path)['ro']
 def snapshot(self,source,target,readonly):
  shutil.copytree(source,target,symlinks=True)
  data={'uuid':str(uuid.uuid4()),'parent':self.subvolume(source)['uuid'],'ro':readonly,'generation':'1'}
  (Path(target)/'.fake-volume').write_text(json.dumps(data));self.tick()
 def prepare_root(self,path):
  (Path(path)/'.snapshots').mkdir(exist_ok=True)
  (Path(path)/'.autorelabel').touch();self.tick()
 def exchange(self,left,right):
  temporary=Path(left).parent/('.swap-'+uuid.uuid4().hex)
  REAL_RENAME(left,temporary);REAL_RENAME(right,left);REAL_RENAME(temporary,right)
  self.tick()
 def validate_installation(self,root,boot,efi,layout):
  return FS['LinuxBackend'].validate_installation(self,root,boot,efi,layout)
 def sync(self,path):self.tick()
 def tick(self):
  self.events+=1
  if self.fail_after==self.events:raise InjectedCrash('simulated interruption')


class Recovery(unittest.TestCase):
 def setUp(self):
  self.tmp=tempfile.TemporaryDirectory(prefix='vabu-recovery-test-')
  self.base=Path(self.tmp.name).resolve();self.top=self.base/'top';self.boot=self.base/'boot';self.efi=self.base/'efi'
  for path in (self.top,self.boot,self.efi):path.mkdir(mode=0o700)
  self.root=self.top/'root';self.root.mkdir()
  for folder in ('usr/lib/modules/1.0.x86_64','etc','home','var/log','.snapshots'):(self.root/folder).mkdir(parents=True,exist_ok=True)
  (self.root/'.fake-volume').write_text(json.dumps({'uuid':str(uuid.uuid4()),'parent':'-','ro':False,'generation':'1'}))
  (self.root/'usr/lib/os-release').write_text('ID=vabu\n')
  (self.root/'etc/machine-id').write_text('a'*32+'\n')
  (self.root/'etc/fstab').write_text('\n'.join([
   'UUID='+IDS['root']+' / btrfs defaults,subvol=/root 0 0',
   'UUID='+IDS['root']+' /home btrfs defaults,subvol=/home 0 0',
   'UUID='+IDS['root']+' /var/log btrfs defaults,subvol=/var/log 0 0',
   'UUID='+IDS['boot']+' /boot ext4 defaults 0 2',
   'UUID='+IDS['efi']+' /boot/efi vfat umask=0077 0 2'])+'\n')
  (self.root/'usr/lib/modules/1.0.x86_64/vmlinuz').write_bytes(b'kernel-v1')
  (self.root/'etc/release-marker').write_text('before')
  (self.boot/'loader/entries').mkdir(parents=True)
  (self.boot/'vmlinuz-1.0.x86_64').write_bytes(b'kernel-v1')
  (self.boot/'initramfs-1.0.x86_64.img').write_bytes(b'init-v1')
  (self.boot/'loader/entries/test.conf').write_text('title Vabu\nlinux /vmlinuz-1.0.x86_64\ninitrd /initramfs-1.0.x86_64.img\noptions root=UUID='+IDS['root']+' rootflags=subvol=root quiet\n')
  (self.efi/'EFI/fedora').mkdir(parents=True);(self.efi/'EFI/other-os').mkdir()
  (self.efi/'EFI/fedora/grub.cfg').write_text('search --fs-uuid '+IDS['boot'])
  (self.efi/'EFI/fedora/grubx64.efi').write_bytes(b'MZgrub-v1')
  (self.efi/'EFI/fedora/shimx64.efi').write_bytes(b'MZshim-v1')
  (self.efi/'EFI/other-os/keep.efi').write_bytes(b'never-touch')
  (self.top/'home').mkdir();(self.top/'home/user-data').write_text('keep home')
  (self.top/'var/log').mkdir(parents=True);(self.top/'var/log/log').write_text('keep logs')
  self.backend=FakeBackend(self.base)
  self.engine=ENGINE['Engine'](self.top,self.boot,self.efi,self.backend)
  self.engine.space=lambda *args:None
 def tearDown(self):self.tmp.cleanup()
 def point(self):return self.engine.create('before update')['id']
 def update_files(self):
  (self.root/'etc/release-marker').write_text('after')
  (self.root/'usr/lib/modules/1.0.x86_64/vmlinuz').write_bytes(b'kernel-v2')
  (self.boot/'vmlinuz-1.0.x86_64').write_bytes(b'kernel-v2')
  (self.boot/'initramfs-1.0.x86_64.img').write_bytes(b'init-v2')
  (self.boot/'new-only').write_text('new boot item')
  (self.efi/'EFI/fedora/grubx64.efi').write_bytes(b'MZgrub-v2')
 def apply(self,point):return self.engine.apply(point,self.engine.plan(point)['confirmation'],True)
 def assert_preserved(self):
  self.assertEqual((self.top/'home/user-data').read_text(),'keep home')
  self.assertEqual((self.top/'var/log/log').read_text(),'keep logs')
  self.assertEqual((self.efi/'EFI/other-os/keep.efi').read_bytes(),b'never-touch')

 def test_capture_apply_and_undo_restore_matching_components(self):
  point=self.point();self.update_files();operation=self.apply(point)['id']
  self.assertEqual((self.root/'etc/release-marker').read_text(),'before')
  self.assertEqual((self.boot/'vmlinuz-1.0.x86_64').read_bytes(),b'kernel-v1')
  self.assertEqual((self.efi/'EFI/fedora/grubx64.efi').read_bytes(),b'MZgrub-v1')
  self.assertFalse((self.boot/'new-only').exists());self.assertTrue((self.root/'.autorelabel').exists())
  self.assert_preserved()
  self.engine.undo(operation,operation,True)
  self.assertEqual((self.root/'etc/release-marker').read_text(),'after')
  self.assertEqual((self.boot/'vmlinuz-1.0.x86_64').read_bytes(),b'kernel-v2')
  self.assertEqual((self.efi/'EFI/fedora/grubx64.efi').read_bytes(),b'MZgrub-v2')
  self.assertEqual((self.boot/'new-only').read_text(),'new boot item');self.assert_preserved()
  self.assertEqual(self.engine.undo(operation,operation,True)['state'],'undone')

 def test_plan_is_read_only_and_stale_confirmation_is_rejected(self):
  point=self.point();plan=self.engine.plan(point)
  before=sorted(str(p.relative_to(self.base)) for p in self.base.rglob('*'))
  self.engine.plan(point)
  self.assertEqual(before,sorted(str(p.relative_to(self.base)) for p in self.base.rglob('*')))
  self.update_files()
  with self.assertRaises(ValueError):self.engine.apply(point,plan['confirmation'],True)
  self.assertEqual((self.root/'etc/release-marker').read_text(),'after')
  self.assertFalse((self.engine.store/'operations').exists())

 def test_acknowledgement_and_exact_operation_confirmation_are_required(self):
  point=self.point()
  with self.assertRaises(ValueError):self.engine.apply(point,self.engine.plan(point)['confirmation'],False)
  with self.assertRaises(ValueError):self.engine.resume('a'*32,'b'*32,True)
  with self.assertRaises(ValueError):self.engine.undo('a'*32,'a'*32,False)

 def test_checkpoint_tamper_or_readwrite_snapshot_is_rejected_before_changes(self):
  point=self.point();path=self.engine.store/'checkpoints'/point
  (path/'boot/vmlinuz-1.0.x86_64').write_bytes(b'tampered')
  with self.assertRaises(ValueError):self.engine.plan(point)
  self.assertFalse((self.engine.store/'operations').exists())

 def test_wrong_filesystem_identity_is_rejected(self):
  point=self.point();self.engine.layout={**IDS,'boot':'33333333-3333-3333-3333-333333333333'}
  with self.assertRaises(ValueError):self.engine.plan(point)

 def test_capture_rejects_kernel_mismatch_and_fixed_root_subvolid(self):
  (self.boot/'vmlinuz-1.0.x86_64').write_bytes(b'wrong')
  with self.assertRaises(ValueError):self.point()
  (self.boot/'vmlinuz-1.0.x86_64').write_bytes(b'kernel-v1')
  path=self.root/'etc/fstab';path.write_text(path.read_text().replace('subvol=/root','subvolid=256'))
  with self.assertRaises(ValueError):self.point()
  self.assertFalse(any((self.engine.store/'checkpoints').iterdir()))

 def test_root_or_checkpoint_path_cannot_be_symlinked(self):
  point=self.point();path=self.engine.store/'checkpoints'/point
  REAL_RENAME(path,path.with_name('a'*32));path.symlink_to(path.with_name('a'*32),target_is_directory=True)
  with self.assertRaises(ValueError):self.engine.plan(point)

 def test_inventory_preserves_symlink_without_following_it(self):
  outside=self.base/'outside';outside.write_text('private')
  (self.boot/'link').symlink_to(outside)
  point=self.point();backup=self.engine.store/'checkpoints'/point/'boot/link'
  self.assertTrue(backup.is_symlink());self.assertEqual(os.readlink(backup),str(outside))
  self.assertEqual(outside.read_text(),'private')

 def test_inventory_rejects_fifo_and_writable_boot_entries(self):
  os.mkfifo(self.boot/'unsafe')
  with self.assertRaises(ValueError):FS['inventory'](self.boot)
  (self.boot/'unsafe').unlink();(self.boot/'unsafe').write_text('x');(self.boot/'unsafe').chmod(0o666)
  with self.assertRaises(ValueError):FS['inventory'](self.boot)

 def test_resume_after_every_durability_boundary(self):
  # First determine how many snapshot/sync/exchange boundaries this plan traverses.
  point=self.point();self.update_files();start=self.backend.events;operation=self.apply(point)['id'];count=self.backend.events-start
  self.engine.undo(operation,operation,True)
  for boundary in range(1,count+1):
   with self.subTest(boundary=boundary):
    fixture=Recovery('test_capture_apply_and_undo_restore_matching_components');fixture.setUp()
    try:
     point=fixture.point();fixture.update_files();fixture.backend.fail_after=fixture.backend.events+boundary
     try:fixture.apply(point)
     except InjectedCrash:pass
     fixture.backend.fail_after=None
     operations=list((fixture.engine.store/'operations').iterdir())
     if not operations:continue
     token=operations[0].name;result=fixture.engine.resume(token,token,True)
     self.assertEqual(result['state'],'complete')
     self.assertEqual((fixture.root/'etc/release-marker').read_text(),'before')
     self.assertEqual((fixture.boot/'vmlinuz-1.0.x86_64').read_bytes(),b'kernel-v1');fixture.assert_preserved()
    finally:fixture.tearDown()

 def test_resume_after_each_boot_rename(self):
  point=self.point();self.update_files();calls=[]
  def count(source,target):calls.append((str(source),str(target)));return REAL_RENAME(source,target)
  with patch.dict(ENGINE['Engine'].move_step.__globals__['os'].__dict__,{'rename':count}):operation=self.apply(point)['id']
  self.engine.undo(operation,operation,True)
  for boundary in range(1,len(calls)+1):
   with self.subTest(rename=boundary):
    fixture=Recovery('test_capture_apply_and_undo_restore_matching_components');fixture.setUp()
    try:
     point=fixture.point();fixture.update_files();counter=[0]
     def interrupt(source,target):
      REAL_RENAME(source,target);counter[0]+=1
      if counter[0]==boundary:raise InjectedCrash('rename interrupted')
     with patch('os.rename',side_effect=interrupt):
      with self.assertRaises(InjectedCrash):fixture.apply(point)
     token=next((fixture.engine.store/'operations').iterdir()).name
     fixture.engine.resume(token,token,True)
     self.assertEqual((fixture.boot/'vmlinuz-1.0.x86_64').read_bytes(),b'kernel-v1');fixture.assert_preserved()
    finally:fixture.tearDown()

 def test_undo_can_abort_a_partial_apply(self):
  point=self.point();self.update_files();counter=[0]
  def interrupt(source,target):
   REAL_RENAME(source,target);counter[0]+=1
   if counter[0]==2:raise InjectedCrash('after boot update')
  with patch('os.rename',side_effect=interrupt):
   with self.assertRaises(InjectedCrash):self.apply(point)
  token=next((self.engine.store/'operations').iterdir()).name
  self.engine.undo(token,token,True)
  self.assertEqual((self.root/'etc/release-marker').read_text(),'after')
  self.assertEqual((self.boot/'vmlinuz-1.0.x86_64').read_bytes(),b'kernel-v2');self.assert_preserved()

 def test_undo_is_resumable_after_interruption(self):
  point=self.point();self.update_files();token=self.apply(point)['id'];counter=[0]
  def interrupt(source,target):
   REAL_RENAME(source,target);counter[0]+=1
   if counter[0]==1:raise InjectedCrash('undo rename interrupted')
  with patch('os.rename',side_effect=interrupt):
   with self.assertRaises(InjectedCrash):self.engine.undo(token,token,True)
  self.assertEqual(self.engine.resume(token,token,True)['state'],'undone')
  self.assertEqual((self.root/'etc/release-marker').read_text(),'after')
  self.assertEqual((self.boot/'vmlinuz-1.0.x86_64').read_bytes(),b'kernel-v2')

 def test_corrupt_candidate_identity_is_rejected_before_boot_changes(self):
  point=self.point();self.update_files();self.backend.fail_after=self.backend.events+4
  with self.assertRaises(InjectedCrash):self.apply(point)
  self.backend.fail_after=None;token=next((self.engine.store/'operations').iterdir()).name
  # Prepare to the first installed rename, then stop.
  def refuse(*args):raise InjectedCrash('before first mutation')
  with patch('os.rename',side_effect=refuse):
   with self.assertRaises(InjectedCrash):self.engine.resume(token,token,True)
  path=self.engine.store/'operations'/token/'candidate/.fake-volume';data=json.loads(path.read_text());data['uuid']=str(uuid.uuid4());path.write_text(json.dumps(data))
  before=FS['inventory'](self.boot,FS['EXCLUDED'])
  with self.assertRaises(ValueError):self.engine.resume(token,token,True)
  self.assertEqual(FS['inventory'](self.boot,FS['EXCLUDED']),before)

 def test_no_automatic_pruning_or_reboot_and_capture_limit_is_enforced(self):
  for n in range(6):self.point()
  with self.assertRaises(ValueError):self.point()
  self.assertEqual(len(self.engine.listing()['checkpoints']),6);self.assert_preserved()

 def test_cli_refuses_this_nonlinux_host_before_writing(self):
  if sys.platform=='linux':self.skipTest('non-Linux guard is tested on a non-Linux host')
  before=sorted(str(p) for p in self.base.rglob('*'))
  result=subprocess.run([sys.executable,'-I',str(LIB/'recovery'),'create','--top',str(self.top),'--boot',str(self.boot),'--efi',str(self.efi)],capture_output=True,text=True)
  self.assertNotEqual(result.returncode,0)
  self.assertEqual(before,sorted(str(p) for p in self.base.rglob('*')))

 def test_guard_refuses_nonroot_or_installed_host_without_mutating(self):
  backend=FS['LinuxBackend']()
  for platform,uid,cmdline in (('darwin',0,''),('linux',1000,'root=live:CDLABEL=test'),('linux',0,'root=UUID=installed')):
   with patch.object(sys,'platform',platform),patch('os.geteuid',return_value=uid),patch.object(Path,'exists',return_value=False),patch.object(Path,'read_text',return_value=cmdline),patch('subprocess.run') as run,patch.object(Path,'mkdir') as mkdir:
    with self.assertRaises(ValueError):backend.guard()
    run.assert_not_called();mkdir.assert_not_called()

 def test_backend_layout_rejects_active_duplicate_nested_and_readonly_mounts(self):
  backend=FS['LinuxBackend']()
  mounts=[{'target':str(path),'source':'/dev/test'+str(n),'fstype':fs,'fsroot':'/','uuid':IDS[key],'options':'rw','maj:min':'8:'+str(n)} for n,(path,fs,key) in enumerate(((self.top,'btrfs','root'),(self.boot,'ext4','boot'),(self.efi,'vfat','efi')))]
  def command(args):
   if args[:3]==['btrfs','inspect-internal','rootid']:return '5\n'
   if args[:3]==['btrfs','subvolume','show']:return 'UUID: '+str(uuid.uuid4())+'\nParent UUID: -\nGeneration: 1\n'
   raise AssertionError(args)
  original=Path.iterdir
  def directories(path):return iter(()) if str(path)=='/proc' else original(path)
  with patch.object(backend,'guard'),patch.object(backend,'command',side_effect=command),patch.object(Path,'iterdir',directories):
   with patch.object(backend,'mounts',return_value=mounts):self.assertEqual(backend.layout(self.top,self.boot,self.efi),IDS)
   cases=[mounts+[dict(mounts[0],target='/')],mounts+[dict(mounts[1],target=str(self.boot/'extra'),uuid='bbbb-cccc')], [dict(row,options='ro') if n==1 else row for n,row in enumerate(mounts)], [dict(row,fstype='ext4') if n==0 else row for n,row in enumerate(mounts)], [dict(row,fsroot='/root') if n==0 else row for n,row in enumerate(mounts)]]
   for case in cases:
    with self.subTest(mounts=case),patch.object(backend,'mounts',return_value=case):
     with self.assertRaises(ValueError):backend.layout(self.top,self.boot,self.efi,write=True)

 def test_missing_space_and_unsupported_exchange_leave_installed_files_unchanged(self):
  point=self.point();self.update_files();before=FS['inventory'](self.boot,FS['EXCLUDED'])
  self.engine.space=ENGINE['Engine'].space.__get__(self.engine)
  with patch('shutil.disk_usage',return_value=type('Usage',(),{'free':0})()):
   with self.assertRaises(ValueError):self.apply(point)
  self.assertEqual(FS['inventory'](self.boot,FS['EXCLUDED']),before)
  token=next((self.engine.store/'operations').iterdir()).name
  self.assertEqual(self.engine.undo(token,token,True)['state'],'undone')

 def test_exchange_unsupported_before_boot_commit(self):
  point=self.point();self.update_files();before=FS['inventory'](self.boot,FS['EXCLUDED'])
  with patch.object(self.backend,'exchange',side_effect=OSError('unsupported')):
   with self.assertRaises(OSError):self.apply(point)
  self.assertEqual(FS['inventory'](self.boot,FS['EXCLUDED']),before)
  token=next((self.engine.store/'operations').iterdir()).name
  self.engine.undo(token,token,True);self.assertEqual((self.root/'etc/release-marker').read_text(),'after')

 def test_completed_resume_is_idempotent_and_does_not_exchange_again(self):
  point=self.point();self.update_files();token=self.apply(point)['id']
  with patch.object(self.backend,'exchange',side_effect=AssertionError('must not exchange')):
   self.assertEqual(self.engine.resume(token,token,True)['state'],'complete')

 def test_undo_before_prepare_can_resume_without_candidate(self):
  point=self.point();self.update_files()
  with patch.object(self.backend,'snapshot',side_effect=InjectedCrash('before candidate')):
   with self.assertRaises(InjectedCrash):self.apply(point)
  token=next((self.engine.store/'operations').iterdir()).name
  path,journal=self.engine.operation(token);journal['state']='undoing';FS['atomic_json'](path/'journal.json',journal)
  self.assertEqual(self.engine.resume(token,token,True)['state'],'undone')
  self.assertEqual((self.root/'etc/release-marker').read_text(),'after')

 def test_corrupt_manifest_seal_and_path_traversal_are_refused(self):
  point=self.point();path=self.engine.store/'checkpoints'/point/'manifest.json'
  record=json.loads(path.read_text());record['label']='changed';path.write_text(json.dumps(record))
  with self.assertRaises(ValueError):self.engine.plan(point)
  for token in ('../root','/','', 'a'*31):
   with self.assertRaises(ValueError):self.engine.plan(token)

 def test_stage_corruption_is_detected_before_any_installed_rename(self):
  point=self.point();self.update_files()
  with patch('os.rename',side_effect=InjectedCrash('before commit')):
   with self.assertRaises(InjectedCrash):self.apply(point)
  token=next((self.engine.store/'operations').iterdir()).name
  (self.boot/'.vabu-recovery'/token/'new/vmlinuz-1.0.x86_64').write_bytes(b'corrupt')
  before=FS['inventory'](self.boot,FS['EXCLUDED'])
  with self.assertRaises(ValueError):self.engine.resume(token,token,True)
  self.assertEqual(FS['inventory'](self.boot,FS['EXCLUDED']),before)

 def test_checkpoint_requires_a_complete_efi_loader(self):
  (self.efi/'EFI/fedora/grubx64.efi').unlink()
  with self.assertRaises(ValueError):self.point()

 def test_second_apply_refuses_an_unfinished_first_operation(self):
  point=self.point();self.update_files()
  with patch('os.rename',side_effect=InjectedCrash('before commit')):
   with self.assertRaises(InjectedCrash):self.apply(point)
  before=len(list((self.engine.store/'operations').iterdir()))
  with self.assertRaises(ValueError):self.apply(point)
  self.assertEqual(len(list((self.engine.store/'operations').iterdir())),before)

 def test_shared_boot_entries_cannot_point_to_another_root(self):
  entry=self.boot/'loader/entries/test.conf'
  entry.write_text(entry.read_text().replace('root=UUID='+IDS['root'],'root=UUID=44444444-4444-4444-4444-444444444444'))
  with self.assertRaises(ValueError):self.point()

 def test_target_or_encryption_change_after_opening_is_rejected(self):
  point=self.point();self.update_files()
  with patch.object(self.backend,'layout',return_value={**IDS,'encryption':{'kind':'luks2','uuid':'changed'}}):
   with self.assertRaises(ValueError):self.engine.apply(point,'a'*64,True)
  self.assertFalse((self.engine.store/'operations').exists())

 def test_luks_identity_uses_block_device_number_not_btrfs_mount_number(self):
  backend=FS['LinuxBackend']();expected='/sys/dev/block/37:7/dm/uuid'
  information=SimpleNamespace(st_mode=stat.S_IFBLK,st_rdev=os.makedev(37,7))
  commands=[]
  def command(args):
   commands.append(args)
   if args[:2]==['cryptsetup','status']:return 'device: /dev/test-underlying\n'
   if args[:2]==['cryptsetup','luksUUID']:return '11111111-1111-1111-1111-111111111111\n'
   if args[:2]==['cryptsetup','luksDump']:return '{"keyslots":{}}'
   raise AssertionError(args)
  with patch.object(Path,'stat',return_value=information),patch.object(Path,'is_file',lambda path:str(path)==expected),patch.object(Path,'read_text',return_value='CRYPT-LUKS2-test'),patch.object(Path,'is_block_device',return_value=True),patch.object(backend,'command',side_effect=command):
   result=backend.encryption({'source':'/dev/mapper/test','maj:min':'0:123'})
  self.assertEqual(result['kind'],'luks2')
  self.assertEqual(commands[0],['cryptsetup','status','/dev/mapper/test'])

 def test_relabel_marker_refuses_special_files_and_links(self):
  backend=FS['LinuxBackend']();marker=self.root/'.autorelabel'
  backend._relabel(self.root);self.assertTrue(marker.is_file())
  marker.unlink();os.mkfifo(marker)
  with self.assertRaises((OSError,ValueError)):backend._relabel(self.root)
  marker.unlink();outside=self.base/'untouched';outside.write_text('keep')
  marker.symlink_to(outside)
  with self.assertRaises((OSError,ValueError)):backend._relabel(self.root)
  self.assertEqual(outside.read_text(),'keep')

 def test_lock_fifo_is_rejected_without_blocking(self):
  self.point();lock=self.top/'.vabu-recovery/.lock'
  lock.unlink();os.mkfifo(lock,0o600)
  with self.assertRaises((OSError,ValueError)):self.engine.listing()

 def test_untrusted_ancestor_and_external_config_links_are_rejected(self):
  parent=self.base/'untrusted';parent.mkdir();parent.chmod(0o777)
  child=parent/'private';child.mkdir(mode=0o700)
  try:
   with self.assertRaises(ValueError):FS['directory'](child)
  finally:parent.chmod(0o700)
  outside=self.base/'outside';outside.mkdir();(outside/'record').write_text('untrusted')
  (self.root/'escape').symlink_to(outside,target_is_directory=True)
  with self.assertRaises(ValueError):FS['local_text'](self.root,'escape/record')
  fifo=self.root/'fifo';os.mkfifo(fifo)
  with self.assertRaises(ValueError):FS['local_text'](self.root,'fifo')

 def test_readonly_flag_and_snapshot_generation_are_bound_to_checkpoint(self):
  point=self.point();path=self.engine.store/'checkpoints'/point/'root/.fake-volume';data=json.loads(path.read_text())
  for changed in ({**data,'ro':False},{**data,'generation':'2'}):
   path.write_text(json.dumps(changed))
   with self.assertRaises(ValueError):self.engine.plan(point)
  path.write_text(json.dumps(data));self.assertIn('confirmation',self.engine.plan(point))


if __name__=='__main__':unittest.main(verbosity=2)
