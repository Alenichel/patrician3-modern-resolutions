param([Parameter(Mandatory=$true)][string]$GamePath)
$ErrorActionPreference='Stop'
$GamePath=(Resolve-Path -LiteralPath $GamePath).Path
if(Get-Process Patrician3,Patrician -ErrorAction SilentlyContinue){throw 'Close the game before restoring the original files.'}
. (Join-Path $PSScriptRoot 'src\Mod.Common.ps1')
Restore-ModFiles $GamePath
