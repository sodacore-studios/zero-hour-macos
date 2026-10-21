# Build and release

Supported build targets are native macOS ARM64 (deployment target 13.3) and Windows x86. See [Windows build and operation](WINDOWS.md) for Visual Studio requirements and [verification](VERIFICATION.md) for the tested hardware matrix. The following commands build the macOS target. Required developer tools: Xcode/Command Line Tools, CMake 3.25+, Ninja, Python 3, and the build tools required by dependency recipes. GitHub Actions uses macos-15 ARM64 runners. End users download binaries instead of compiling.

```sh
cmake --preset macos -S work/zero-hour-macos -DCMAKE_OSX_ARCHITECTURES=arm64 -DCMAKE_OSX_DEPLOYMENT_TARGET=13.3
cmake --build work/zero-hour-macos/build/macos --target GeneralsOnlineZH --parallel 3
bash work/performance-tests/run.sh /tmp/pacing-coverage
bash work/update-tests/run.sh /tmp/updater-coverage
bash work/renderer-tests/run-buffers.sh /tmp/renderer-coverage
bash work/input-tests/run.sh /tmp/input-coverage
python3 work/release/package.py --version 0.3.0 --key /private/path/to/update-signing.key
```

The package script compiles the launcher/helper, bundles the native engine and dependency licenses, signs the app ad hoc, verifies signatures/architecture/dependency paths, generates `Version.json`, ZIP, DMG, SHA-256 sums, a signed updater manifest and corresponding source archive. It refuses to package original BIG archives or Abrams artifacts. Keep the signing seed outside the checkout. The source archive includes fetched dependency sources used by the build; their recipes remain in the repository.

## GitHub Actions

`Build and release` runs deterministic simulation, network, input and terrain tests on Linux; launcher/updater and renderer-buffer tests on macOS; server compatibility/controller tests on Linux; and native core checks on Windows. Coverage reports are uploaded as artifacts. The macOS engine build follows the core, launcher and server checks; the Windows job builds and packages its x86 client. `required-checks` requires every test job and both platform builds to succeed. Main builds increment the 0.3 release line, package/sign, and publish a version tag and downloadable artifacts only after successful tests and build. Release notes come from `docs/RELEASE_NOTES.md` and must be maintained when behavior changes.

Main is protected by the required `required-checks` aggregate, including administrator enforcement. The release job also depends on that aggregate independently of branch protection. Actual protection state is checked during publication. Branch builds provide Windows packages and a macOS engine test artifact; only main builds publish the complete launcher packages to the stable release channel.

Automated releases require the repository Actions secret `UPDATE_SIGNING_KEY`. The checked-in public key must match. Builds and publication timestamps record actual execution time. User-authored commits made for this delivery use the preceding Sunday in Europe/Berlin, retaining local time of day, as requested; those Git timestamps are metadata, not evidence of when work occurred. Existing history is not rewritten.

Each rebuild may change the binary CRC even without gameplay changes. Operators must use the release-specific `Version.json` for server compatibility. Publishing does not deploy the server.
