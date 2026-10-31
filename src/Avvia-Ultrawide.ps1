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
     if($hex.Contains('C744244C00050000C744245000040000')){break}
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
  if($i -lt 0 -or $hex.IndexOf($sig,$i+2) -ge 0){throw "Firma non univoca: $sig"}
  $edits+=@{Address=$base+$i/2+4;Data=[BitConverter]::GetBytes([int]3440)}
  $edits+=@{Address=$base+$i/2+12;Data=[BitConverter]::GetBytes([int]1440)}
 }
 foreach($spec in @(@('0F84AF0000003D00050000',7),@('3D00040000741E3D00050000',8))) {
  $i=$hex.IndexOf($spec[0])
  if($i -lt 0 -or $hex.IndexOf($spec[0],$i+2) -ge 0){throw "Firma non univoca: $($spec[0])"}
  $edits+=@{Address=$base+$i/2+$spec[1];Data=[BitConverter]::GetBytes([int]3440)}
 }
 # All seven code sites were verified before any code is changed.
 foreach($edit in $edits){
  $old=[uint32]0; $address=[IntPtr][long]$edit.Address; $written=[IntPtr]::Zero
  if(![P3PatchMemory]::VirtualProtectEx($handle,$address,([UIntPtr]::new([uint32]4)),0x40,[ref]$old)){throw 'Protezione memoria non modificabile.'}
  try {
   if(![P3PatchMemory]::WriteProcessMemory($handle,$address,$edit.Data,4,[ref]$written) -or $written.ToInt64() -ne 4){throw 'Scrittura memoria fallita. Chiudi il gioco.'}
  } finally { $ignored=[uint32]0; [P3PatchMemory]::VirtualProtectEx($handle,$address,([UIntPtr]::new([uint32]4)),$old,[ref]$ignored) | Out-Null }
  [P3PatchMemory]::FlushInstructionCache($handle,$address,([UIntPtr]::new([uint32]4))) | Out-Null
  $verify=New-Object byte[] 4; $read=[IntPtr]::Zero
  if(![P3PatchMemory]::ReadProcessMemory($handle,$address,$verify,4,[ref]$read) -or [BitConverter]::ToString($verify) -ne [BitConverter]::ToString($edit.Data)){throw 'Verifica memoria fallita. Chiudi il gioco.'}
 }
 "$(Get-Date -Format o): PID $($game.Id), 12 dimension constants verified, target 3440x1440." | Add-Content (Join-Path $PSScriptRoot 'runtime.log')
 Write-Host 'Patch 3440x1440 applicata. Nelle opzioni usa 1280x1024 (etichetta originale).'
} finally {if($handle -ne [IntPtr]::Zero){[P3PatchMemory]::CloseHandle($handle) | Out-Null}}
