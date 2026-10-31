param([Parameter(Mandatory=$true)][string]$GamePath)
$ErrorActionPreference='Stop'
$GamePath=(Resolve-Path -LiteralPath $GamePath).Path
. (Join-Path $PSScriptRoot 'src\Mod.Common.ps1')
Assert-CompatibleGame $GamePath
if(Get-Process Patrician3,Patrician -ErrorAction SilentlyContinue){throw 'Close the game before installing or updating the mod.'}
$destination=Join-Path $GamePath 'mods-ultrawide'
New-Item -ItemType Directory -Force $destination | Out-Null
Copy-Item (Join-Path $PSScriptRoot 'src\*.ps1') $destination -Force
Copy-Item (Join-Path $PSScriptRoot 'src\Launch Patrician Modern Resolutions.cmd') $GamePath -Force
& powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $destination 'Prepare-Assets.ps1')
if($LASTEXITCODE -ne 0){throw 'Asset generation failed.'}
Activate-ModFiles $GamePath
Write-Host "Installation ready. Launch: $GamePath\Launch Patrician Modern Resolutions.cmd"
