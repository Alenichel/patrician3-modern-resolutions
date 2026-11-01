function New-ResolutionConstantEdits([byte[]]$Buffer,[long]$Base,$Profile) {
 $hex=[BitConverter]::ToString($Buffer).Replace('-','')
 $widthHex=[BitConverter]::ToString([BitConverter]::GetBytes([int]$Profile.Width)).Replace('-','')
 $heightHex=[BitConverter]::ToString([BitConverter]::GetBytes([int]$Profile.Height)).Replace('-','')
 $edits=@()
 foreach($pair in @(@('4C','50'),@('18','1C'),@('3C','40'),@('48','4C'),@('24','28'))) {
  $sig='C74424'+$pair[0]+'00050000C74424'+$pair[1]+'00040000'
  $i=$hex.IndexOf($sig)
  if($i -lt 0){$sig='C74424'+$pair[0]+$widthHex+'C74424'+$pair[1]+$heightHex;$i=$hex.IndexOf($sig)}
  if($i -lt 0 -or $hex.IndexOf($sig,$i+2) -ge 0){throw "Missing or ambiguous resolution signature: $sig"}
  $edits+=@{Address=$Base+$i/2+4;Data=[BitConverter]::GetBytes([int]$Profile.Width)}
  $edits+=@{Address=$Base+$i/2+12;Data=[BitConverter]::GetBytes([int]$Profile.Height)}
 }
 foreach($spec in @(@('0F84AF0000003D00050000',7),@('3D00040000741E3D00050000',8))) {
  $sig=$spec[0];$i=$hex.IndexOf($sig)
  if($i -lt 0){$sig=$sig.Replace('00050000',$widthHex);$i=$hex.IndexOf($sig)}
  if($i -lt 0 -or $hex.IndexOf($sig,$i+2) -ge 0){throw "Missing or ambiguous width signature: $sig"}
  $edits+=@{Address=$Base+$i/2+$spec[1];Data=[BitConverter]::GetBytes([int]$Profile.Width)}
 }
 return $edits
}
