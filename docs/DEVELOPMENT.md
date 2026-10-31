# Development and distribution

[Back to the project overview](../README.md)

## Build the standalone launcher

The repository does not contain game files. The Windows launcher embeds the
mod scripts and generates images and INI files from the user's local game.
No replacement game executable or external asset download is required.

Build with the .NET Framework compiler included in Windows:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\Build.ps1
```

Alternatively, open `Launch-Mod.cmd`. Build output is written to `dist/`:

- `Patrician3ModernResolutions.exe`
- `Patrician3-Modern-Resolutions-1.0.1.zip`
- documentation, cover artwork, license, and changelog
- `SHA256SUMS.txt`

Share the ZIP and its checksum. Do not distribute the game folder or generated
`prepared` and `backup-originali` directories. The build does not publish anything online.

## Run the scripts directly

```powershell
$game = 'D:\SteamLibrary\steamapps\common\Patrician III'
powershell -NoProfile -ExecutionPolicy Bypass -File .\Start-Mod.ps1 -GamePath $game
powershell -NoProfile -ExecutionPolicy Bypass -File .\Restore.ps1 -GamePath $game
```

`src/Apply-ResolutionPatch.ps1` applies the native runtime patch.
`src/Prepare-Assets.ps1` generates the local image and INI overrides.
`src/Mod.Common.ps1` contains compatibility checks, activation, backup, and restore.

## Supported game and runtime patch

The verified SHA256 of `Patrician3.exe` is:
`21aca7ae64ab3b8c8d55c9c4e547e311ee4ede4e9e62bb6e8b7fd8de180ea60a`.

The patch checks nine unique signatures before writing and reads back every
change. It replaces five width/height pairs, two width comparisons, and both
horizontal sea-camera clamps. At a viewport width of 3156, the camera offset
is -378; the original clamp behavior is retained at other widths.

The project name is broader than the current implementation. This release
still supports only the verified English Steam build at 3440 x 1440.
Changing the name does not add resolution support or alter game behavior.

The on-disk identifiers `mods-ultrawide` and `backup-originali` are intentionally
retained for compatibility with existing installs. Original German filenames
and configuration keys are required by the game's archive format and are not translated.

## Tests

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tests/check_install_restore.ps1 -GamePath $game
python tests/check_camera.py
python tests/check_seamap.py $game "$game\mods-ultrawide\prepared"
python tests/check_panel.py $game "$game\mods-ultrawide\prepared"
python tests/check_release.py dist
```

Only the x86 emulation test requires `pip install unicorn`. Release users do
not need Python or Unicorn. Tests cover both hooks in 40 cases, map and panel
pixels, repeated activation, backup/restore, untouched saves and unrelated
files, rejection of unknown executable versions, and release contents/checksums.
The build checks its embedded payload and renders a launcher preview.

## Credits and license

Original research by brotkohl et al., [Raydell's guide](https://steamcommunity.com/sharedfiles/filedetails/?id=382413909),
[dsedivec's notes](https://github.com/dsedivec/P3WideScreen/blob/master/binary-changes.txt),
and [P3Modding documentation](https://p3modding.github.io/).
Developed with assistance from OpenAI Codex. The README cover was generated
with ImageGen; in-game graphics are adapted locally from the original assets.

Original mod code and documentation artwork use the [MIT license](../LICENSE).
The game and proprietary graphics remain subject to their owners' terms.
