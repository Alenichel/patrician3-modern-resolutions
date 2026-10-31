# Release 1.0.1 validation

- Original 3440x1440 gameplay, centered sea map, and side-panel proportions:
  confirmed working in game by the user on 2026-10-31.
- This update changes presentation, names, and language; patch coordinates
  and game behavior are unchanged.
- Both production x86 camera hooks: 40 emulated cases.
- Sea map: all 4,320,000 original pixels and the palette preserved.
- Side panel: relief, end caps, and palette preserved without stretching.
- Isolated install/restore fixture: repeated activation preserves the first
  backup; original config and preexisting image restored; mod-only assets
  deactivated; unrelated files, saves, and executable unchanged.
- Unknown executable version rejected by SHA256 preflight.
- Compiled English launcher: embedded payload checked, UI preview rendered
  for inspection, existing Steam installation detected automatically.
- Distribution lint and ZIP checks cover proprietary game files, secrets,
  personal paths, the entry allowlist, CRC, and published SHA256.

The complete GUI bootstrap has not yet been used for an elevated launch
on another machine. Supported configuration: the stated English Steam build
and primary display at 3440x1440. The GitHub repository remains private.
