$ErrorActionPreference='Stop'
$compiler=Join-Path $env:WINDIR 'Microsoft.NET\Framework64\v4.0.30319\csc.exe'
if(!(Test-Path $compiler)){$compiler=Join-Path $env:WINDIR 'Microsoft.NET\Framework\v4.0.30319\csc.exe'}
if(!(Test-Path $compiler)){throw 'Compilatore .NET Framework 4 non trovato.'}
$dist=Join-Path $PSScriptRoot 'dist'
New-Item -ItemType Directory -Force $dist | Out-Null
$exe=Join-Path $dist 'Patrician3Ultrawide.exe'
$compileArgs=@('/nologo','/target:winexe','/platform:anycpu','/optimize+','/reference:System.Windows.Forms.dll','/reference:System.Drawing.dll',('/out:'+$exe),('/win32manifest:'+(Join-Path $PSScriptRoot 'launcher\app.manifest')))
foreach($relative in @('Install.ps1','Restore.ps1','Start-Mod.ps1','src/Avvia-Ultrawide.ps1','src/Prepare-Assets.ps1','src/Mod.Common.ps1','src/Avvia Patrician Ultrawide.cmd')) {
 $compileArgs+=('/resource:'+(Join-Path $PSScriptRoot $relative)+',payload/'+$relative)
}
$compileArgs+=(Join-Path $PSScriptRoot 'launcher\Program.cs')
& $compiler @compileArgs
if($LASTEXITCODE -ne 0){throw 'Compilazione launcher fallita.'}
$selfTest=Join-Path $dist 'self-test.txt'
$process=Start-Process -FilePath $exe -ArgumentList ('--self-test "'+$selfTest+'"') -Wait -PassThru
if($process.ExitCode -ne 0 -or !(Test-Path $selfTest)){throw 'Self-test del launcher fallito.'}
Get-Content $selfTest
Copy-Item (Join-Path $PSScriptRoot 'DISTRIBUZIONE.txt'),(Join-Path $PSScriptRoot 'README.md'),(Join-Path $PSScriptRoot 'LICENSE'),(Join-Path $PSScriptRoot 'CHANGELOG.md') $dist -Force
Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'RELEASE-CHECKS.md') -Destination $dist -Force
Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'assets'),(Join-Path $PSScriptRoot 'docs') -Destination $dist -Recurse -Force
$zip=Join-Path $dist 'Patrician3-Ultrawide-1.0.0.zip'
Compress-Archive -Path $exe,(Join-Path $dist 'DISTRIBUZIONE.txt'),(Join-Path $dist 'README.md'),(Join-Path $dist 'LICENSE'),(Join-Path $dist 'CHANGELOG.md'),(Join-Path $dist 'RELEASE-CHECKS.md'),(Join-Path $dist 'assets'),(Join-Path $dist 'docs') -DestinationPath $zip -Force
$hash=(Get-FileHash $zip -Algorithm SHA256).Hash.ToLowerInvariant()
"$hash  Patrician3-Ultrawide-1.0.0.zip" | Set-Content (Join-Path $dist 'SHA256SUMS.txt')
Write-Host "Pacchetto pronto: $zip"
