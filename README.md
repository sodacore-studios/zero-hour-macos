# Zero Hour for Apple Silicon · sodacore studios

Native ARM64 macOS edition of Command & Conquer: Generals – Zero Hour, with a Metal renderer, a native launcher and a self-hosted invitation-based multiplayer service. The performance update keeps simulation time independent of rendering speed. The user accepted the performance preview on 2026-10-21.

Download the latest **macOS-arm64 DMG** from [Releases](https://github.com/sodacore-studios/zero-hour-macos/releases/latest). No compilation is required. Public releases require no GitHub account or token. Original game files are not distributed on GitHub; use your own installed Generals and Zero Hour files.

## Features

- Fixed-step simulation: the controlled 30-render-FPS test advances at 60 logic ticks per second, restoring normal game-clock speed.
- Fullscreen/window toggle with Command–Return, WASD and arrow camera controls, extended camera zoom and ultrawide resolutions up to 7680 × 2160.
- Configurable private server and relay addresses, with invitation-based multiplayer.
- Automatic GitHub updates, with optional Keychain authentication for private deployments, with Ed25519 signature and SHA-256 validation. Installation waits until the game exits.
- Separate development state for the Abrams prototype; it is not part of this release.

## Documentation

| Document | Contents |
| --- | --- |
| [Installation and operation](docs/INSTALLATION.md) | Download, game data, controls, updates and rollback |
| [Build and delivery](docs/BUILD.md) | Native build, CI, release artifacts and versioning |
| [Updates](docs/UPDATES.md) | Authentication, signature trust, installation and troubleshooting |
| [Performance](docs/PERFORMANCE.md) | Measurements, scheduling design and limits |
| [Verification](docs/VERIFICATION.md) | Actual tests, user acceptance and remaining validation |
| [Server operations](docs/SERVER.md) | Service, relay, backup, migration and version compatibility |
| [Origins and licensing](docs/HERKUNFT.md) | Upstream source and attribution |
| [Release notes](docs/RELEASE_NOTES.md) | Changes in this release line |

## Support boundaries

Apple Silicon only. The deployment target is macOS 13.3, which is not a claim that every supported OS version was physically tested. Packages are ad-hoc signed and update manifests are Ed25519 signed; Apple Developer ID signing and notarization are not configured. The Windows x86 candidate passed native Windows 10 gameplay and a controlled Mac-to-Windows match through a forced public TURN relay. See [Windows](docs/WINDOWS.md) and the [verification matrix](docs/VERIFICATION.md) for installation and exact limits.

All players need matching engine builds. `Version.json` contains the binary CRC required by the private service. Publishing a GitHub release does not modify the live server's accepted CRC. The stable build was previously played in multiplayer; the user's performance approval does not specify a new two-Mac multiplayer test of the final updater build.

Original assets, credentials, invitation codes, private server addresses, replays and player profiles are excluded. The engine derives from OKJID/GameClient and the server from GeneralsOnlineDevelopmentTeam/Services. Original notices and license texts are retained.
