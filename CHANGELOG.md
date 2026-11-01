# Changelog

## 1.1.0

- Add 1920x1080, 1920x1200, 2560x1080, and 2560x1440 profiles, automatically selected from the primary display.
- Generate profile-specific panels, top bars, overview maps, and configuration at 100% UI scale.
- Preserve native sea-map scrolling for the four narrower profiles; retain the verified 3440x1440 camera and fast-forward fix.
- Validate prepared assets against the selected profile and preserve the initial backup across profile switches.
- Add automated coverage for all five profiles. Gameplay validation of the four new profiles is pending.

﻿# Changelog

## 1.0.2

- Display the same README cover in the launcher, embedded in the standalone EXE.
- Fix the centered sea-map renderer passing a negative source X to the
  indexed-color blitter during fast-forward, causing an access violation.
- Preserve centering by drawing the neutral margin and clipped map as two
  valid source rectangles; other rendering requests retain their behavior.
- Add a regression test based on the captured crash rectangle, including
  vertical limits, destination coverage, stack balance, and saved registers.

## 1.0.1

- Rename the project to Patrician III Modern Resolutions.
- Update only the cover subtitle while retaining the existing illustration.
- Translate the launcher, documentation, scripts, and messages into English.
- Rename public launcher/script files and the distributable package.
- Preserve existing backup paths and remembered game-folder compatibility.
- Keep the verified 3440x1440 gameplay behavior unchanged.

## 1.0.0

- Add a standalone Windows launcher with embedded scripts, Steam-library
  discovery, folder selection, launch, restore, and operation status.
- Generate assets automatically from the user's own game files.
- Check the English Steam build and primary display at 3440x1440.
- Back up modified files without changing saves, executables, or archives.
- Include the verified resolution patch, non-repeating centered sea map,
  and correctly proportioned side-panel artwork.
- Add an illustrated README, original cover artwork, and development guide.
