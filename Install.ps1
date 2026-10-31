param([string]$GamePath='C:\Program Files (x86)\Steam\steamapps\common\Patrician III')
$ErrorActionPreference='Stop'
$GamePath=(Resolve-Path -LiteralPath $GamePath).Path
if(!(Test-Path (Join-Path $GamePath 'p2arch0_eng.cpr'))){throw 'Archivio della versione inglese non trovato.'}
if(Get-Process Patrician3,Patrician -ErrorAction SilentlyContinue){throw 'Chiudi il gioco prima di installare o aggiornare.'}
$destination=Join-Path $GamePath 'mods-ultrawide'
New-Item -ItemType Directory -Force $destination | Out-Null
Copy-Item (Join-Path $PSScriptRoot 'src\*.ps1') $destination -Force
Copy-Item (Join-Path $PSScriptRoot 'src\Avvia Patrician Ultrawide.cmd') $GamePath -Force
& powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $destination 'Prepare-Assets.ps1')
if($LASTEXITCODE -ne 0){throw 'Generazione risorse fallita.'}
Write-Host "Installazione pronta. Avvia: $GamePath\Avvia Patrician Ultrawide.cmd"
