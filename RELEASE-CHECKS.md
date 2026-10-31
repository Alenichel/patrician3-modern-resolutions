# Release 1.0.0 checks

- Original ultrawide gameplay, centered sea map and side-panel proportions:
  confirmed working in game by the user on 2026-10-31.
- Both production x86 camera hooks: 40 emulated cases passed.
- Sea map: all 4,320,000 original pixels and palette preserved.
- Side panel: relief, end caps and palette preserved without stretching.
- Isolated install/restore fixture: repeated activation preserves the first
  backup; original config and preexisting image restored; mod-only assets
  deactivated; unrelated files, saves and executable unchanged.
- Unknown executable version rejected by SHA256 preflight.
- Compiled launcher: embedded payload verified, UI preview rendered and
  inspected, existing Steam installation detected automatically.
- Distribution lint: no original game files, secrets or personal paths.
- ZIP entry allowlist, CRC and SHA256 checked.

The new GUI bootstrap has not yet been used for a full elevated game launch
on another machine. Compatibility is limited to the stated English Steam
build and primary display at 3440x1440. No online publication was performed.
