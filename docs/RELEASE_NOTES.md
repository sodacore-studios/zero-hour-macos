## Windows and private cross-platform multiplayer candidate

- Extend the shared camera, WASD, right-click order, selection and fixed-step
  pacing improvements to the native Windows x86 build.
- Add a resolution dropdown and isolated-profile Windows launcher, build scripts, downloadable packaging
  and native Windows core checks with coverage.
- Validate private HTTPS/WSS connections against the Windows certificate store.
- Add explicit server admission for multiple binary CRCs with a shared simulation
  checksum for validated platform pairs; retain script and version checks.

- Fix incoming lobby-peer registration, empty-stream network startup and differing
  live checksum intervals across diagnostic builds.

Native Windows gameplay and a controlled Mac-host/Windows-guest match through a
forced public TURN relay passed: construction, movement, surrender and matching
result screens, with 12,655 identical CRC comparisons. Both devices used the same
Internet access network. A full 28:35 replay also matched all 1,716 checkpoints.
See `VERIFICATION.md` for exact scope and remaining limits. The production service
is unchanged and must admit the release binaries before online use. Windows
updates are manual; fullscreen modes depend on graphics-adapter support.

## Graphics and mouse controls

- Fix intermittent terrain grid lines during fast camera pans by preserving vertex and index buffers already referenced by queued Metal draws. Initial writes and no-overwrite appends keep their direct shared-memory path; no per-frame GPU wait is added.
- Keep the drag-selection rectangle visible and updating during mouse motion. Ignore inactive projector state in the UI shader, process current drag positions and bound OS input work between rendered frames.
- Enable **Left-click selects; right-click moves / attacks** by default in the launcher. Uncheck the option for classic controls. Right-button camera scrolling is disabled with the new controls; WASD, arrows and edge scrolling remain available.
- Preserve existing launcher settings when loading the new mouse-control option.
- Add deterministic input and renderer-buffer regression suites and coverage reports to the required CI checks.

The user confirmed that terrain lines were gone, then confirmed that continuous drag selection and the new mouse controls worked correctly in the local Apple Silicon candidate on 2026-10-21 and approved publication. Local Metal shader/readback tests, input scheduling tests, launcher migration tests, existing pacing/clock tests and terrain coverage checks passed. The CI release rebuild receives its own signature, checksum and packaging validation; a two-Mac match with that exact binary has not been verified.

Original game data is required and excluded from downloads. Packages support Apple Silicon and target macOS 13.3 or later; they are ad-hoc signed, not Apple-notarized. Automatic updates use signed manifests. All players and the private server's accepted client CRC must be coordinated using `Version.json` before online play; publication does not update the live server.
