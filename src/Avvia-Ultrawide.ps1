param([switch]$Attach)
$ErrorActionPreference='Stop'
if(!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
 $arguments='-NoProfile -ExecutionPolicy Bypass -File "'+$PSCommandPath+'"'
 if($Attach){$arguments+=' -Attach'}
 # Interactive status console: the user needs to see success and any error.
 $child=Start-Process powershell.exe -Verb RunAs -WindowStyle Normal -ArgumentList $arguments -Wait -PassThru
 exit $child.ExitCode
}
$root=Split-Path $PSScriptRoot -Parent
Set-Location $root
if(!$Attach -and (Get-Process Patrician3,Patrician -ErrorAction SilentlyContinue)){throw 'Chiudi prima Patrician III.'}
if(!$Attach -and (Get-Process P3Setup -ErrorAction SilentlyContinue)){throw 'Completa prima P3Setup con OK e chiudi il gioco.'}
Add-Type @'
using System;
using System.Runtime.InteropServices;
public static class P3PatchMemory {
 [DllImport("kernel32.dll",SetLastError=true)] public static extern IntPtr OpenProcess(uint access,bool inherit,int pid);
 [DllImport("kernel32.dll",SetLastError=true)] public static extern bool ReadProcessMemory(IntPtr p,IntPtr a,byte[] b,int size,out IntPtr read);
 [DllImport("kernel32.dll",SetLastError=true)] public static extern bool WriteProcessMemory(IntPtr p,IntPtr a,byte[] b,int size,out IntPtr written);
 [DllImport("kernel32.dll",SetLastError=true)] public static extern bool VirtualProtectEx(IntPtr p,IntPtr a,UIntPtr size,uint protection,out uint previous);
 [DllImport("kernel32.dll",SetLastError=true)] public static extern IntPtr VirtualAllocEx(IntPtr p,IntPtr a,UIntPtr size,uint allocation,uint protection);
 [DllImport("kernel32.dll")] public static extern bool FlushInstructionCache(IntPtr p,IntPtr a,UIntPtr size);
 [DllImport("kernel32.dll")] public static extern bool CloseHandle(IntPtr p);
}
'@
if(!$Attach){
$backup=Join-Path $PSScriptRoot 'backup-originali'
if(!(Test-Path $backup)){
 New-Item -ItemType Directory $backup | Out-Null
 foreach($item in @('P2.cfg','Save','scripts','images')) {
  if(Test-Path (Join-Path $root $item)){Copy-Item (Join-Path $root $item) $backup -Recurse}
 }
 Get-FileHash Patrician.exe,Patrician3.exe | Format-List | Out-File (Join-Path $backup 'hash-eseguibili.txt')
}
if(!(Test-Path (Join-Path $PSScriptRoot 'prepared\images\Vollansichtskarte1280.bmp'))){throw 'Risorse ultrawide mancanti.'}
foreach($folder in @('scripts','images')) {
 New-Item -ItemType Directory -Force (Join-Path $root $folder) | Out-Null
 Copy-Item (Join-Path $PSScriptRoot "prepared\$folder\*") (Join-Path $root $folder) -Force
}
$cfg=Join-Path $root 'P2.cfg'
$text=[IO.File]::ReadAllText($cfg)
if($text -notmatch '(?m)^AUFLOESUNG=\d+'){throw 'Impostazione risoluzione non trovata.'}
[IO.File]::WriteAllText($cfg,($text -replace '(?m)^AUFLOESUNG=\d+','AUFLOESUNG=2'),[Text.Encoding]::ASCII)
Start-Process -FilePath 'C:\Program Files (x86)\Steam\steam.exe' -ArgumentList '-applaunch 33570'
}
Write-Host 'Attendo avvio normale da Steam. Lascia il gioco al menu principale.'
$deadline=(Get-Date).AddSeconds(90)
$handle=[IntPtr]::Zero
try {
 do {
  $game=Get-Process Patrician3,Patrician -ErrorAction SilentlyContinue | Select-Object -First 1
  if($game){
   $handle=[P3PatchMemory]::OpenProcess(0x438,$false,$game.Id)
   if($handle -eq [IntPtr]::Zero){throw "Accesso al processo negato (errore $([Runtime.InteropServices.Marshal]::GetLastWin32Error())). Il gioco potrebbe essere avviato come amministratore."}
   if($handle -ne [IntPtr]::Zero){
    $base=$game.MainModule.BaseAddress.ToInt64()
    $buffer=New-Object byte[] 0x26a000; $count=[IntPtr]::Zero
    if([P3PatchMemory]::ReadProcessMemory($handle,[IntPtr]$base,$buffer,$buffer.Length,[ref]$count)){
     $hex=[BitConverter]::ToString($buffer).Replace('-','')
     if($hex.Contains('C744244C00050000C744245000040000') -or $hex.Contains('C744244C700D0000C7442450A0050000')){break}
    }
    [P3PatchMemory]::CloseHandle($handle) | Out-Null; $handle=[IntPtr]::Zero
   }
  }
  Start-Sleep -Milliseconds 500
 } while((Get-Date) -lt $deadline)
 if($handle -eq [IntPtr]::Zero){throw 'Avvio non riuscito o versione incompatibile. Nessuna modifica al codice applicata.'}
 $edits=@()
 foreach($pair in @(@('4C','50'),@('18','1C'),@('3C','40'),@('48','4C'),@('24','28'))) {
  $sig='C74424'+$pair[0]+'00050000C74424'+$pair[1]+'00040000'
  $i=$hex.IndexOf($sig)
  if($i -lt 0){$sig='C74424'+$pair[0]+'700D0000C74424'+$pair[1]+'A0050000';$i=$hex.IndexOf($sig)}
  if($i -lt 0 -or $hex.IndexOf($sig,$i+2) -ge 0){throw "Firma non univoca: $sig"}
  $edits+=@{Address=$base+$i/2+4;Data=[BitConverter]::GetBytes([int]3440)}
  $edits+=@{Address=$base+$i/2+12;Data=[BitConverter]::GetBytes([int]1440)}
 }
 foreach($spec in @(@('0F84AF0000003D00050000',7),@('3D00040000741E3D00050000',8))) {
  $i=$hex.IndexOf($spec[0])
  if($i -lt 0){$spec[0]=$spec[0].Replace('00050000','700D0000');$i=$hex.IndexOf($spec[0])}
  if($i -lt 0 -or $hex.IndexOf($spec[0],$i+2) -ge 0){throw "Firma non univoca: $($spec[0])"}
  $edits+=@{Address=$base+$i/2+$spec[1];Data=[BitConverter]::GetBytes([int]3440)}
 }
 # The sea view is wider than the original 2400-pixel geography. Keep the
 # horizontal camera at -(3156-2400)/2 rather than moving the bitmap alone.
 # Drawn towns, ships and mouse coordinates all use this same camera offset.
 $cameraSignature='6683BEE4290000007D0966C786E42900000000'
 $cameraIndex=$hex.IndexOf($cameraSignature)
 if($cameraIndex -lt 0 -or $hex.IndexOf($cameraSignature,$cameraIndex+2) -ge 0){throw 'Firma del limite della camera mare non univoca.'}
 $cameraAddress=[long]($base+$cameraIndex/2)
 $continuation=$cameraAddress+19
 $stubAddress=[P3PatchMemory]::VirtualAllocEx($handle,[IntPtr]::Zero,([UIntPtr]::new([uint32]4096)),0x3000,0x40).ToInt64()
 if($stubAddress -le 0 -or $stubAddress -gt [uint32]::MaxValue){throw 'Allocazione del correttore camera fallita.'}
 $stub=New-Object 'System.Collections.Generic.List[byte]'
 # cmp dword [esi+2c],3156; jne original; mov word [esi+29e4],-378
 $stub.AddRange([byte[]]@(0x81,0x7e,0x2c,0x54,0x0c,0,0,0x75,0x0e,0x66,0xc7,0x86,0xe4,0x29,0,0,0x86,0xfe))
 $stub.Add(0xe9); $stub.AddRange([BitConverter]::GetBytes([int]($continuation-($stubAddress+23))))
 for($i=0;$i -lt $cameraSignature.Length;$i+=2){$stub.Add([Convert]::ToByte($cameraSignature.Substring($i,2),16))}
 $stub.Add(0xe9); $stub.AddRange([BitConverter]::GetBytes([int]($continuation-($stubAddress+47))))
 $hook=New-Object 'System.Collections.Generic.List[byte]'
 $hook.Add(0xe9); $hook.AddRange([BitConverter]::GetBytes([int]($stubAddress-($cameraAddress+5))))
 while($hook.Count -lt 19){$hook.Add(0x90)}
 $edits+=@{Address=$stubAddress;Data=$stub.ToArray()}
 $edits+=@{Address=$cameraAddress;Data=$hook.ToArray()}
 # Scrolling has a second, independent clamp, which otherwise resets X to 0.
 $scrollSignature='668B86E4290000663BC37D238B5424400FBFC0F7DA3BC2750BC644241300895C2440EB040144244066899EE4290000'
 $scrollIndex=$hex.IndexOf($scrollSignature)
 if($scrollIndex -lt 0 -or $hex.IndexOf($scrollSignature,$scrollIndex+2) -ge 0){throw 'Firma del limite di scorrimento mare non univoca.'}
 $scrollAddress=[long]($base+$scrollIndex/2)
 $scrollContinuation=$scrollAddress+47
 $scrollStubAddress=$stubAddress+256
 $scrollStub=New-Object 'System.Collections.Generic.List[byte]'
 # cmp width,3156; jne original; cameraX=-378; clear horizontal deltas.
 $scrollStub.AddRange([byte[]]@(0x81,0x7e,0x2c,0x54,0x0c,0,0,0x75,0x1e,0x66,0xc7,0x86,0xe4,0x29,0,0,0x86,0xfe,0xc7,0x44,0x24,0x3c,0,0,0,0,0xc7,0x44,0x24,0x40,0,0,0,0))
 $scrollStub.Add(0xe9);$scrollStub.AddRange([BitConverter]::GetBytes([int]($scrollContinuation-($scrollStubAddress+39))))
 for($i=0;$i -lt $scrollSignature.Length;$i+=2){$scrollStub.Add([Convert]::ToByte($scrollSignature.Substring($i,2),16))}
 $scrollStub.Add(0xe9);$scrollStub.AddRange([BitConverter]::GetBytes([int]($scrollContinuation-($scrollStubAddress+91))))
 $scrollHook=New-Object 'System.Collections.Generic.List[byte]'
 $scrollHook.Add(0xe9);$scrollHook.AddRange([BitConverter]::GetBytes([int]($scrollStubAddress-($scrollAddress+5))))
 while($scrollHook.Count -lt 47){$scrollHook.Add(0x90)}
 $edits+=@{Address=$scrollStubAddress;Data=$scrollStub.ToArray()}
 $edits+=@{Address=$scrollAddress;Data=$scrollHook.ToArray()}
 # All nine original code sites were verified before any code is changed.
 foreach($edit in $edits){
  $length=$edit.Data.Length
  $nativeLength=[UIntPtr]::new([uint32]$length)
  $old=[uint32]0; $address=[IntPtr][long]$edit.Address; $written=[IntPtr]::Zero
  if(![P3PatchMemory]::VirtualProtectEx($handle,$address,$nativeLength,0x40,[ref]$old)){throw 'Protezione memoria non modificabile.'}
  try {
   if(![P3PatchMemory]::WriteProcessMemory($handle,$address,$edit.Data,$length,[ref]$written) -or $written.ToInt64() -ne $length){throw 'Scrittura memoria fallita. Chiudi il gioco.'}
  } finally { $ignored=[uint32]0; [P3PatchMemory]::VirtualProtectEx($handle,$address,$nativeLength,$old,[ref]$ignored) | Out-Null }
  [P3PatchMemory]::FlushInstructionCache($handle,$address,$nativeLength) | Out-Null
  $verify=New-Object byte[] $length; $read=[IntPtr]::Zero
  if(![P3PatchMemory]::ReadProcessMemory($handle,$address,$verify,$length,[ref]$read) -or [BitConverter]::ToString($verify) -ne [BitConverter]::ToString($edit.Data)){throw 'Verifica memoria fallita. Chiudi il gioco.'}
 }
 "$(Get-Date -Format o): PID $($game.Id), 12 dimension constants and BOTH centered sea camera clamps verified, target 3440x1440; camera=-378 for viewport3156, original behavior for other widths." | Add-Content (Join-Path $PSScriptRoot 'runtime.log')
 Write-Host 'Patch 3440x1440 applicata. Nelle opzioni usa 1280x1024 (etichetta originale).'
} finally {if($handle -ne [IntPtr]::Zero){[P3PatchMemory]::CloseHandle($handle) | Out-Null}}
