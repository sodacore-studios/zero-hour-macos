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
