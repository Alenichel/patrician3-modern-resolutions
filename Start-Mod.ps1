param([Parameter(Mandatory=$true)][string]$GamePath,[int]$Width=0,[int]$Height=0)
$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot 'src\ResolutionProfiles.ps1')
$profile=Get-ResolutionProfile -Width $Width -Height $Height
if(!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
 $arguments='-NoProfile -ExecutionPolicy Bypass -File "'+$PSCommandPath+'" -GamePath "'+$GamePath+'" -Width '+$profile.Width+' -Height '+$profile.Height
 $child=Start-Process powershell.exe -Verb RunAs -WindowStyle Normal -ArgumentList $arguments -Wait -PassThru
 exit $child.ExitCode
}
& (Join-Path $PSScriptRoot 'Install.ps1') -GamePath $GamePath -Width $profile.Width -Height $profile.Height
& powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $GamePath 'mods-ultrawide\Apply-ResolutionPatch.ps1') -Width $profile.Width -Height $profile.Height
if($LASTEXITCODE -ne 0){throw 'The patch could not start. Read the console message for details.'}
