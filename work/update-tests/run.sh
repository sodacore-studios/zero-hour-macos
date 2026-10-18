#!/usr/bin/env bash
set -euo pipefail
root="$(cd "$(dirname "$0")/../.." && pwd)"
output="${1:-$(mktemp -d)}"
mkdir -p "$output"
launcher="$root/work/zero-hour-macos/Platform/MacOS/PrivateLauncher"
xcrun swiftc -Onone -g -profile-generate -profile-coverage-mapping -module-cache-path "$output/modules" \
  "$launcher/UpdateCore.swift" "$root/work/update-tests/Tests.swift" -o "$output/update-tests"
LLVM_PROFILE_FILE="$output/update.profraw" "$output/update-tests"
xcrun llvm-profdata merge -sparse "$output/update.profraw" -o "$output/update.profdata"
xcrun llvm-cov report "$output/update-tests" -instr-profile="$output/update.profdata" "$launcher/UpdateCore.swift"
xcrun llvm-cov show "$output/update-tests" -instr-profile="$output/update.profdata" \
  -format=html -output-dir="$output/html" "$launcher/UpdateCore.swift"
xcrun swiftc -O -target arm64-apple-macos13.3 -module-cache-path "$output/modules" \
  "$launcher/Configuration.swift" "$launcher/UpdateCore.swift" "$launcher/Updater.swift" "$launcher/main.swift" -o "$output/ZeroHourLauncher"
xcrun swiftc -O -target arm64-apple-macos13.3 -module-cache-path "$output/modules" \
  "$launcher/UpdateCore.swift" "$launcher/UpdateHelper.swift" -o "$output/ZeroHourUpdateHelper"
xcrun swiftc -module-cache-path "$output/modules" "$launcher/Configuration.swift" "$root/work/launcher-tests/Tests.swift" -o "$output/launcher-tests"
"$output/launcher-tests"
