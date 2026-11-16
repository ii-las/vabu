#!/usr/bin/env python3
"""Build-container-only key preparation. COPR key must match an out-of-band pin."""
import hashlib
import os
from pathlib import Path
import re
import shutil
import sys
import tempfile
import xml.etree.ElementTree as ET
import urllib.request


def prepare(description, key_root, fedora, owner, expected, fetch=None):
    if not re.fullmatch(r'[0-9]+', fedora) or not re.fullmatch(r'[A-Za-z0-9_-]+', owner):
        raise ValueError('Geçersiz Fedora sürümü veya COPR sahibi.')
    if not re.fullmatch(r'[0-9a-fA-F]{64}', expected):
        raise ValueError('Doğrulanmış COPR_KEY_SHA256 gerekli; anahtar kendiliğinden güvenilir sayılmayacak.')
    names = {
        'fedora.asc': Path(key_root) / 'fedora' / f'RPM-GPG-KEY-fedora-{fedora}-primary',
        'rpmfusion-free.asc': Path(key_root) / 'rpmfusion' / f'RPM-GPG-KEY-rpmfusion-free-fedora-{fedora}',
        'rpmfusion-nonfree.asc': Path(key_root) / 'rpmfusion' / f'RPM-GPG-KEY-rpmfusion-nonfree-fedora-{fedora}',
    }
    # Validate all locally supplied official keys before making any remote request.
    contents = {name: source.read_bytes() for name, source in names.items()}
    if any(not data.startswith(b'-----BEGIN PGP PUBLIC KEY BLOCK-----') for data in contents.values()):
        raise ValueError('Dağıtım anahtar paketi geçersiz.')
    url = f'https://download.copr.fedorainfracloud.org/results/{owner}/vabu/pubkey.gpg'
    if fetch is None:
        with urllib.request.urlopen(url, timeout=20) as response:
            data = response.read(1_048_577)
    else:
        data = fetch(url)
    if len(data) > 1_048_576 or hashlib.sha256(data).hexdigest() != expected.lower():
        raise ValueError('COPR anahtarı güvenilen özetle uyuşmuyor; ISO derlemesi durduruldu.')
    contents['vabu.asc'] = data
    destination = Path(description) / 'keys'
    destination.mkdir(parents=True, exist_ok=True)
    for name, data in contents.items():
        (destination / name).write_bytes(data)


def materialize_local_keys(description):
    """Use RFC 8089 file URIs accepted by Fedora's installed KIWI schema."""
    description = Path(description).resolve(strict=True)
    configuration = description / 'config.kiwi'
    if configuration.is_symlink():
        raise ValueError('ISO tanımı sembolik bağlantı olamaz.')
    parser = ET.XMLParser(target=ET.TreeBuilder(insert_comments=True))
    image = ET.fromstring(configuration.read_bytes(), parser=parser)
    if image.findtext('preferences/rpm-check-signatures') != 'true':
        raise ValueError('ISO paket imzası denetimi etkin olmalı.')
    names = {'fedora.asc', 'rpmfusion-free.asc', 'rpmfusion-nonfree.asc', 'vabu.asc'}
    expected = {name: (description / 'keys' / name).as_uri() for name in names}
    repositories = image.findall('repository')
    if any(repo.get('package_gpgcheck') != 'true' for repo in repositories):
        raise ValueError('Her ISO deposunda paket imzası denetimi açıkça etkin olmalı.')
    nodes = image.findall('repository/source/signing')
    if not nodes or len(nodes) != len(repositories):
        raise ValueError('Her ISO deposu açık bir yerel anahtar belirtmeli.')
    used = set()
    for node in nodes:
        uri = node.get('key', '')
        matches = [name for name in names if uri in ('this://keys/' + name, expected[name])]
        if len(matches) != 1:
            raise ValueError('Beklenmeyen ISO imza anahtarı yolu.')
        name = matches[0]
        key = description / 'keys' / name
        if key.is_symlink() or not key.is_file():
            raise ValueError('Hazırlanmış yerel imza anahtarı eksik veya geçersiz.')
        used.add(name)
        node.set('key', expected[name])
    if used != names:
        raise ValueError('Gerekli ISO depo anahtarlarından biri eksik.')
    fd, temporary = tempfile.mkstemp(prefix='.config-keys-', dir=description)
    try:
        with os.fdopen(fd, 'wb') as stream:
            ET.ElementTree(image).write(stream, encoding='utf-8', xml_declaration=True)
            stream.flush()
            os.fsync(stream.fileno())
        os.replace(temporary, configuration)
    finally:
        if os.path.exists(temporary):
            os.unlink(temporary)


if __name__ == '__main__':
    try:
        prepare(sys.argv[1], '/usr/share/distribution-gpg-keys', sys.argv[2],
                Path('COPR_OWNER').read_text().strip(), os.environ.get('COPR_KEY_SHA256', ''))
        materialize_local_keys(sys.argv[1])
    except (OSError, ValueError, IndexError, ET.ParseError) as error:
        print(str(error), file=sys.stderr)
        sys.exit(1)
