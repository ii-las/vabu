#!/usr/bin/env python3
"""Public key bootstrap parser tests using artificial bytes only; no network."""
import base64
import hashlib
from pathlib import Path
import runpy
import unittest
from unittest.mock import patch

ROOT=Path(__file__).resolve().parents[1]
TOOLS=runpy.run_path(str(ROOT/'tools/copr-key-info.py'),run_name='key_info_tests')


def armor(packet):return b'-----BEGIN PGP PUBLIC KEY BLOCK-----\n\n'+base64.b64encode(packet)+b'\n-----END PGP PUBLIC KEY BLOCK-----\n'


class KeySetup(unittest.TestCase):
 def test_file_hash_uses_original_bytes_and_standard_v4_fingerprint(self):
  body=b'\x04\x00\x00\x00\x01\x01'+b'artificial-test-data'
  data=armor(b'\xc6'+bytes([len(body)])+body)
  result=TOOLS['inspect'](data)
  self.assertEqual(result['fileSHA256'],hashlib.sha256(data).hexdigest())
  self.assertEqual(result['publicKeyFingerprint'],hashlib.sha1(b'\x99'+len(body).to_bytes(2,'big')+body).hexdigest().upper())
  self.assertFalse(result['matchedProvidedFingerprint'])
  self.assertTrue(TOOLS['inspect'](data,result['publicKeyFingerprint'])['matchedProvidedFingerprint'])
  with self.assertRaises(ValueError):TOOLS['inspect'](data,'F'*40)
  self.assertNotEqual(TOOLS['inspect'](data.replace(b'\n',b'\r\n'))['fileSHA256'],result['fileSHA256'])

 def test_rejects_empty_html_private_truncated_and_multiple_primary_keys(self):
  for data in (b'',b'<html>error</html>',b'-----BEGIN PGP PRIVATE KEY BLOCK-----',armor(b'\xc5\x06\x04abcde'),armor(b'\xc6\x20short'),armor(b'\xc6\x06\x04abcde\xc6\x06\x04abcde'),armor(b'\xc6\xe0data')):
   with self.subTest(data=data),self.assertRaises(ValueError):TOOLS['inspect'](data)

 def test_invalid_owner_never_fetches(self):
  with patch('urllib.request.urlopen') as fetch:
   with self.assertRaises(ValueError):TOOLS['fetch']('../other')
   fetch.assert_not_called()

 def test_redirect_and_size_guards(self):
  class Response:
   def __enter__(self):return self
   def __exit__(self,*args):pass
   def geturl(self):return 'http://untrusted.example/key'
   def read(self,*args):raise AssertionError('must reject before reading')
  with patch('urllib.request.urlopen',return_value=Response()):
   with self.assertRaises(ValueError):TOOLS['fetch']('ii-las')


if __name__=='__main__':unittest.main(verbosity=2)
