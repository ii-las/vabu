#!/usr/bin/env python3
"""Build-container-only key preparation. COPR key must match an out-of-band pin."""
import hashlib
import os
from pathlib import Path
import re
import shutil
import sys
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


if __name__ == '__main__':
    try:
        prepare(sys.argv[1], '/usr/share/distribution-gpg-keys', sys.argv[2],
                Path('COPR_OWNER').read_text().strip(), os.environ.get('COPR_KEY_SHA256', ''))
    except (OSError, ValueError, IndexError) as error:
        print(str(error), file=sys.stderr)
        sys.exit(1)
