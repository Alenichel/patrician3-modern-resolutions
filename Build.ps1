$ErrorActionPreference='Stop'
$compiler=Join-Path $env:WINDIR 'Microsoft.NET\Framework64\v4.0.30319\csc.exe'
if(!(Test-Path $compiler)){$compiler=Join-Path $env:WINDIR 'Microsoft.NET\Framework\v4.0.30319\csc.exe'}
if(!(Test-Path $compiler)){throw '.NET Framework 4 compiler not found.'}
$dist=Join-Path $PSScriptRoot 'dist'
New-Item -ItemType Directory -Force $dist | Out-Null
$exe=Join-Path $dist 'Patrician3ModernResolutions.exe'
$compileArgs=@('/nologo','/target:winexe','/platform:anycpu','/optimize+','/reference:System.Windows.Forms.dll','/reference:System.Drawing.dll',('/out:'+$exe),('/win32manifest:'+(Join-Path $PSScriptRoot 'launcher\app.manifest')))
$compileArgs+=('/resource:'+(Join-Path $PSScriptRoot 'assets\readme-cover.png')+',artwork/readme-cover.png')
foreach($relative in @('Install.ps1','Restore.ps1','Start-Mod.ps1','src/Apply-ResolutionPatch.ps1','src/Prepare-Assets.ps1','src/Mod.Common.ps1','src/Safe-SeaBlit.ps1','src/Launch Patrician Modern Resolutions.cmd')) {
 $compileArgs+=('/resource:'+(Join-Path $PSScriptRoot $relative)+',payload/'+$relative)
}
$compileArgs+=(Join-Path $PSScriptRoot 'launcher\Program.cs')
& $compiler @compileArgs
if($LASTEXITCODE -ne 0){throw 'Launcher compilation failed.'}
$selfTest=Join-Path $dist 'self-test.txt'
$process=Start-Process -FilePath $exe -ArgumentList ('--self-test "'+$selfTest+'"') -Wait -PassThru
if($process.ExitCode -ne 0 -or !(Test-Path $selfTest)){throw 'Launcher self-test failed.'}
Get-Content $selfTest
Copy-Item (Join-Path $PSScriptRoot 'QUICKSTART.txt'),(Join-Path $PSScriptRoot 'README.md'),(Join-Path $PSScriptRoot 'LICENSE'),(Join-Path $PSScriptRoot 'CHANGELOG.md') $dist -Force
Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'RELEASE-CHECKS.md') -Destination $dist -Force
Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'assets'),(Join-Path $PSScriptRoot 'docs') -Destination $dist -Recurse -Force
$zip=Join-Path $dist 'Patrician3-Modern-Resolutions-1.0.2.zip'
Compress-Archive -Path $exe,(Join-Path $dist 'QUICKSTART.txt'),(Join-Path $dist 'README.md'),(Join-Path $dist 'LICENSE'),(Join-Path $dist 'CHANGELOG.md'),(Join-Path $dist 'RELEASE-CHECKS.md'),(Join-Path $dist 'assets'),(Join-Path $dist 'docs') -DestinationPath $zip -Force
$hash=(Get-FileHash $zip -Algorithm SHA256).Hash.ToLowerInvariant()
"$hash  Patrician3-Modern-Resolutions-1.0.2.zip" | Set-Content (Join-Path $dist 'SHA256SUMS.txt')
Write-Host "Package ready: $zip"
