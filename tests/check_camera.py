"""Execute the production x86 camera hook in Unicorn (pip install unicorn).

No game process or proprietary code dump is required.
"""
import base64
import json
from pathlib import Path
import subprocess
import tempfile
from unicorn import Uc, UC_ARCH_X86, UC_MODE_32
from unicorn.x86_const import UC_X86_REG_ESI

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
@{stub=[Convert]::ToBase64String($stub.ToArray());hook=[Convert]::ToBase64String($hook.ToArray())}|ConvertTo-Json -Compress
'''
# Dot-source the emitter so its variables remain available to the serializer.
ps = ps.replace('& ([scriptblock]', '. ([scriptblock]')
with tempfile.TemporaryDirectory() as folder:
    script = Path(folder) / 'emit.ps1'
    script.write_text(ps, encoding='utf-8')
    emitted = json.loads(subprocess.check_output([
        'powershell.exe', '-NoProfile', '-ExecutionPolicy', 'Bypass',
        '-File', str(script), str(root / 'src' / 'Avvia-Ultrawide.ps1')
    ], text=True))
stub, hook = (base64.b64decode(emitted[k]) for k in ('stub', 'hook'))
assert len(stub) == 47 and len(hook) == 19
for width in (3156, 516, 740, 996):
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
print('PASS: production hook executed for 20 cases; centered ultrawide; vanilla fallback; vertical camera untouched')
