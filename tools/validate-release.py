#!/usr/bin/env python3
"""Require a maintainer-supplied test record for this exact source and architecture.
This validates the record's completeness, not the truth of human test evidence.
"""
import json
import os
import re
import sys

REQUIRED = ('rpm-qml', 'small-screen-accessibility', 'lock-suspend', 'display-hotplug',
            'network-bluetooth', 'portal-sharing', 'install-boot', 'update-recovery')


def validate(record, source, arch, fedora):
    if not re.fullmatch(r'[0-9a-f]{40}', source) or arch not in ('x86_64', 'aarch64'):
        raise ValueError('Geçersiz kaynak veya mimari.')
    if not isinstance(record, dict) or record.get('format') != 1 or record.get('sourceCommit') != source or str(record.get('fedora')) != str(fedora):
        raise ValueError('Bu kaynak ve Fedora sürümü için doğrulama kaydı yok.')
    architectures = record.get('architectures')
    checks = architectures.get(arch) if isinstance(architectures, dict) else None
    if not isinstance(checks, dict): raise ValueError('Mimari doğrulaması eksik.')
    for name in REQUIRED:
        check = checks.get(name)
        if not isinstance(check, dict) or check.get('status') != 'passed' or not isinstance(check.get('evidence'), str) or not check['evidence'].startswith('https://') or len(check['evidence']) > 2048:
            raise ValueError('Doğrulama veya test kanıtı eksik: ' + name)
    return True


if __name__ == '__main__':
    try:
        if len(sys.argv) != 4: raise ValueError('Kaynak, mimari ve Fedora sürümü gerekli.')
        text = os.environ.get('VABU_VALIDATION_RECORD', '')
        if not text or len(text) > 65536: raise ValueError('Doğrulama kaydı yapılandırılmamış.')
        validate(json.loads(text), *sys.argv[1:])
    except (ValueError, TypeError) as error:
        print(str(error), file=sys.stderr); sys.exit(1)
