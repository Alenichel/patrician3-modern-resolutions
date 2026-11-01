"""Reproduce the crash rectangle and execute the production clipping hook.

Requires Unicorn. Uses a synthetic cdecl renderer, not proprietary game code.
"""
import base64
import json
from pathlib import Path
import struct
import subprocess
import tempfile
from unicorn import Uc, UC_ARCH_X86, UC_MODE_32, UC_HOOK_CODE
from unicorn.x86_const import *

root=Path(__file__).resolve().parents[1]
with tempfile.TemporaryDirectory() as directory:
    script=Path(directory)/'emit.ps1'
    script.write_text(r'''
. $args[0]
$hook=New-SafeSeaBlitHook -StubAddress 0x20000200 -OriginalAddress 0x004bb330 -CallAddress 0x0044ace0
@{stub=[Convert]::ToBase64String($hook.Stub);hook=[Convert]::ToBase64String($hook.Hook)}|ConvertTo-Json -Compress
''',encoding='utf-8')
    encoded=json.loads(subprocess.check_output(['powershell.exe','-NoProfile','-ExecutionPolicy','Bypass','-File',str(script),str(root/'src'/'Safe-SeaBlit.ps1')],text=True))
stub,hook=(base64.b64decode(encoded[key]) for key in ('stub','hook'))

def inside_source(rect):
    sx,sy,dx,dy,w,h=rect
    return sx>=0 and sy>=0 and w>0 and h>0 and sx+w<=3440 and sy+h<=1800

crash=(-378,0,0,42,3156,1398)
assert not inside_source(crash), 'The captured crash rectangle must reproduce an invalid source read'
cases=[crash,(-378,402,0,42,3156,1398),(-378,120,11,42,3156,1398),
       (0,0,0,42,3156,1398),(1000,200,0,42,996,600),(0,0,0,42,740,600),
       (0,0,0,42,1636,1038),(764,762,0,42,1636,1038),
       (764,642,0,42,1636,1158),(124,762,0,42,2276,1038),(124,402,0,42,2276,1398)]
for original in cases:
    uc=Uc(UC_ARCH_X86,UC_MODE_32)
    for address,size in ((0x44a000,4096),(0x4bb000,4096),(0x20000000,4096),(0x40000000,4096)):
        uc.mem_map(address,size)
    uc.mem_write(0x44ace0,hook)
    uc.mem_write(0x20000200,stub)
    uc.mem_write(0x4bb330,b'\xc3')
    uc.mem_write(0x40000800,struct.pack('<6i',*original))
    uc.reg_write(UC_X86_REG_ESP,0x40000800)
    preserved={UC_X86_REG_ESI:0x12345678,UC_X86_REG_EDI:0x76543210,UC_X86_REG_EBX:0x11112222,UC_X86_REG_EBP:0x33334444}
    for reg,value in preserved.items():uc.reg_write(reg,value)
    calls=[]
    def renderer(machine,address,size,user):
        if address==0x4bb330:
            esp=machine.reg_read(UC_X86_REG_ESP)
            rect=struct.unpack('<6i',machine.mem_read(esp+4,24))
            assert inside_source(rect), ('Out-of-bounds source rectangle',rect)
            calls.append(rect)
            for reg in (UC_X86_REG_EAX,UC_X86_REG_ECX,UC_X86_REG_EDX):machine.reg_write(reg,0x55aa55aa)
    uc.hook_add(UC_HOOK_CODE,renderer)
    uc.emu_start(0x44ace0,0x44ace5,count=100)
    assert uc.reg_read(UC_X86_REG_ESP)==0x40000800
    for reg,value in preserved.items():assert uc.reg_read(reg)==value
    sx,sy,dx,dy,w,h=original
    if sx==-378 and w==3156:
        assert calls==[(3062,sy,dx,dy,378,h),(0,sy,dx+378,dy,w-378,h)],calls
        assert calls[0][2]+calls[0][4]==calls[1][2]
        assert calls[1][2]+calls[1][4]==dx+w
    else:
        assert calls==[original]
print('PASS: captured crash rectangle clipped; 11 boundary/passthrough cases including all narrow-profile map edges; map placement, coverage, cdecl stack and saved registers preserved')
