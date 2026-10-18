#!/usr/bin/env bash
set -euo pipefail
root="$(cd "$(dirname "$0")/../.." && pwd)"
output="${1:-$(mktemp -d)}"
mkdir -p "$output"
platform="$root/work/zero-hour-macos/Platform/MacOS"
xcrun clang++ -std=c++17 -fobjc-arc -fprofile-instr-generate -fcoverage-mapping \
  -I"$platform/Include" -I"$platform/Source/Metal" \
  -I"$root/work/zero-hour-macos/Dependencies/Utility" \
  -include "$platform/Include/metal_prefix.h" \
  "$root/work/renderer-tests/buffer-lifetime.mm" \
  "$platform/Source/Metal/MetalVertexBuffer8.mm" \
  "$platform/Source/Metal/MetalIndexBuffer8.mm" \
  -framework Foundation -framework Metal -framework AppKit -framework MetalKit \
  -o "$output/buffer-lifetime"
LLVM_PROFILE_FILE="$output/buffers.profraw" "$output/buffer-lifetime" "${2:---cpu}"
xcrun llvm-profdata merge -sparse "$output/buffers.profraw" -o "$output/buffers.profdata"
xcrun llvm-cov show "$output/buffer-lifetime" -instr-profile="$output/buffers.profdata" \
  -format=html -output-dir="$output/html" \
  "$platform/Source/Metal/MetalVertexBuffer8.mm" "$platform/Source/Metal/MetalIndexBuffer8.mm"
