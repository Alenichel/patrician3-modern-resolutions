# Release 1.1.0 validation

- All five profiles: 12 resolution constants, unique signatures, repeated target recognition, unrelated bytes, geometry, and unsupported-resolution rejection checked.
- Generated assets for all five profiles: sea-map pixels and palette preserved, panel relief and caps preserved, expected image dimensions, INI values, and profile metadata checked against the local game archive.
- Five profile switches and repeated activation: initial backup preserved, mismatched prepared assets rejected, original configuration/assets restored, saves and unrelated files unchanged, executable unchanged, unknown executable rejected.
- Camera hooks: 60 emulated cases. Source-copy wrapper: 11 emulated boundary/passthrough cases, including the captured crash rectangle and narrower native viewports.
- Launcher: compilation, embedded payload, profile catalog, Steam discovery, and rendered preview checked. ZIP contents, links, CRC, and SHA256 checked.

3440x1440 gameplay, centered sea map, and panel proportions were confirmed by
the user on 2026-10-31. Fast-forward with a moving ship was confirmed working
on 2026-11-01 after the source-copy fix. See [crash findings](docs/CRASH-2026-10-31.md).

The four new profiles have automated validation only; real gameplay at those
resolutions and cross-machine bootstrap testing remain outstanding. Support
requires the stated English Steam build. The GitHub repository remains private.
No crash dumps or extracted proprietary assets are distributed.
