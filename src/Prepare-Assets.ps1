$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot -Parent
$stage=Join-Path $PSScriptRoot 'prepared'
$enc=[Text.Encoding]::GetEncoding(28591)
$archive=[IO.File]::ReadAllBytes((Join-Path $root 'p2arch0_eng.cpr'))
$names=$enc.GetString($archive)
foreach($folder in @('scripts','images')){New-Item -ItemType Directory -Force (Join-Path $stage $folder) | Out-Null}
foreach($path in @('scripts\screenGame.ini','scripts\accelMap.ini','scripts\textures.ini','images\HauptscreenE1280.bmp','images\HauptscreenA1280.bmp','images\Vollansichtskarte1280.bmp')) {
 $i=$names.IndexOf($path,[StringComparison]::OrdinalIgnoreCase)
 if($i -lt 12){throw "Archive entry missing: $path"}
 $offset=[BitConverter]::ToInt32($archive,$i-12); $size=[BitConverter]::ToInt32($archive,$i-8)
 if($offset -lt 0 -or $size -le 0 -or $offset+$size -gt $archive.Length){throw 'Invalid archive entry'}
 $data=New-Object byte[] $size
 [Array]::Copy($archive,$offset,$data,0,$size)
 [IO.File]::WriteAllBytes((Join-Path $stage $path),$data)
}
# Modify only the 1280x1024 slot; retain the other two standard modes.
$path=Join-Path $stage 'scripts\accelMap.ini'
$text=[IO.File]::ReadAllText($path,$enc).Replace('1280 1024','3440 1440')
[IO.File]::WriteAllText($path,$text,$enc)
$path=Join-Path $stage 'scripts\screenGame.ini'
$text=[IO.File]::ReadAllText($path,$enc).Replace('Frame0=11 0 0 0 0 996 42 0','Frame0=11 0 0 0 0 3156 42 0').Replace('Frame0=9 0 0 0 0 284 424 0','Frame0=9 0 0 0 0 284 840 0').Replace('Pos=996 600','Pos=3156 600')
[IO.File]::WriteAllText($path,$text,$enc)
$path=Join-Path $stage 'scripts\textures.ini'
$text=[IO.File]::ReadAllText($path,$enc).Replace('OffsetNSize0=0 0 284 424','OffsetNSize0=0 0 284 840').Replace('OffsetNSize0=0 0 996 42','OffsetNSize0=0 0 3156 42').Replace('OffsetNSize0=0 0 1280 1024','OffsetNSize0=0 0 3440 1440')
[IO.File]::WriteAllText($path,$text,$enc)
Add-Type @'
using System;
using System.IO;
public static class P3Bitmap {
 public static void Resize(string path,int width,int height) {
  byte[] src=File.ReadAllBytes(path);
  int pixel=BitConverter.ToInt32(src,10), w=BitConverter.ToInt32(src,18), h=BitConverter.ToInt32(src,22);
  if(src[0]!=66 || src[1]!=77 || BitConverter.ToUInt16(src,28)!=8 || BitConverter.ToInt32(src,30)!=0 || h<=0) throw new Exception("Expected uncompressed indexed BMP");
  int oldStride=(w+3)&~3, stride=(width+3)&~3;
  byte[] dst=new byte[pixel+stride*height];
  Array.Copy(src,dst,pixel);
  Array.Copy(BitConverter.GetBytes(dst.Length),0,dst,2,4);
  Array.Copy(BitConverter.GetBytes(width),0,dst,18,4);
  Array.Copy(BitConverter.GetBytes(height),0,dst,22,4);
  Array.Copy(BitConverter.GetBytes(stride*height),0,dst,34,4);
  for(int y=0;y<height;y++) for(int x=0;x<width;x++) dst[pixel+y*stride+x]=src[pixel+(int)((long)y*h/height)*oldStride+(int)((long)x*w/width)];
  File.WriteAllBytes(path,dst);
 }
}
'@
[P3Bitmap]::Resize((Join-Path $stage 'images\Vollansichtskarte1280.bmp'),3440,1440)
[P3Bitmap]::Resize((Join-Path $stage 'images\HauptscreenE1280.bmp'),284,840)
[P3Bitmap]::Resize((Join-Path $stage 'images\HauptscreenA1280.bmp'),3156,42)
'Prepared assets for 3440x1440. Not installed until runtime signatures are verified.'
