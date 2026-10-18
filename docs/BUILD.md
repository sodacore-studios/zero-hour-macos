# Build and release

Supported client: native macOS ARM64, deployment target 13.3. Required developer tools: Xcode/Command Line Tools, CMake 3.25+, Ninja, Python 3, and the build tools required by dependency recipes. GitHub Actions uses macos-15 ARM64 runners. End users download binaries instead of compiling.

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

`Build and release` runs deterministic simulation/terrain tests on Linux and launcher/updater and deterministic renderer-buffer tests on macOS for pushes and pull requests. Coverage HTML is uploaded as artifacts. `required-checks` aggregates both suites. Native builds depend on that aggregate. Main builds increment the 0.3 release line, package/sign, and publish a version tag and downloadable artifacts only after successful tests and build. Release notes come from `docs/RELEASE_NOTES.md` and must be maintained when behavior changes.

The previous private repository could not enable branch protection under its plan. For public delivery, configure main to require `required-checks` and restrict updates to reviewed, passing changes. Release jobs always depend on the aggregate tests and successful native build, independently of repository protection. Actual branch-protection state is verified during publication.

Automated releases require the repository Actions secret `UPDATE_SIGNING_KEY`. The checked-in public key must match. Builds and publication timestamps record actual execution time. User-authored commits made for this delivery use the preceding Sunday in Europe/Berlin, retaining local time of day, as requested; those Git timestamps are metadata, not evidence of when work occurred. Existing history is not rewritten.

Each rebuild may change the binary CRC even without gameplay changes. Operators must use the release-specific `Version.json` for server compatibility. Publishing does not deploy the server.
