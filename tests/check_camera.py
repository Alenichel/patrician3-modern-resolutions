"""Execute the production x86 camera hook in Unicorn (pip install unicorn).

No game process or proprietary code dump is required.
"""
import base64
import json
from pathlib import Path
import subprocess
import tempfile
from unicorn import Uc, UC_ARCH_X86, UC_MODE_32
from unicorn.x86_const import UC_X86_REG_ESI, UC_X86_REG_ESP

root = Path(__file__).resolve().parents[1]
# Evaluate the actual production byte emitter with deterministic addresses.
ps = r'''
$s=[IO.File]::ReadAllText($args[0])
$start=$s.IndexOf('$stub=New-Object')
$end=$s.IndexOf('$edits+=@{Address=$stubAddress')
if($start -lt 0 -or $end -le $start){throw 'Production emitter missing'}
$cameraAddress=[long]0x44f529
$continuation=$cameraAddress+19
$stubAddress=[long]0x20000000
$cameraSignature='6683BEE4290000007D0966C786E42900000000'
& ([scriptblock]::Create($s.Substring($start,$end-$start)))
$start=$s.IndexOf('$scrollStub=New-Object')
$end=$s.IndexOf('$edits+=@{Address=$scrollStubAddress')
$scrollAddress=[long]0x44e682
$scrollContinuation=$scrollAddress+47
$scrollStubAddress=$stubAddress+256
$scrollSignature='668B86E4290000663BC37D238B5424400FBFC0F7DA3BC2750BC644241300895C2440EB040144244066899EE4290000'
& ([scriptblock]::Create($s.Substring($start,$end-$start)))
@{stub=[Convert]::ToBase64String($stub.ToArray());hook=[Convert]::ToBase64String($hook.ToArray());scrollStub=[Convert]::ToBase64String($scrollStub.ToArray());scrollHook=[Convert]::ToBase64String($scrollHook.ToArray())}|ConvertTo-Json -Compress
'''
# Dot-source the emitter so its variables remain available to the serializer.
ps = ps.replace('& ([scriptblock]', '. ([scriptblock]')
with tempfile.TemporaryDirectory() as folder:
    script = Path(folder) / 'emit.ps1'
    script.write_text(ps, encoding='utf-8')
    emitted = json.loads(subprocess.check_output([
        'powershell.exe', '-NoProfile', '-ExecutionPolicy', 'Bypass',
        '-File', str(script), str(root / 'src' / 'Apply-ResolutionPatch.ps1')
    ], text=True))
stub, hook = (base64.b64decode(emitted[k]) for k in ('stub', 'hook'))
assert len(stub) == 47 and len(hook) == 19
for width in (3156, 1636, 2276, 516, 740, 996):
    for offset in (-1000, -378, -1, 0, 500):
        uc = Uc(UC_ARCH_X86, UC_MODE_32)
        uc.mem_map(0x44f000, 4096)
        uc.mem_map(0x20000000, 4096)
        uc.mem_map(0x30000000, 0x4000)
        uc.mem_write(0x44f529, hook)
        uc.mem_write(0x20000000, stub)
        uc.mem_write(0x3000002c, width.to_bytes(4, 'little'))
        uc.mem_write(0x300029e4, offset.to_bytes(2, 'little', signed=True))
        uc.mem_write(0x300029e6, b'\x34\x12')
        uc.reg_write(UC_X86_REG_ESI, 0x30000000)
        uc.emu_start(0x44f529, 0x44f53c, count=30)
        result = int.from_bytes(uc.mem_read(0x300029e4, 2), 'little', signed=True)
        assert result == (-378 if width == 3156 else max(offset, 0)), (width, offset, result)
        assert bytes(uc.mem_read(0x300029e6, 2)) == b'\x34\x12'
        assert uc.reg_read(UC_X86_REG_ESI) == 0x30000000
scroll_stub, scroll_hook = (base64.b64decode(emitted[k]) for k in ('scrollStub', 'scrollHook'))
assert len(scroll_stub) == 91 and len(scroll_hook) == 47
for width in (3156, 1636, 2276, 516, 740, 996):
    for offset in (-1000, -378, -1, 0, 500):
        uc = Uc(UC_ARCH_X86, UC_MODE_32)
        uc.mem_map(0x44e000, 4096)
        uc.mem_map(0x20000000, 4096)
        uc.mem_map(0x30000000, 0x4000)
        uc.mem_map(0x40000000, 4096)
        uc.mem_write(0x44e682, scroll_hook)
        uc.mem_write(0x20000100, scroll_stub)
        uc.mem_write(0x3000002c, width.to_bytes(4, 'little'))
        uc.mem_write(0x300029e4, offset.to_bytes(2, 'little', signed=True))
        uc.mem_write(0x300029e6, b'\x34\x12')
        uc.mem_write(0x4000013c, (15).to_bytes(4, 'little'))
        uc.mem_write(0x40000140, (30).to_bytes(4, 'little'))
        uc.reg_write(UC_X86_REG_ESI, 0x30000000)
        uc.reg_write(UC_X86_REG_ESP, 0x40000100)
        uc.emu_start(0x44e682, 0x44e6b1, count=30)
        result = int.from_bytes(uc.mem_read(0x300029e4, 2), 'little', signed=True)
        assert result == (-378 if width == 3156 else max(offset, 0)), (width, offset, result)
        if width == 3156:
            assert bytes(uc.mem_read(0x4000013c, 8)) == bytes(8)
        assert bytes(uc.mem_read(0x300029e6, 2)) == b'\x34\x12'
print('PASS: BOTH production hooks executed for 60 cases; centered ultrawide; narrow-profile fallback; vertical camera untouched')
