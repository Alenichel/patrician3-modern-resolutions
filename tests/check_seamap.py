"""Check that the ultrawide map keeps geography and its palette unchanged.

python tests/check_seamap.py GAME_DIRECTORY GENERATED_DIRECTORY
Uses only Python's standard library; no game files are stored in this repository.
"""
import pathlib
import struct
import sys

game, generated = map(pathlib.Path, sys.argv[1:])
archive = (game / 'p2arch0_eng.cpr').read_bytes()
entry = archive.index(b'images\\Vollansichtskarte.bmp\0')
offset, size = struct.unpack_from('<II', archive, entry - 12)
original = archive[offset:offset + size]
padded = (generated / 'images' / 'Vollansichtskarte.bmp').read_bytes()

def info(data):
    assert data[:2] == b'BM'
    assert struct.unpack_from('<H', data, 28)[0] == 8
    assert struct.unpack_from('<I', data, 30)[0] == 0
    assert struct.unpack_from('<I', data, 2)[0] == len(data)
    pixel = struct.unpack_from('<I', data, 10)[0]
    width, height = struct.unpack_from('<ii', data, 18)
    return pixel, width, height, (width + 3) & ~3

op, ow, oh, os = info(original)
pp, pw, ph, ps = info(padded)
assert (ow, oh) == (2400, 1800)
assert (pw, ph) == (3440, 1800)
assert original[54:op] == padded[54:pp], 'Palette changed'
for row in range(oh):
    assert original[op + row * os:op + row * os + ow] == padded[pp + row * ps:pp + row * ps + ow], f'Geography moved on row {row}'
extension = {value for row in range(ph) for value in padded[pp + row * ps + ow:pp + row * ps + pw]}
assert len(extension) == 1, 'The extension should be neutral, not repeated geography'
textures = (generated / 'scripts' / 'textures.ini').read_text(encoding='latin1')
assert '[TEX16036]\nTextureFile=images/Vollansichtskarte.bmp\nUseAlpha=false\nCount=1\nOffsetNSize0=0 0 3440 1800' in textures
print('PASS: all 4,320,000 original map pixels and palette preserved; neutral extension; texture dimensions agree')
