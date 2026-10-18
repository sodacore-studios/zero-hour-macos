# Verification status

## Performance

The user reported successful performance testing and approved publication on 2026-10-21. The exact display mode, duration and multiplayer conditions of that acceptance were not specified. This is acceptance of the performance preview, not a claim that every test matrix case was executed.

Controlled tests on the local Apple Silicon Mac restored median simulation speed from 0.5x to 1.0x at a 30 FPS render ceiling. The new scheduler also sustained 60 logic ticks per second at 15 render FPS. Thirty-six paired simulation checksum checkpoints matched through frame 21,600. The final signed preview completed a full 28:35 replay headlessly in 01:44 with exit code zero and no reported CRC mismatch. See `performance-results.json`.

## Updater and delivery

Deterministic Swift tests cover semantic version ordering, invalid versions, signature/hash rejection, OS gating, URL origin policy, failed staging validation, failed launch rollback and successful app replacement. C++ tests cover fixed-step pacing, irregular render intervals, suspend/transition limits, network deadlines and completed-tick performance sampling. These tests operate in isolated temporary directories.

The release workflow builds ARM64 binaries and publishes coverage reports. Package validation checks code signatures, architecture, dependency paths, checksums and absence of original game archives. Actual GitHub run results and release artifacts are the delivery evidence, not commit dates.

## Remaining limits

- The user previously confirmed stable multiplayer, but no new two-Mac live match with the final updater release is claimed.
- GitHub publication does not change the live server's allowed binary CRC.
- Apple Developer ID signing/notarization and all supported macOS versions have not been validated.
- The original automated render benchmarks used a 1728 × 882 target with audio bypassed on a locked desktop. They do not establish 5120 × 1440 GPU frame rates or new audio behavior.
- The update installer tests verify launch-request rollback; they cannot guarantee that a future version will not crash later during play.
