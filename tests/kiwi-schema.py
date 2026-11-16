#!/usr/bin/env python3
"""Validate both ISO descriptions using CI's real installed KIWI schema.
The temporary key files are schema fixtures, never keys for a package install.
No image build, dependency resolution, mount or block device is invoked.
"""
import os
from pathlib import Path
import runpy
import subprocess
import tempfile

ROOT=Path(__file__).resolve().parents[1]


def main():
    if os.environ.get('VABU_TEST_ISOLATED')!='1':
        raise SystemExit('Yalnızca ayrılmış CI/test ortamında şema kontrolü yapılır.')
    materialize=runpy.run_path(str(ROOT/'tools/prepare-iso-keys.py'),run_name='schema_keys')['materialize_local_keys']
    fedora=(ROOT/'FEDORA_VERSION').read_text().strip()
    for arch in ('x86_64','aarch64'):
        with tempfile.TemporaryDirectory(prefix='vabu-kiwi-schema-') as folder:
            description=Path(folder)
            text=(ROOT/'iso/config.kiwi').read_text().replace('@FEDORA@',fedora).replace('@ARCH@',arch)
            (description/'config.kiwi').write_text(text)
            (description/'keys').mkdir()
            for name in ('fedora.asc','rpmfusion-free.asc','rpmfusion-nonfree.asc','vabu.asc'):
                (description/'keys'/name).write_text('SCHEMA FIXTURE ONLY; NOT A PACKAGE SIGNING KEY')
            materialize(description)
            result=subprocess.run(['kiwi-ng','image','info','--description',str(description),'--print-xml'],capture_output=True,text=True,timeout=60)
            if result.returncode:
                print(result.stdout);print(result.stderr)
                raise SystemExit(result.returncode)
            print(arch+': real KIWI schema validation passed')


if __name__=='__main__':main()
