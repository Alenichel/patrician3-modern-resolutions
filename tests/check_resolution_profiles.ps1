$ErrorActionPreference='Stop'
$repo=Split-Path $PSScriptRoot -Parent
. (Join-Path $repo 'src\ResolutionProfiles.ps1')
. (Join-Path $repo 'src\ResolutionPatch.Plan.ps1')
$catalog=Get-Content (Join-Path $repo 'src\ResolutionProfiles.json') -Raw | ConvertFrom-Json
$patterns=@('C744244C00050000C744245000040000','C744241800050000C744241C00040000','C744243C00050000C744244000040000','C744244800050000C744244C00040000','C744242400050000C744242800040000','0F84AF0000003D00050000','3D00040000741E3D00050000')
$hex=('90'*32)+($patterns -join ('90'*16))+('90'*32)
$original=New-Object byte[] ($hex.Length/2)
for($i=0;$i -lt $hex.Length;$i+=2){$original[$i/2]=[Convert]::ToByte($hex.Substring($i,2),16)}
foreach($item in $catalog.profiles) {
 $profile=Get-ResolutionProfile -Width $item.width -Height $item.height
 $working=[byte[]]$original.Clone()
 $edits=@(New-ResolutionConstantEdits -Buffer $working -Base 0x400000 -Profile $profile)
 if($edits.Count -ne 12){throw 'Wrong edit count'}
 $changed=@{};$widthCount=0;$heightCount=0
 foreach($edit in $edits) {
  $offset=[int]($edit.Address-0x400000)
  $value=[BitConverter]::ToInt32($edit.Data,0)
  if($value -eq $profile.Width){$widthCount++}elseif($value -eq $profile.Height){$heightCount++}else{throw 'Wrong dimension value'}
  [Array]::Copy($edit.Data,0,$working,$offset,4)
  for($i=$offset;$i -lt $offset+4;$i++){if($changed.ContainsKey($i)){throw 'Overlapping edits'};$changed[$i]=$true}
 }
 if($widthCount -ne 7 -or $heightCount -ne 5){throw 'Not all dimension sites were patched'}
 for($i=0;$i -lt $working.Length;$i++){if(!$changed.ContainsKey($i) -and $working[$i] -ne $original[$i]){throw 'Unrelated code changed'}}
 if(@(New-ResolutionConstantEdits -Buffer $working -Base 0x400000 -Profile $profile).Count -ne 12){throw 'Target signatures not recognized'}
 if($profile.MapViewportWidth -ne $item.width-284 -or $profile.PanelHeight -ne $item.height-600){throw 'Wrong profile geometry'}
 if($profile.CenteringRequired -ne ($item.width -eq 3440)){throw 'Narrow profiles must preserve original camera behavior'}
 if(!$profile.CenteringRequired -and $profile.SeaCanvasWidth -ne 2400){throw 'Narrow profiles must keep the original sea-image bounds'}
}
$duplicate=New-Object byte[] ($original.Length*2)
[Array]::Copy($original,0,$duplicate,0,$original.Length);[Array]::Copy($original,0,$duplicate,$original.Length,$original.Length)
$rejected=$false;try {New-ResolutionConstantEdits -Buffer $duplicate -Base 0x400000 -Profile $profile | Out-Null}catch{$rejected=$true}
if(!$rejected){throw 'Duplicate signatures accepted'}
foreach($dimensions in @(@(3840,2160),@(1366,768),@(1920,0))) {
 $rejected=$false;try {Get-ResolutionProfile -Width $dimensions[0] -Height $dimensions[1] | Out-Null}catch{$rejected=$true}
 if(!$rejected){throw 'Unsupported profile accepted'}
}
'PASS: all five profiles patch exactly 12 constants; no overlapping/unrelated writes; narrow camera preserved; duplicate signatures and unsupported profiles rejected'
