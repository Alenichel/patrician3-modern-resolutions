param([string]$Executable=(Join-Path (Split-Path $PSScriptRoot -Parent) 'dist\Patrician3ModernResolutions.exe'))
$ErrorActionPreference='Stop'
$repo=Split-Path $PSScriptRoot -Parent
$assembly=[Reflection.Assembly]::LoadFile((Resolve-Path -LiteralPath $Executable).Path)
$resources=@($assembly.GetManifestResourceNames() | Where-Object {$_ -like 'payload/*' -or $_ -eq 'artwork/readme-cover.png'})
if($resources.Count -ne 12){throw 'Unexpected embedded payload count'}
foreach($name in $resources) {
 $relative=if($name -like 'payload/*'){$name.Substring(8)}else{'assets/readme-cover.png'}
 $expected=[IO.File]::ReadAllBytes((Join-Path $repo $relative))
 $stream=$assembly.GetManifestResourceStream($name)
 try {
  $copy=New-Object IO.MemoryStream
  try {$stream.CopyTo($copy);$actual=$copy.ToArray()}finally{$copy.Dispose()}
 }finally{$stream.Dispose()}
 if([Convert]::ToBase64String($actual) -cne [Convert]::ToBase64String($expected)){throw "Embedded resource differs from source: $relative"}
}
'PASS: all 11 embedded payload files and the README cover match repository sources byte-for-byte'
