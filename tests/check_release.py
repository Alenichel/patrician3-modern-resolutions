"""Verify the distributable's allowlist and its published checksum."""
import hashlib
from pathlib import Path
import sys
import zipfile
import posixpath
import re
dist=Path(sys.argv[1])
archive=dist/'Patrician3-Modern-Resolutions-1.1.0.zip'
expected={'Patrician3ModernResolutions.exe','QUICKSTART.txt','README.md','LICENSE','CHANGELOG.md','RELEASE-CHECKS.md','assets/readme-cover.png','assets/GENERATION.md','docs/DEVELOPMENT.md','docs/CRASH-2026-10-31.md'}
with zipfile.ZipFile(archive) as bundle:
    assert {p.filename.replace('\\','/') for p in bundle.infolist() if not p.is_dir()}==expected, bundle.namelist()
    assert bundle.testzip() is None
    assert bundle.read('Patrician3ModernResolutions.exe')[:2]==b'MZ'
    assert b'C:\\Users\\aleni' not in bundle.read('Patrician3ModernResolutions.exe')
    for name in ('README.md','docs/DEVELOPMENT.md'):
        text=bundle.read(name).decode('utf-8-sig')
        for link in re.findall(r'!?\[[^\]]*\]\(([^)]+)\)',text):
            if '://' not in link and not link.startswith('#'):
                target=posixpath.normpath(posixpath.join(posixpath.dirname(name),link.split('#')[0]))
                assert target in expected, (name,link)
    assert '# Patrician III Modern Resolutions' in bundle.read('README.md').decode('utf-8-sig')
    for name in expected-{'Patrician3ModernResolutions.exe'}:
        text=bundle.read(name)
        assert b'C:\\Users\\' not in text and b'C:/Users/' not in text
checksum=hashlib.sha256(archive.read_bytes()).hexdigest()
assert (dist/'SHA256SUMS.txt').read_text().split()[0]==checksum
print('PASS: ZIP allowlist, CRC, executable header, no personal paths, SHA256 checksum')
