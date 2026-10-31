$script:ModFiles=@('scripts\screenGame.ini','scripts\accelMap.ini','scripts\textures.ini','images\HauptscreenA1280.bmp','images\HauptscreenE1280.bmp','images\Vollansichtskarte1280.bmp','images\Vollansichtskarte.bmp')
function Assert-CompatibleGame([string]$GamePath) {
 foreach($name in @('Patrician3.exe','p2arch0_eng.cpr','P2.cfg')) {
  if(!(Test-Path -LiteralPath (Join-Path $GamePath $name) -PathType Leaf)){throw "Required file not found: $name. The English Steam edition of Patrician III is required."}
 }
 $hash=(Get-FileHash -LiteralPath (Join-Path $GamePath 'Patrician3.exe') -Algorithm SHA256).Hash
 if($hash -ne '21ACA7AE64AB3B8C8D55C9C4E547E311EE4EDE4E9E62BB6E8B7FD8DE180EA60A'){throw 'Unsupported game version. No files were changed. This release supports the English Steam edition of Patrician III 1.1.'}
}
function Backup-ModFiles([string]$GamePath) {
 $backup=Join-Path $GamePath 'mods-ultrawide\backup-originali'
 if(!(Test-Path -LiteralPath $backup)) {
  New-Item -ItemType Directory -Path $backup | Out-Null
  foreach($relative in (@('P2.cfg')+$script:ModFiles)) {
   $source=Join-Path $GamePath $relative
   if(Test-Path -LiteralPath $source) {
    $target=Join-Path $backup $relative
    New-Item -ItemType Directory -Force -Path (Split-Path $target -Parent) | Out-Null
    Copy-Item -LiteralPath $source -Destination $target
   }
  }
  'Original files, created before activation. Do not overwrite.' | Set-Content (Join-Path $backup 'backup.txt')
 }
 if(!(Test-Path -LiteralPath (Join-Path $backup 'P2.cfg'))){throw 'Incomplete backup: P2.cfg is missing. Recover the original backup before continuing.'}
}
function Activate-ModFiles([string]$GamePath) {
 $prepared=Join-Path $GamePath 'mods-ultrawide\prepared'
 foreach($relative in $script:ModFiles) {
  if(!(Test-Path -LiteralPath (Join-Path $prepared $relative))){throw "Missing generated asset: $relative"}
 }
 Backup-ModFiles $GamePath
 foreach($relative in $script:ModFiles) {
  $target=Join-Path $GamePath $relative
  New-Item -ItemType Directory -Force -Path (Split-Path $target -Parent) | Out-Null
  Copy-Item -LiteralPath (Join-Path $prepared $relative) -Destination $target -Force
 }
 $cfg=Join-Path $GamePath 'P2.cfg'
 $text=[IO.File]::ReadAllText($cfg)
 if($text -notmatch '(?m)^AUFLOESUNG=\d+'){throw 'Resolution setting not found in P2.cfg.'}
 [IO.File]::WriteAllText($cfg,($text -replace '(?m)^AUFLOESUNG=\d+','AUFLOESUNG=2'),[Text.Encoding]::ASCII)
}
function Find-SteamExecutable {
 foreach($process in (Get-Process steam -ErrorAction SilentlyContinue)) {
  if($process.Path -and (Test-Path -LiteralPath $process.Path)){return $process.Path}
 }
 foreach($key in @('HKCU:\Software\Valve\Steam','HKLM:\SOFTWARE\WOW6432Node\Valve\Steam','HKLM:\SOFTWARE\Valve\Steam')) {
  $values=Get-ItemProperty -Path $key -ErrorAction SilentlyContinue
  $candidates=@()
  if($values.SteamExe){$candidates+= $values.SteamExe}
  if($values.SteamPath){$candidates+=Join-Path $values.SteamPath 'steam.exe'}
  if($values.InstallPath){$candidates+=Join-Path $values.InstallPath 'steam.exe'}
  foreach($candidate in $candidates) {
   if($candidate -and (Test-Path -LiteralPath $candidate -PathType Leaf)){return $candidate}
  }
 }
 $fallback=Join-Path ${env:ProgramFiles(x86)} 'Steam\steam.exe'
 if(Test-Path -LiteralPath $fallback){return $fallback}
 throw 'Steam was not found. Install and start Steam before using the mod.'
}
function Restore-ModFiles([string]$GamePath) {
 $GamePath=(Resolve-Path -LiteralPath $GamePath).Path
 $boundary=$GamePath.TrimEnd('\')+'\'
 $backup=Join-Path $GamePath 'mods-ultrawide\backup-originali'
 if(!(Test-Path -LiteralPath (Join-Path $backup 'P2.cfg'))){throw 'Original backup not found. No files were changed.'}
 $disabled=Join-Path $GamePath ('mods-ultrawide\disabled-'+(Get-Date -Format yyyyMMdd-HHmmss)+'-'+[Guid]::NewGuid().ToString('N').Substring(0,6))
 if(![IO.Path]::GetFullPath($disabled).StartsWith($boundary,[StringComparison]::OrdinalIgnoreCase)){throw 'Invalid restore destination.'}
 New-Item -ItemType Directory -Path $disabled | Out-Null
 foreach($relative in $script:ModFiles) {
  $active=Join-Path $GamePath $relative
  $saved=Join-Path $backup $relative
  if(![IO.Path]::GetFullPath($active).StartsWith($boundary,[StringComparison]::OrdinalIgnoreCase)){throw 'Invalid active-file path.'}
  if(Test-Path -LiteralPath $active) {
   $target=Join-Path $disabled $relative
   New-Item -ItemType Directory -Force -Path (Split-Path $target -Parent) | Out-Null
   Move-Item -LiteralPath $active -Destination $target
  }
  if(Test-Path -LiteralPath $saved){Copy-Item -LiteralPath $saved -Destination $active}
 }
 Copy-Item -LiteralPath (Join-Path $backup 'P2.cfg') -Destination (Join-Path $GamePath 'P2.cfg') -Force
 Write-Host 'Original files restored. Launch normally from Steam. Save files were not changed.'
}
