# Verification status

## Performance

The user reported successful performance testing and approved publication on 2026-10-21. The exact display mode, duration and multiplayer conditions of that acceptance were not specified. This is acceptance of the performance preview, not a claim that every test matrix case was executed.

Controlled tests on the local Apple Silicon Mac restored median simulation speed from 0.5x to 1.0x at a 30 FPS render ceiling. The new scheduler also sustained 60 logic ticks per second at 15 render FPS. Thirty-six paired simulation checksum checkpoints matched through frame 21,600. The final signed preview completed a full 28:35 replay headlessly in 01:44 with exit code zero and no reported CRC mismatch. See `performance-results.json`.

## Updater and delivery

Deterministic Swift tests cover semantic version ordering, invalid versions, signature/hash rejection, OS gating, URL origin policy, failed staging validation, failed launch rollback and successful app replacement. C++ tests cover fixed-step pacing, irregular render intervals, suspend/transition limits, network deadlines and completed-tick performance sampling. These tests operate in isolated temporary directories.

The release workflow builds ARM64 binaries and publishes coverage reports. Package validation checks code signatures, architecture, dependency paths, checksums and absence of original game archives. Actual GitHub run results and release artifacts are the delivery evidence, not commit dates.

## Terrain, selection and mouse controls

On 2026-10-21, local tests reproduced two defects in the production Metal code:
ordinary writes changed shared buffers already referenced by queued GPU work, and
disabled texture-stage projector state discarded valid UI fragments. The original
buffer implementation failed delayed GPU readback for vertex, 16-bit index and
32-bit index buffers; all pass after copy-on-write. Both original disabled-stage
shader regression cases failed; all ten shader cases pass with active-stage-only
clipping. An asset-free in-memory device suite adds 55 deterministic assertions
against the actual production buffer classes, with LLVM coverage for CI.

The user confirmed that terrain grid lines were gone. The follow-up candidate
also updated selection hints from current drag messages, bounded AppKit input work
between frames and added a default-on launcher option for right-click orders.
On 2026-10-21 the user confirmed that both continuous drag selection and the new
mouse controls worked correctly and approved publication. The local candidate's
engine SHA-256 was `f36e5a01ab8a412c8632e1c06900f710e494c2adaf36d452986a3e49c516e174`.
The precise map, test duration and opponent configuration were not specified.

Deterministic event fairness and launcher migration/opt-out tests pass. See
`work/renderer-tests/README.md` and `work/input-tests/README.md` for commands and
scope. CI rebuilds and packages the release independently; local user acceptance
does not establish a new two-Mac match or performance benchmark of that rebuilt
binary. The live server keeps its existing accepted checksum until coordinated.

## Remaining limits

- The user previously confirmed stable multiplayer, but no new two-Mac live match with the final updater release is claimed.
- GitHub publication does not change the live server's allowed binary CRC.
- Apple Developer ID signing/notarization and all supported macOS versions have not been validated.
- The original automated render benchmarks used a 1728 × 882 target with audio bypassed on a locked desktop. They do not establish 5120 × 1440 GPU frame rates or new audio behavior.
- The update installer tests verify launch-request rollback; they cannot guarantee that a future version will not crash later during play.

## Windows development candidate (2026-10-21)

- The known Windows test device was identified over SSH before changes: Windows 10
  build 19045, Intel HD Graphics and AMD Radeon R5 M255. Build Tools 2022 were
  installed in a separate test directory without rebooting the device.
- The shared pacing, match-clock and input-budget suites pass locally and under
  native MSVC on the Windows test device. GitHub also passes the Windows LLVM
  checks, coverage export and PowerShell launcher validation.
- The private-server compatibility policy tests pass. The full .NET 10 Release
  server build succeeds with zero warnings and errors.
- Windows x86 compilation and packaging passed in GitHub run 39613762580.
  Hardware startup then exposed upstream DLLs requiring debug CRT files and a
  missing Sentry runtime. That package is not a verified playable release. The
  replacement builds networking from pinned source with Release runtimes and
  checks the package dependency closure before upload. The replacement package
  passed all aggregate checks in run 39622544361 and opened a native Direct3D 8
  skirmish on the Windows test device.
- An isolated staging service on the existing test server passed invitation
  rejection, two authenticated WebSocket sessions, protected lobby create/join,
  wrong-password rejection and TURN credential issuance. A public TURN probe
  exchanged ten exact payloads bidirectionally and rejected an excluded peer.
  The native macOS candidate also logged in and created a lobby in its actual UI.
  These protocol tests do not establish a completed game or two separate Internet
  access networks. The live service has not been changed.
- The local candidates completed the same full 28:35 replay with exit zero on
  both platforms: macOS in 01:45 and Windows in 04:49. All 1,716 simulation CRC
  checkpoints (every 60 frames through frame 102,900) matched exactly. This tests
  replay determinism; a complete live Mac-to-Windows match remains pending.
  The original INIZH, MapsZH and GensecZH archive hashes also match.
- The replay comparison identified and fixed a platform-specific pathfinding
  allocation rule: macOS-only compatibility definitions are now shared with
  Windows. Before the fix, a frame-240 state dump differed in an allocation
  counter. After the fix, the full replay matched without disabling CRC checks.
- Windows replay testing used the interactive desktop. Starting the legacy Miles
  audio backend in the SSH session failed during initialization. Audio output
  itself has not been verified.
- The Windows launcher was opened on the test desktop through RustDesk. It
  detected both EA game folders and rejected an empty player name. Its process
  exit reporting also reproduced the missing-DLL startup failure above.
- The Windows resolution dropdown was opened and used through RustDesk. Selecting
  1280 x 800 wrote `Resolution = 1280 800` and opened an actual 1280 x 800 game
  viewport. A skirmish rendered, WASD moved the camera in both directions, left
  click selected a construction dozer, and a short right click moved it to the
  selected ground location. Command hotkey labels were visible. The subsequent
  local candidate opened the pause menu on Escape and closed normally through
  its window close button. These checks do
  not establish every resolution, GPU, audio device or a complete online game.
- The Windows launcher currently uses manual updates; macOS retains its signed
  automatic updater. Windows ARM and Windows 11 hardware have not been tested.

The first native cross-platform online test connected and loaded the map, but
commands did not execute. Investigation found that network frame initialization
was tied to render-generated messages and could miss frame one during catch-up.
Frame bookkeeping now advances on every network update. A corrected native
match, actual command execution and relay-only gameplay are still pending.

The network-frame regression harness compiles the production update functions
with an empty render-message stream. The previous update fails the active-state
assertion; the corrected update passes start, delayed start, repeated frame and
leaving cases. Its coverage is included with the isolated pacing suite.
