param([Parameter(Mandatory=$true)][string]$GamePath)
$ErrorActionPreference='Stop'
$GamePath=(Resolve-Path -LiteralPath $GamePath).Path
. (Join-Path $PSScriptRoot 'src\Mod.Common.ps1')
Assert-CompatibleGame $GamePath
if(Get-Process Patrician3,Patrician -ErrorAction SilentlyContinue){throw 'Chiudi il gioco prima di installare o aggiornare.'}
$destination=Join-Path $GamePath 'mods-ultrawide'
New-Item -ItemType Directory -Force $destination | Out-Null
Copy-Item (Join-Path $PSScriptRoot 'src\*.ps1') $destination -Force
Copy-Item (Join-Path $PSScriptRoot 'src\Avvia Patrician Ultrawide.cmd') $GamePath -Force
& powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $destination 'Prepare-Assets.ps1')
if($LASTEXITCODE -ne 0){throw 'Generazione risorse fallita.'}
Activate-ModFiles $GamePath
Write-Host "Installazione pronta. Avvia: $GamePath\Avvia Patrician Ultrawide.cmd"
