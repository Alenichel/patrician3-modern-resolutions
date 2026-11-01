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
- `Patrician3-Modern-Resolutions-1.1.2.zip`
- documentation, cover artwork, license, and changelog
- `SHA256SUMS.txt`

Share the ZIP and its checksum. Do not distribute the game folder or generated
`prepared` and `backup-originali` directories. The build does not publish anything online.

Use `Build.ps1 -SkipLauncherPreview` for local packaging while a game is running;
this avoids opening the launcher preview and changing desktop focus. Publishing
requires the full build and its self-test, which run on the Windows CI runner.

## Publish a GitHub release

Update the version consistently in the manifest, launcher, build, tests and
package documentation, and update the changelog. Commit to `main`, then push
a matching stable tag such as `v1.1.2`. The release workflow validates the tag
against `manifest.json`, builds on Windows, tests the embedded payload and ZIP,
and attaches the ready-to-use ZIP and `SHA256SUMS.txt` to a GitHub Release.
The workflow can also be dispatched manually with an existing version tag.
It publishes only that tagged source tree, never a separate local worktree.

Release notes come from `.github/release-notes.md`; update them for each release.
The workflow refuses to overwrite an existing release. Failed build/test runs
do not publish a release.

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

`src/ResolutionProfiles.json` is the shared profile catalog used by PowerShell
and the embedded launcher. The four new profiles are 1920x1080, 1920x1200,
2560x1080, and 2560x1440; 3440x1440 remains available. UI scale is 100%. The launcher exposes a profile selector defaulting to the
current primary display when supported; an unsupported display has no default.
The selected catalog key is passed to the elevated worker, validated again,
and forwarded as explicit width/height to the scripts.
`-Width` and `-Height` optionally select a catalog profile when running scripts;
omit both to detect the primary display. Unsupported dimensions are rejected.

All profiles replace five width/height pairs and two width comparisons:
12 constants at seven unique sites, checked before writing and read back.
Only 3440x1440 adds two camera hooks and a source-copy hook, for ten sites.
Its viewport width is 3156 and camera X is -378. The source-copy wrapper in
`src/Safe-SeaBlit.ps1` prevents negative image reads during fast-forward.
See the [crash investigation](CRASH-2026-10-31.md).

Narrower profiles preserve the native camera and the original 2400x1800 sea
image. Generated top bars, panels, overview maps, and INI files follow the
selected dimensions. Prepared profile metadata must match the runtime patch.
Close the game before switching profiles; installation regenerates assets
without replacing the initial backup. 1920x1080 and 3440x1440 have user gameplay verification;
the other three profiles currently have automated validation only.

The on-disk identifiers `mods-ultrawide` and `backup-originali` are intentionally
retained for compatibility with existing installs. Original German filenames
and configuration keys are required by the game's archive format and are not translated.

## Tests

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tests/check_install_restore.ps1 -GamePath $game
powershell -NoProfile -ExecutionPolicy Bypass -File tests/check_resolution_profiles.ps1
python tests/check_all_profile_assets.py $game
python tests/check_camera.py
python tests/check_safe_blit.py
python tests/check_seamap.py $game "$game\mods-ultrawide\prepared"
python tests/check_panel.py $game "$game\mods-ultrawide\prepared"
powershell -NoProfile -ExecutionPolicy Bypass -File tests/check_embedded_payload.ps1
python tests/check_release.py dist
```

Only the x86 emulation test requires `pip install unicorn`. Release users do
not need Python or Unicorn. Tests cover both camera hooks in 60 cases and the source-copy hook in 11 cases,
all five constant-patch plans, every profile's map and panel
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
