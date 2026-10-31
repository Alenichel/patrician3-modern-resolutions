"""Verify that extending the side panel preserves the relief at native scale."""
import pathlib
import struct
import sys
game, generated = map(pathlib.Path, sys.argv[1:])
archive=(game/'p2arch0_eng.cpr').read_bytes()
entry=archive.index(b'images\\HauptscreenE1280.bmp\0')
offset,size=struct.unpack_from('<II',archive,entry-12)
old=archive[offset:offset+size]
new=(generated/'images'/'HauptscreenE1280.bmp').read_bytes()
op=struct.unpack_from('<I',old,10)[0]
np=struct.unpack_from('<I',new,10)[0]
assert struct.unpack_from('<ii',old,18)==(284,424)
assert struct.unpack_from('<ii',new,18)==(284,840)
assert old[54:op]==new[54:np]
def row(data,p,height,y):
    start=p+(height-1-y)*284
    return data[start:start+284]
for y in range(28):
    assert row(old,op,424,y)==row(new,np,840,y)
    assert row(old,op,424,396+y)==row(new,np,840,812+y)
for y in range(28,396):
    assert row(old,op,424,y)==row(new,np,840,y+208), f'Relief distorted on row {y}'
print('PASS: original relief at 1:1, both end caps and palette preserved; panel 284x840')
