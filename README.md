# Zero Hour for macOS and Windows · sodacore studios

Native Apple Silicon and Windows x86 editions of Command & Conquer: Generals – Zero Hour, with platform launchers and a self-hosted invitation-based multiplayer service. Shared camera, input and pacing improvements keep simulation time independent of rendering speed. macOS uses Metal; Windows uses Direct3D 8.

Download the latest **macOS-arm64 DMG** or **Windows-x86 ZIP** from [Releases](https://github.com/sodacore-studios/zero-hour-macos/releases/latest). No compilation is required. Public releases require no GitHub account or token. Original game files are not distributed on GitHub; use your own installed Generals and Zero Hour files.

## Features

- Fixed-step simulation: the controlled 30-render-FPS test advances at 60 logic ticks per second, restoring normal game-clock speed.
- Resolution dropdowns, windowed/fullscreen modes, WASD and arrow camera controls, extended camera zoom and ultrawide resolutions up to 7680 × 2160. Command–Return toggles fullscreen on macOS; Windows fullscreen modes depend on the graphics adapter.
- Configurable private server and relay addresses, with invitation-based multiplayer.
- Automatic macOS GitHub updates with Ed25519 signature and SHA-256 validation; optional Keychain authentication for private deployments. Installation waits until the game exits. Windows uses manual ZIP updates.
- Separate development state for the Abrams prototype; it is not part of this release.

## Documentation

| Document | Contents |
| --- | --- |
| [Installation and operation](docs/INSTALLATION.md) | Download, game data, controls, updates and rollback |
| [Windows installation and operation](docs/WINDOWS.md) | Launcher, game folders, controls, updates and troubleshooting |
| [Build and delivery](docs/BUILD.md) | Native build, CI, release artifacts and versioning |
| [Updates](docs/UPDATES.md) | Authentication, signature trust, installation and troubleshooting |
| [Performance](docs/PERFORMANCE.md) | Measurements, scheduling design and limits |
| [Verification](docs/VERIFICATION.md) | Actual tests, user acceptance and remaining validation |
| [Server operations](docs/SERVER.md) | Service, relay, backup, migration and version compatibility |
| [Origins and licensing](docs/HERKUNFT.md) | Upstream source and attribution |
| [Release notes](docs/RELEASE_NOTES.md) | Changes in this release line |

## Support boundaries

macOS packages target Apple Silicon and macOS 13.3 or later. They are ad-hoc signed; update manifests are Ed25519 signed. Apple Developer ID signing and notarization are not configured. Windows packages target x86 on Intel/AMD Windows 10/11 and are not Authenticode-signed. Native Windows 10 gameplay and a controlled Mac-to-Windows match through a forced public TURN relay passed. Windows 11, Windows ARM, Windows audio and separate-ISP gameplay are not claimed as verified. See [Windows](docs/WINDOWS.md) and the [verification matrix](docs/VERIFICATION.md) for exact limits.

Players need builds that the private server explicitly admits as simulation-compatible. macOS `Version.json` and `Windows-Version.json` contain the actual binary CRCs; publication alone does not update server admission. The documented replay and live-match results apply to the recorded test binaries. Release rebuilds have their own hashes and must be enrolled by the server operator.

Original assets, credentials, invitation codes, private server addresses, replays and player profiles are excluded. The engine derives from OKJID/GameClient and the server from GeneralsOnlineDevelopmentTeam/Services. Original notices and license texts are retained.
