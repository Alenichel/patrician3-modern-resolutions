"""Generate and validate all profiles from the user's own archive, in temp."""
import json
from pathlib import Path
import struct
import subprocess
import sys
import tempfile

root=Path(__file__).resolve().parents[1]
game=Path(sys.argv[1])
archive=(game/'p2arch0_eng.cpr').read_bytes()
profiles=json.loads((root/'src'/'ResolutionProfiles.json').read_text())['profiles']
def extracted(name):
    i=archive.index(name.encode('latin1')+b'\0')
    offset,size=struct.unpack_from('<II',archive,i-12)
    return archive[offset:offset+size]
def info(data):
    assert data[:2]==b'BM'
    p=struct.unpack_from('<I',data,10)[0]
    w,h=struct.unpack_from('<ii',data,18)
    assert struct.unpack_from('<H',data,28)[0]==8
    assert struct.unpack_from('<I',data,2)[0]==len(data)
    return p,w,h,(w+3)&~3
old_map=extracted('images\\Vollansichtskarte.bmp');mp,mw,mh,ms=info(old_map)
old_panel=extracted('images\\HauptscreenE1280.bmp');pp,pw,ph,ps=info(old_panel)
def row(data,p,stride,height,y):
    return data[p+(height-1-y)*stride:p+(height-1-y)*stride+pw]
with tempfile.TemporaryDirectory(prefix='Patrician3-Profiles-') as temp:
    work=Path(temp)
    assert work.resolve().is_relative_to(Path(tempfile.gettempdir()).resolve())
    for profile in profiles:
        w,h=profile['width'],profile['height'];out=work/f'{w}x{h}'
        subprocess.run(['powershell.exe','-NoProfile','-ExecutionPolicy','Bypass','-File',str(root/'src'/'Prepare-Assets.ps1'),'-GamePath',str(game),'-OutputPath',str(out),'-Width',str(w),'-Height',str(h)],check=True)
        sea=(out/'images'/'Vollansichtskarte.bmp').read_bytes();np,nw,nh,ns=info(sea)
        canvas=w if w-284>2400 else 2400
        assert (nw,nh)==(canvas,1800)
        assert sea[54:np]==old_map[54:mp]
        for y in range(mh):assert old_map[mp+y*ms:mp+y*ms+mw]==sea[np+y*ns:np+y*ns+mw]
        panel=(out/'images'/'HauptscreenE1280.bmp').read_bytes();np,nw,nh,ns=info(panel)
        assert (nw,nh)==(284,h-600)
        assert panel[54:np]==old_panel[54:pp]
        shift=(nh-ph)//2
        for y in range(28,ph-28):assert row(old_panel,pp,ps,ph,y)==row(panel,np,ns,nh,y+shift)
        for y in range(28):
            assert row(old_panel,pp,ps,ph,y)==row(panel,np,ns,nh,y)
            assert row(old_panel,pp,ps,ph,ph-28+y)==row(panel,np,ns,nh,nh-28+y)
        assert info((out/'images'/'HauptscreenA1280.bmp').read_bytes())[1:3]==(w-284,42)
        assert info((out/'images'/'Vollansichtskarte1280.bmp').read_bytes())[1:3]==(w,h)
        textures=(out/'scripts'/'textures.ini').read_text(encoding='latin1')
        screen=(out/'scripts'/'screenGame.ini').read_text(encoding='latin1')
        accel=(out/'scripts'/'accelMap.ini').read_text(encoding='latin1')
        assert f'OffsetNSize0=0 0 {canvas} 1800' in textures
        assert f'Frame0=11 0 0 0 0 {w-284} 42 0' in screen
        assert f'Pos={w-284} 600' in screen
        assert f'Size={w} {h}' in accel
        metadata=json.loads((out/'profile.json').read_text(encoding='utf-8-sig'))
        assert (metadata['Width'],metadata['Height'])==(w,h)
print('PASS: all five profiles preserve sea geography, palette, panel relief and caps; image/INI dimensions and profile metadata agree')
