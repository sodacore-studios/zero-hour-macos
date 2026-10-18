## Performance and automatic updates

- Keep game simulation at its fixed 60 Hz rate when rendering falls below 60 FPS. The controlled 30 FPS case improves from half speed to normal game-clock speed; this does not claim doubled GPU frame rate.
- Preserve network command readiness, simulation ordering and CRC propagation during catch-up. Measure network performance from completed simulation ticks rather than render FPS.
- Include the camera terrain-ray fix and existing fullscreen, WASD and ultrawide options.
- Add automatic GitHub release updates with optional Keychain authentication, Ed25519 manifests, archive checksums, idle-only installation and recoverable app backups.
- Include deterministic tests, coverage artifacts, native ARM64 binaries and corresponding sources. The Abrams prototype remains separate.

The user accepted the performance preview on 2026-10-21. Automated replay checks and scheduling tests pass; see `docs/PERFORMANCE.md` and `docs/VERIFICATION.md` for precise scope. The new updater does not change gameplay code. A fresh two-Mac match with the final release binary is not claimed.

Install the ARM64 DMG once to gain the updater. Original game files are required and excluded from downloads. Public GitHub downloads and automatic updates need no account or token. Automatic updates can be configured under Zero Hour → Updates. All players and the private server's accepted client CRC must be coordinated using `Version.json` before online play. The live server is not changed by publication.

Packages are ad-hoc signed, not Apple-notarized. macOS 13.3 is the deployment target; older OS/hardware behavior beyond the documented tests remains unverified.
