# Release 1.0.2 validation

- Original 3440x1440 gameplay, centered sea map, and side-panel proportions:
  confirmed working in game by the user on 2026-10-31.
- Two later fast-forward crashes were recorded at the same indexed-color
  blitter offset. The second minidump identified a negative source rectangle
  introduced by the centered sea camera. See docs/CRASH-2026-10-31.md.
- The new source-clipping hook passes six emulated boundary/passthrough cases,
  including the captured crash rectangle and the vertical camera limit.
  Destination coverage, map position, cdecl stack balance, and saved registers
  are checked against the production hook bytes.
- Both camera hooks retain their 40 passing emulated cases.
- Existing asset and install/restore regression checks remain applicable.
- The launcher embeds the additional safe-blit helper. Build, payload,
  packaged links, CRC, and SHA256 checks cover the updated distribution.

On 2026-11-01, the user confirmed that fast-forward with a moving ship worked
in game after applying the fix. This gameplay scenario is now verified.
Cross-machine bootstrap testing remains outstanding. Support is limited to the stated English Steam
build and primary display at 3440x1440. The GitHub repository remains private.
Crash dumps and extracted proprietary memory are not distributed.
