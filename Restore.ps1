param([string]$GamePath='C:\Program Files (x86)\Steam\steamapps\common\Patrician III')
$ErrorActionPreference='Stop'
$GamePath=(Resolve-Path -LiteralPath $GamePath).Path
if(Get-Process Patrician3,Patrician -ErrorAction SilentlyContinue){throw 'Chiudi il gioco prima del ripristino.'}
$backup=Join-Path $GamePath 'mods-ultrawide\backup-originali'
if(!(Test-Path (Join-Path $backup 'P2.cfg'))){throw 'Backup originale non trovato.'}
$disabled=Join-Path $GamePath ('mods-ultrawide\disabled-'+(Get-Date -Format yyyyMMdd-HHmmss))
New-Item -ItemType Directory $disabled | Out-Null
foreach($relative in @('scripts\screenGame.ini','scripts\accelMap.ini','scripts\textures.ini','images\HauptscreenA1280.bmp','images\HauptscreenE1280.bmp','images\Vollansichtskarte1280.bmp')) {
 $active=Join-Path $GamePath $relative
 $saved=Join-Path $backup $relative
 if(Test-Path $active){
  $target=Join-Path $disabled $relative
  New-Item -ItemType Directory -Force (Split-Path $target -Parent) | Out-Null
  Move-Item -LiteralPath $active -Destination $target
 }
 if(Test-Path $saved){Copy-Item -LiteralPath $saved -Destination $active}
}
Copy-Item (Join-Path $backup 'P2.cfg') (Join-Path $GamePath 'P2.cfg') -Force
Write-Host 'Originali ripristinati. Avvia normalmente da Steam. Salvataggi invariati.'
