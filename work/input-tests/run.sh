#!/usr/bin/env bash
set -euo pipefail
root="$(cd "$(dirname "$0")/../.." && pwd)"
output="${1:-$(mktemp -d)}"
mkdir -p "$output"
compiler=(clang++)
profdata=(llvm-profdata)
cov=(llvm-cov)
if [[ "$(uname -s)" == Darwin ]]; then
  compiler=(xcrun clang++)
  profdata=(xcrun llvm-profdata)
  cov=(xcrun llvm-cov)
fi
header="$root/work/zero-hour-macos/Core/GameEngine/Include/Common"
"${compiler[@]}" -std=c++17 -Wall -Wextra -Werror -fprofile-instr-generate -fcoverage-mapping \
  -I"$header" "$root/work/input-tests/events.cpp" -o "$output/input-tests"
LLVM_PROFILE_FILE="$output/input.profraw" "$output/input-tests"
"${profdata[@]}" merge -sparse "$output/input.profraw" -o "$output/input.profdata"
"${cov[@]}" show "$output/input-tests" -instr-profile="$output/input.profdata" \
  -format=html -output-dir="$output/html" "$header/InputEventBudget.h"
