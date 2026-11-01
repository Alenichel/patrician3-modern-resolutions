function Get-ResolutionProfile([int]$Width=0,[int]$Height=0) {
 if($Width -eq 0 -and $Height -eq 0) {
  Add-Type -AssemblyName System.Windows.Forms
  $screen=[System.Windows.Forms.Screen]::PrimaryScreen.Bounds
  $Width=$screen.Width;$Height=$screen.Height
 }
 $catalog=Get-Content -LiteralPath (Join-Path $PSScriptRoot 'ResolutionProfiles.json') -Raw | ConvertFrom-Json
 $selected=@($catalog.profiles | Where-Object {$_.width -eq $Width -and $_.height -eq $Height})
 if($selected.Count -ne 1){throw "Unsupported resolution ${Width}x${Height}. Supported: 1920x1080, 1920x1200, 2560x1080, 2560x1440, 3440x1440."}
 $viewport=$Width-284
 $margin=[int][Math]::Max(0,[Math]::Floor(($viewport-2400)/2))
 $canvasWidth=2400
 if($margin -gt 0){$canvasWidth=$Width}
 return [pscustomobject]@{
  Key="${Width}x${Height}";Width=$Width;Height=$Height
  MapViewportWidth=$viewport;MapViewportHeight=$Height-42;PanelHeight=$Height-600
  SeaCanvasWidth=$canvasWidth;SeaCanvasHeight=1800
  CenteringRequired=($margin -gt 0);CameraX=-$margin
  GameplayVerified=[bool]$selected[0].gameplayVerified
 }
}
function Assert-PreparedProfile([string]$GamePath,$Profile) {
 $path=Join-Path $GamePath 'mods-ultrawide\prepared\profile.json'
 if(!(Test-Path -LiteralPath $path)){throw 'Prepared profile metadata is missing. Reinstall using the launcher.'}
 $prepared=Get-Content -LiteralPath $path -Raw | ConvertFrom-Json
 if($prepared.Width -ne $Profile.Width -or $prepared.Height -ne $Profile.Height){throw "Prepared assets do not match $($Profile.Key). Reinstall using the launcher."}
}
