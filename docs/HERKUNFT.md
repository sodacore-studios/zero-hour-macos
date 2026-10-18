# Origins and licenses

| Component | Upstream baseline |
| --- | --- |
| Engine and macOS port | https://github.com/OKJID/GameClient, `macos-port`, commit `506f1e45b806ae5bdfcc67e8bda54b1ae44a35f2` |
| Web service | https://github.com/GeneralsOnlineDevelopmentTeam/Services, commit `85dfbc7ac6f9e336f5d18939f3cd1eb20663b6ea` |

Local changes cover private guest access, configurable endpoints, native launcher/updater, fullscreen/input/resolutions, HUD/terrain/camera fixes, simulation scheduling and branding. Upstream READMEs are retained as provenance; their status/download claims describe the upstream projects rather than this edition.

The [engine license](../work/zero-hour-macos/LICENSE.md) is GPL-3.0-or-later; the [service license](../work/zero-hour-services/LICENSE) is AGPL-3.0-or-later. Component and dependency notices remain authoritative. No replacement umbrella license is imposed. Electronic Arts, TheSuperHackers, GeneralsOnline and OKJID attribution is retained. Customized branding does not imply sole authorship of the original engine.

Commercial game assets are not covered by those source licenses and are excluded from GitHub artifacts. The user-supplied logo is included in the launcher. Dependencies retain their own licenses and source notices.

This repository contains source snapshots, not imported upstream histories. The original uninitialized gitlinks `Dependencies/fdlibm-deterministic` and `GeneralsReplays` were not converted into files; they were not initialized in the local macOS build. Other platforms/replay datasets may require additional upstream setup. CMake fetches macOS dependencies. `dependencies.json` records the local baseline. The GameNetworkingSockets dependency is pinned to that tested commit for this release line. Toolchain differences can still change binary bytes and multiplayer CRC values.
