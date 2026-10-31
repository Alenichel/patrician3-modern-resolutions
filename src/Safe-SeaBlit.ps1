function New-SafeSeaBlitHook([long]$StubAddress,[long]$OriginalAddress,[long]$CallAddress) {
 $bytes=New-Object 'System.Collections.Generic.List[byte]'
 # Only the centered 3156-pixel sea view needs this adjustment.
 # cdecl arguments: source X/Y, destination X/Y, width, height.
 $bytes.AddRange([byte[]]@(0x81,0x7c,0x24,0x04,0x86,0xfe,0xff,0xff,0x0f,0x85,0,0,0,0))
 $bytes.AddRange([byte[]]@(0x81,0x7c,0x24,0x14,0x54,0x0c,0,0,0x0f,0x85,0,0,0,0))
 # Preserve registers while drawing the left margin from the known neutral
 # strip at source X=3062..3439 in the generated 3440-pixel background.
 $bytes.AddRange([byte[]]@(0x60,0xff,0x74,0x24,0x38,0x68,0x7a,0x01,0,0,0xff,0x74,0x24,0x38,0xff,0x74,0x24,0x38,0xff,0x74,0x24,0x38,0x68,0xf6,0x0b,0,0))
 $callOffset=$bytes.Count
 $bytes.Add(0xe8);$bytes.AddRange([BitConverter]::GetBytes([int]($OriginalAddress-($StubAddress+$callOffset+5))))
 $bytes.AddRange([byte[]]@(0x83,0xc4,0x18,0x61))
 # Clip the negative source X. Shift destination X and reduce width by
 # exactly the same amount, preserving the position of the map and ships.
 $bytes.AddRange([byte[]]@(0xc7,0x44,0x24,0x04,0,0,0,0,0x81,0x44,0x24,0x0c,0x7a,0x01,0,0,0x81,0x6c,0x24,0x14,0x7a,0x01,0,0))
 $tailOffset=$bytes.Count
 $bytes.Add(0xe9);$bytes.AddRange([BitConverter]::GetBytes([int]($OriginalAddress-($StubAddress+$tailOffset+5))))
 foreach($immediate in @(10,24)) {
  $relative=[BitConverter]::GetBytes([int]($tailOffset-($immediate+4)))
  for($i=0;$i -lt 4;$i++){$bytes[$immediate+$i]=$relative[$i]}
 }
 $hook=New-Object 'System.Collections.Generic.List[byte]'
 $hook.Add(0xe8);$hook.AddRange([BitConverter]::GetBytes([int]($StubAddress-($CallAddress+5))))
 return @{Stub=$bytes.ToArray();Hook=$hook.ToArray()}
}
