param([Parameter(Mandatory=$true)][string]$GamePath,[int]$Width=0,[int]$Height=0)
$ErrorActionPreference='Stop'
$GamePath=(Resolve-Path -LiteralPath $GamePath).Path
. (Join-Path $PSScriptRoot 'src\Mod.Common.ps1')
. (Join-Path $PSScriptRoot 'src\ResolutionProfiles.ps1')
$profile=Get-ResolutionProfile -Width $Width -Height $Height
Assert-CompatibleGame $GamePath
if(Get-Process Patrician3,Patrician -ErrorAction SilentlyContinue){throw 'Close the game before installing or updating the mod.'}
$destination=Join-Path $GamePath 'mods-ultrawide'
New-Item -ItemType Directory -Force $destination | Out-Null
Copy-Item (Join-Path $PSScriptRoot 'src\*.ps1') $destination -Force
Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'src\ResolutionProfiles.json') -Destination $destination -Force
Copy-Item (Join-Path $PSScriptRoot 'src\Launch Patrician Modern Resolutions.cmd') $GamePath -Force
& powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $destination 'Prepare-Assets.ps1') -Width $profile.Width -Height $profile.Height
if($LASTEXITCODE -ne 0){throw 'Asset generation failed.'}
Assert-PreparedProfile -GamePath $GamePath -Profile $profile
Activate-ModFiles $GamePath
Write-Host "Installation ready. Launch: $GamePath\Launch Patrician Modern Resolutions.cmd"
