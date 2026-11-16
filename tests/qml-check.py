#!/usr/bin/env python3
"""Fail closed on missing compilation completion or QML runtime errors."""
import re
import sys
from pathlib import Path

ERRORS = re.compile(r'Failed to load|is not a type|non-existent property|Cannot assign to|is not installed|'
                    r'Type \w+ unavailable|Unexpected token|Syntax error|ReferenceError|TypeError|'
                    r'Unable to assign|Binding loop|DERLEME-HATASI|UI-AUDIT-FAIL', re.I)


def check(folder):
    folder = Path(folder)
    failures = []
    for name in ('derle', 'shell', 'settings', 'greeter', 'shell-niri', 'shell-kilit'):
        path = folder / (name + '.log')
        if not path.is_file() or not path.stat().st_size:
            failures.append(name + ': required log missing')
            continue
        content = path.read_text(errors='replace')
        if ERRORS.search(content): failures.append(name + ': QML error')
        if name == 'derle' and not re.search(r'DERLEME-BITTI [1-9][0-9]* dosya, 0 hatalı', content):
            failures.append('derle: successful completion missing')
    if (folder / 'test-failed').exists(): failures.append('integration action failed')
    return failures


if __name__ == '__main__':
    failures = check(sys.argv[1])
    for failure in failures: print(failure, file=sys.stderr)
    sys.exit(bool(failures))
