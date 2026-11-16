#!/usr/bin/env python3
"""Inspect a public COPR key in memory. Never imports keys, writes files or sets trust."""
import argparse
import base64
import hashlib
import json
from pathlib import Path
import re
import sys
import urllib.parse
import urllib.request

LIMIT=1048576


def public_fingerprint(armor):
 if not isinstance(armor,bytes) or not 0<len(armor)<=LIMIT:raise ValueError('Açık anahtar boyutu geçersiz.')
 lines=armor.decode('ascii').splitlines()
 if not lines or lines[0]!='-----BEGIN PGP PUBLIC KEY BLOCK-----' or '-----END PGP PUBLIC KEY BLOCK-----' not in lines:raise ValueError('Yalnızca zırhlı açık anahtar kabul edilir.')
 payload=[];reading=False;checksum=None
 for line in lines[1:]:
  if line=='-----END PGP PUBLIC KEY BLOCK-----':break
  if not reading:
   if not line:reading=True
   elif ':' not in line:raise ValueError('Anahtar başlığı geçersiz.')
   continue
  if line.startswith('='):checksum=base64.b64decode(line[1:],validate=True)
  elif line:payload.append(line)
 data=base64.b64decode(''.join(payload),validate=True)
 if checksum is not None:
  if len(checksum)!=3:raise ValueError('Anahtar CRC uzunluğu geçersiz.')
  crc=0xB704CE
  for value in data:
   crc^=value<<16
   for _ in range(8):
    crc<<=1
    if crc&0x1000000:crc^=0x1864CFB
  if (crc&0xFFFFFF).to_bytes(3,'big')!=checksum:raise ValueError('Anahtar CRC doğrulaması başarısız.')
 position=0;primary=[]
 while position<len(data):
  header=data[position];position+=1
  if not header&0x80:raise ValueError('OpenPGP paketi geçersiz.')
  if header&0x40:
   tag=header&63
   if position>=len(data):raise ValueError('Paket uzunluğu eksik.')
   length=data[position];position+=1
   if 192<=length<=223:
    if position>=len(data):raise ValueError('Paket uzunluğu eksik.')
    length=((length-192)<<8)+data[position]+192;position+=1
   elif length==255:
    if len(data)-position<4:raise ValueError('Paket uzunluğu eksik.')
    length=int.from_bytes(data[position:position+4],'big');position+=4
   elif length>=224:raise ValueError('Parçalı OpenPGP paketi desteklenmiyor.')
  else:
   tag=(header>>2)&15;mode=header&3
   if mode==3:raise ValueError('Belirsiz uzunluklu paket desteklenmiyor.')
   count=(1,2,4)[mode]
   if len(data)-position<count:raise ValueError('Paket uzunluğu eksik.')
   length=int.from_bytes(data[position:position+count],'big');position+=count
  if length>len(data)-position:raise ValueError('Anahtar paketi eksik.')
  body=data[position:position+length];position+=length
  if tag in (5,7):raise ValueError('Özel anahtar kabul edilmez.')
  if tag==6:primary.append(body)
 if len(primary)!=1 or len(primary[0])<6 or primary[0][0]!=4 or len(primary[0])>65535:raise ValueError('Tek bir OpenPGP v4 açık anahtar gerekli; farklı sürümü ayrıca doğrula.')
 body=primary[0]
 # OpenPGP v4 fingerprints use SHA-1 by specification; the FILE pin uses SHA-256.
 return hashlib.sha1(b'\x99'+len(body).to_bytes(2,'big')+body).hexdigest().upper()


def inspect(data,expected=''):
 fingerprint=public_fingerprint(data)
 normalized=re.sub(r'[ :\t\r\n]','',expected).upper()
 if normalized and (not re.fullmatch(r'[0-9A-F]{40}',normalized) or normalized!=fingerprint):raise ValueError('Açık anahtar güvenilen parmak iziyle uyuşmuyor.')
 return {'publicKeyFingerprint':fingerprint,'fileSHA256':hashlib.sha256(data).hexdigest(),'bytes':len(data),'matchedProvidedFingerprint':bool(normalized)}


def fetch(owner):
 if not re.fullmatch(r'[A-Za-z0-9_-]+',owner):raise ValueError('COPR sahibi geçersiz.')
 url='https://download.copr.fedorainfracloud.org/results/'+owner+'/vabu/pubkey.gpg'
 request=urllib.request.Request(url,headers={'User-Agent':'Vabu-key-inspection/1'})
 with urllib.request.urlopen(request,timeout=20) as response:
  final=urllib.parse.urlsplit(response.geturl())
  if final.scheme!='https' or final.netloc!='download.copr.fedorainfracloud.org':raise ValueError('Beklenmeyen anahtar yönlendirmesi.')
  data=response.read(LIMIT+1)
 if len(data)>LIMIT:raise ValueError('Açık anahtar çok büyük.')
 return data


if __name__=='__main__':
 parser=argparse.ArgumentParser(description='COPR açık anahtarını yalnızca bellekte incele; güven ayarı yapmaz.')
 parser.add_argument('--fetch',action='store_true',help='Açık anahtarı HTTPS ile belleğe oku; dosya kaydedilmez.')
 parser.add_argument('--owner',default=(Path(__file__).resolve().parents[1]/'COPR_OWNER').read_text().strip())
 parser.add_argument('--expected-fingerprint',default='',help='Bağımsız doğrulanan COPR OpenPGP parmak izi (varsa).')
 args=parser.parse_args()
 try:
  data=fetch(args.owner) if args.fetch else sys.stdin.buffer.read(LIMIT+1)
  print(json.dumps(inspect(data,args.expected_fingerprint),indent=2))
  if not args.expected_fingerprint:print('Özet kimliği tek başına kanıtlamaz. Doğru COPR projesini ve anahtar parmak izini güvenilen kanaldan doğrula.',file=sys.stderr)
 except (OSError,ValueError,UnicodeError) as error:
  print('Açık anahtar doğrulanamadı: '+str(error),file=sys.stderr);sys.exit(1)
