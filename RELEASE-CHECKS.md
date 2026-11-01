# Release 1.1.2 validation

- All five profiles: 12 resolution constants, unique signatures, repeated target recognition, unrelated bytes, geometry, and unsupported-resolution rejection checked.
- Generated assets for all five profiles: sea-map pixels and palette preserved, panel relief and caps preserved, expected image dimensions, INI values, and profile metadata checked against the local game archive.
- Five profile switches and repeated activation: initial backup preserved, mismatched prepared assets rejected, original configuration/assets restored, saves and unrelated files unchanged, executable unchanged, unknown executable rejected.
- Camera hooks: 60 emulated cases. Source-copy wrapper: 11 emulated boundary/passthrough cases, including the captured crash rectangle and narrower native viewports.
- Launcher: compilation, embedded payload, profile catalog, selector choices and current-display default, Steam discovery, and rendered preview checked. ZIP contents, links, CRC, and SHA256 checked.

3440x1440 gameplay, centered sea map, and panel proportions were confirmed by
the user on 2026-10-31. Fast-forward with a moving ship was confirmed working
on 2026-11-01 after the source-copy fix. See [crash findings](docs/CRASH-2026-10-31.md).

The user confirmed 1920x1080 working on 2026-11-01. Its runtime log records
all 12 constants verified at seven sites, native camera behavior, and 100% UI
scale. The original executable SHA256 remains unchanged. No later Patrician
application crashes were found in the Windows Application log during this audit.
This confirmation does not independently verify extended fast-forward at 1080p.

Later investigation reproduced a separate foreground-recovery crash in
`apphelp.dll`, even without any UI-scaling prototype loaded. The release lists
this as a known fullscreen/DirectDraw compatibility issue; no focus-recovery
fix or experimental graphics wrapper is included.

1920x1200, 2560x1080, and 2560x1440 have automated validation only; real gameplay
at those resolutions and cross-machine bootstrap testing remain outstanding.
The audit did not launch a new gameplay session. Generated-asset and restore
tests ran in temporary fixtures; the user's installed 1080p profile was retained.
The embedded payload and cover were compared byte-for-byte with repository sources. Support
requires the stated English Steam build. The public repository contains the
stable 100% UI-scale implementation; unfinished UI-scaling experiments remain
in a separate local worktree and are not part of this release.
No crash dumps or extracted proprietary assets are distributed.
