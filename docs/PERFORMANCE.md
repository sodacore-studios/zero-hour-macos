# Simulation pacing on Apple Silicon

The original macOS loop executes at most one logic tick per rendered frame. This build uses 60 fixed logic ticks per game second. At 30 rendered frames per second, the old loop therefore advances the clock and units at half normal speed. Smooth camera movement does not prove that the simulation is running in real time.

The performance candidate separates simulation scheduling from rendering:

- Single-player and replay scheduling accumulate monotonic elapsed time and consume fixed ticks at the configured simulation rate, normally 60 Hz.
- Network performance history measures completed logic ticks per second, independently of render FPS, so the run-ahead estimator does not mistake slower rendering for slower simulation.
- Network games retain command readiness as a prerequisite for every tick. Overdue network deadlines survive ordinary slow render frames instead of being discarded immediately.
- Each additional tick propagates newly generated messages, including CRC messages, before processing the next command frame. Omitting this propagation causes replay CRC divergence; the candidate includes it.
- Catch-up is bounded to eight ticks per render update. Long suspensions over 250 ms discard clock debt rather than fast-forwarding through sleep or loading. Pauses, menus, transitions and missing network commands stop catch-up.
- Unit statistics, damage, movement speeds, random-number generation, protocol versions and fixed simulation step size are unchanged.

## Validation

Measured on 2026-10-21: at a 30 FPS render ceiling, median simulation rate increases from 30 to 60 ticks per second (0.5x to 1.0x game-clock speed). At 15 rendered FPS the candidate also maintains a median 60 logic ticks per second. The paired graphical replay runs match at 36 checksum checkpoints through frame 21,600. The first signed candidate completes the full 28:35 replay in 2:13 headlessly, exits with status 0 and reports no CRC mismatch.

These measurements exclude startup samples through simulation frame 600. The headless throughput number is a validation-runtime measurement, not a predicted interactive frame rate.

The controlled replay benchmark compares an explicit 30 Hz render ceiling with the old and new schedulers. It is a simulation-speed test, not a claim that GPU rendering throughput doubled. Tests run on the local Apple Silicon Mac with a 1728 x 882 render target; the locked desktop prevents a fresh visual or two-Mac interaction test. Audio is disabled in the benchmark because the existing AVAudio path fails while the desktop is locked.

Deterministic standalone tests cover one hour at 15, 20, 30, 60, 120, 144 and 240 render Hz, irregular frame intervals, invalid time inputs, suspension handling, bounded catch-up, and network deadlines. Coverage is published by the prepared `Core checks` workflow. Its `required-checks` job is the intended aggregate branch-protection check. The workflow has not yet been pushed or run on GitHub; branch protection and automatic binary releases are not claimed as configured by this local change.

Real-engine measurements and replay checksums are recorded in `performance-results.json`. Logs and the user's replay remain private and are not repository artifacts. The recorded match is also checked with the engine's headless replay validator. Headless validation alone does not exercise the render scheduling loop or a live network connection.

A fresh Mac-to-Mac multiplayer match, rendering at the user's 5120 x 1440 desktop, camera interaction and audio remain required before replacing the installed stable app or changing the live service's accepted client CRC. The user previously confirmed multiplayer on the stable build; this is not evidence for the new candidate.

## Diagnostic controls

Environment variables are intended for developers and do not change launcher defaults:

- `ZERO_HOUR_PERF=1`: emit render rate, logic rate, clock speed ratio, pause/freeze and replay mismatch status every five seconds.
- `ZERO_HOUR_PERF_RENDER_HZ=30`: impose a reproducible render ceiling (5–240 Hz).
- `ZERO_HOUR_PERF_CRC=1`: report simulation checksums every 600 frames.
- `ZERO_HOUR_PERF_LEGACY_PACING=1`: use the previous regular-game render-bound scheduler for comparisons. This switch does not revert the network deadline implementation.
- `ZERO_HOUR_DISABLE_AUDIO=1`: bypass audio initialization and event playback for unattended benchmarks.

Do not set these variables for ordinary play. Replays and diagnostic logs may include player names; keep them out of published artifacts.

## Installation and rollback

The local performance package is a separate preview. Keep `Zero Hour.app` installed and open `Zero Hour Performance.app` for single-player evaluation. Original game files are reused in the locally assembled complete package. Settings and saves use the existing user-data directory; back up important saves before evaluating a preview. To roll back, close the preview and reopen the stable app. No server migration is performed by the package.

The private service currently accepts one binary CRC. The preview is deliberately not enabled on the live service before multiplayer validation; a changed executable must not be described as online-ready merely because it builds. Both Macs will need the same tested version for the eventual rollout.

Final package verification (build 20261021.2): the entire 28:35 replay completed headlessly in 01:44, with exit status 0 and no reported CRC mismatch. The signed engine CRC32 is 60440466. The updated network rate sampler passes deterministic tests at 15, 30, 60 and 144 rendered FPS; live multiplayer remains unverified.

## Publication acceptance — 2026-10-21

After the preview measurements above, the user reported that the performance test passed and approved GitHub publication. Display mode, duration and live multiplayer conditions were not specified. The release adds a launcher updater while retaining the accepted simulation changes. Earlier pending-test statements above record the automated preview stage; see VERIFICATION.md for the current acceptance boundary and BUILD.md for the delivery pipeline.

## Skirmish speed selection

The original slider uses a 30-based scale: 15 means 0.5x, 30 means 1x, and 60 means 2x. The Apple Silicon engine converts these values to 30, 60 and 120 fixed logic ticks per wall-clock second respectively. Simulation step size and game rules remain unchanged. The `--` position requests unrestricted local speed, subject to the existing eight-tick budget per render update. It is intended for fast-forwarding; its achieved speed depends on hardware and rendering.

Version 0.3.0 incorrectly sent the slider value only to the render limiter. The corrected startup path stores a separate local match rate, and the fixed-step scheduler queries the same effective rate as the pause and network logic. Explicit local time-scale shortcuts still take precedence; new-game preparation clears previous local speed overrides. Network matches always use the network rate. Save files do not persist the local pacing preference; a loaded game starts at normal speed.

Regression tests compile the production `FramePacer.cpp` with isolated substitutes for platform timing and game services. They verify every slider value from 15 through 60 over one simulated minute at 15, 30, 60 and 144 render FPS, plus unlimited, pause/halt, network precedence and reset behavior. These deterministic tests do not substitute for an interactive UI test.
