param([Parameter(Mandatory=$true)][string]$GamePath)
$ErrorActionPreference='Stop'
if(!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
 $arguments='-NoProfile -ExecutionPolicy Bypass -File "'+$PSCommandPath+'" -GamePath "'+$GamePath+'"'
 $child=Start-Process powershell.exe -Verb RunAs -WindowStyle Normal -ArgumentList $arguments -Wait -PassThru
 exit $child.ExitCode
}
& (Join-Path $PSScriptRoot 'Install.ps1') -GamePath $GamePath
& powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $GamePath 'mods-ultrawide\Avvia-Ultrawide.ps1')
if($LASTEXITCODE -ne 0){throw 'Avvio della patch fallito. Leggi il messaggio nella console.'}
