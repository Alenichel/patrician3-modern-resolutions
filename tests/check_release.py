"""Verify the distributable's allowlist and its published checksum."""
import hashlib
from pathlib import Path
import sys
import zipfile
dist=Path(sys.argv[1])
archive=dist/'Patrician3-Ultrawide-1.0.0.zip'
expected={'Patrician3Ultrawide.exe','DISTRIBUZIONE.txt','README.md','LICENSE','CHANGELOG.md'}
with zipfile.ZipFile(archive) as bundle:
    assert set(bundle.namelist())==expected, bundle.namelist()
    assert bundle.testzip() is None
    assert bundle.read('Patrician3Ultrawide.exe')[:2]==b'MZ'
    assert b'C:\\Users\\aleni' not in bundle.read('Patrician3Ultrawide.exe')
    for name in expected-{'Patrician3Ultrawide.exe'}:
        text=bundle.read(name)
        assert b'C:\\Users\\' not in text and b'C:/Users/' not in text
checksum=hashlib.sha256(archive.read_bytes()).hexdigest()
assert (dist/'SHA256SUMS.txt').read_text().split()[0]==checksum
print('PASS: ZIP allowlist, CRC, executable header, no personal paths, SHA256 checksum')
