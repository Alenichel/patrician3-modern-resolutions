param([string]$GamePath='C:\Program Files (x86)\Steam\steamapps\common\Patrician III')
$ErrorActionPreference='Stop'
& (Join-Path $PSScriptRoot 'Install.ps1') -GamePath $GamePath
& powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $GamePath 'mods-ultrawide\Avvia-Ultrawide.ps1')
if($LASTEXITCODE -ne 0){throw 'Avvio della patch fallito. Leggi il messaggio nella console.'}
