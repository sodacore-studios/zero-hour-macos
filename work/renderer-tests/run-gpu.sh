#!/usr/bin/env bash
set -euo pipefail
root="$(cd "$(dirname "$0")/../.." && pwd)"
output="${1:-$(mktemp -d)}"
mkdir -p "$output"
xcrun clang++ -std=c++17 -Wall -Wextra -Werror -fobjc-arc \
  "$root/work/renderer-tests/projected-stages.mm" \
  -framework Foundation -framework Metal -o "$output/projected-stages"
"$output/projected-stages" \
  "$root/work/zero-hour-macos/Platform/MacOS/Source/Metal/MacOSShaders.metal" \
  "$root/work/renderer-tests/projected-stages.metal"
