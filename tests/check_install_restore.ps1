param([Parameter(Mandatory=$true)][string]$GamePath)
$ErrorActionPreference='Stop'
$repo=Split-Path $PSScriptRoot -Parent
. (Join-Path $repo 'src\Mod.Common.ps1')
. (Join-Path $repo 'src\ResolutionProfiles.ps1')
$fixture=Join-Path $env:TEMP ('Patrician3Mod-Test-'+[Guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $fixture | Out-Null
try {
 Copy-Item -LiteralPath (Join-Path $GamePath 'Patrician3.exe') -Destination $fixture
 New-Item -ItemType HardLink -Path (Join-Path $fixture 'p2arch0_eng.cpr') -Target (Join-Path $GamePath 'p2arch0_eng.cpr') | Out-Null
 $original="[OPTIONS]`r`nAUFLOESUNG=1`r`nSOUND=72`r`n"
 [IO.File]::WriteAllText((Join-Path $fixture 'P2.cfg'),$original)
 New-Item -ItemType Directory -Path (Join-Path $fixture 'images'),(Join-Path $fixture 'Save') | Out-Null
 'preexisting-image' | Set-Content (Join-Path $fixture 'images\HauptscreenE1280.bmp')
 'unrelated-file' | Set-Content (Join-Path $fixture 'images\unrelated.txt')
 'save-must-survive' | Set-Content (Join-Path $fixture 'Save\test.sav')
 Assert-CompatibleGame $fixture
 $exeHash=(Get-FileHash (Join-Path $fixture 'Patrician3.exe')).Hash
 $catalog=Get-Content (Join-Path $repo 'src\ResolutionProfiles.json') -Raw | ConvertFrom-Json
 foreach($item in $catalog.profiles) {
  & powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $repo 'src\Prepare-Assets.ps1') -GamePath $fixture -OutputPath (Join-Path $fixture 'mods-ultrawide\prepared') -Width $item.width -Height $item.height
  if($LASTEXITCODE -ne 0){throw 'Generation failed'}
  $profile=Get-ResolutionProfile -Width $item.width -Height $item.height
  Assert-PreparedProfile -GamePath $fixture -Profile $profile
  $other=Get-ResolutionProfile -Width 1920 -Height $(if($item.height -eq 1080){1200}else{1080})
  $rejected=$false;try {Assert-PreparedProfile -GamePath $fixture -Profile $other}catch{$rejected=$true}
  if(!$rejected){throw 'Mismatched prepared profile accepted'}
  Activate-ModFiles $fixture
  Activate-ModFiles $fixture
 }
 if([IO.File]::ReadAllText((Join-Path $fixture 'mods-ultrawide\backup-originali\P2.cfg')) -ne $original){throw 'Backup overwritten on second activation'}
 if(Test-Path (Join-Path $fixture 'mods-ultrawide\backup-originali\Save')){throw 'Saves must not be copied or changed'}
 Restore-ModFiles $fixture
 if([IO.File]::ReadAllText((Join-Path $fixture 'P2.cfg')) -ne $original){throw 'Config restore failed'}
 if((Get-Content (Join-Path $fixture 'images\HauptscreenE1280.bmp') -Raw).Trim() -ne 'preexisting-image'){throw 'Original asset not restored'}
 if(Test-Path (Join-Path $fixture 'images\Vollansichtskarte.bmp')){throw 'Mod-only asset still active'}
 if((Get-Content (Join-Path $fixture 'images\unrelated.txt') -Raw).Trim() -ne 'unrelated-file'){throw 'Unrelated file changed'}
 if((Get-Content (Join-Path $fixture 'Save\test.sav') -Raw).Trim() -ne 'save-must-survive'){throw 'Save changed'}
 if((Get-FileHash (Join-Path $fixture 'Patrician3.exe')).Hash -ne $exeHash){throw 'Executable changed'}
 [IO.File]::AppendAllText((Join-Path $fixture 'Patrician3.exe'),'different version')
 $rejected=$false
 try {Assert-CompatibleGame $fixture} catch {$rejected=$true}
 if(!$rejected){throw 'Unknown version was accepted'}
 'PASS: five profile switches and repeated activation preserve first backup; mismatched assets rejected; config/assets restored; saves and unrelated files untouched; executable unchanged; wrong version rejected'
} finally {
 $resolved=[IO.Path]::GetFullPath($fixture)
 $boundary=[IO.Path]::GetFullPath($env:TEMP).TrimEnd('\')+'\'
 if(!$resolved.StartsWith($boundary,[StringComparison]::OrdinalIgnoreCase) -or ![IO.Path]::GetFileName($resolved).StartsWith('Patrician3Mod-Test-')){throw 'Unsafe test cleanup path'}
 Remove-Item -LiteralPath $resolved -Recurse -Force
}
