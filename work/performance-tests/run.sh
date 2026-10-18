#!/usr/bin/env bash
set -euo pipefail
root="$(cd "$(dirname "$0")/../.." && pwd)"
output="${1:-$(mktemp -d)}"
mkdir -p "$output"
compiler=("${CXX:-clang++}")
profdata=(llvm-profdata)
cov=(llvm-cov)
if [[ "$(uname -s)" == Darwin ]]; then
  compiler=(xcrun "${CXX:-clang++}")
  profdata=(xcrun llvm-profdata)
  cov=(xcrun llvm-cov)
fi
"${compiler[@]}" -std=c++17 -Wall -Wextra -Werror -fprofile-instr-generate -fcoverage-mapping \
  -I "$root/work/zero-hour-macos/Core/GameEngine/Include" \
  "$root/work/performance-tests/fixed_step_test.cpp" -o "$output/fixed-step-tests"
LLVM_PROFILE_FILE="$output/coverage.profraw" "$output/fixed-step-tests"
"${profdata[@]}" merge -sparse "$output/coverage.profraw" -o "$output/coverage.profdata"
"${cov[@]}" report "$output/fixed-step-tests" -instr-profile="$output/coverage.profdata" \
  "$root/work/zero-hour-macos/Core/GameEngine/Include/Common/FixedStepBudget.h"
"${cov[@]}" show "$output/fixed-step-tests" -instr-profile="$output/coverage.profdata" \
  -format=html -output-dir="$output/html" \
  "$root/work/zero-hour-macos/Core/GameEngine/Include/Common/FixedStepBudget.h"

# Compile the real macOS pacing implementation; only external game/platform services are stubbed.
"${compiler[@]}" -std=c++17 -Wall -Wextra -Werror -D__APPLE__ -fprofile-instr-generate -fcoverage-mapping \
  -I "$root/work/performance-tests/stubs" \
  -I "$root/work/zero-hour-macos/Core/GameEngine/Include" \
  "$root/work/performance-tests/game_speed_test.cpp" \
  "$root/work/zero-hour-macos/Core/GameEngine/Source/Common/FramePacer.cpp" -o "$output/game-speed-tests"
LLVM_PROFILE_FILE="$output/game-speed.profraw" "$output/game-speed-tests"
"${profdata[@]}" merge -sparse "$output/game-speed.profraw" -o "$output/game-speed.profdata"
"${cov[@]}" show "$output/game-speed-tests" -instr-profile="$output/game-speed.profdata" \
  -format=html -output-dir="$output/html/game-speed" \
  "$root/work/zero-hour-macos/Core/GameEngine/Source/Common/FramePacer.cpp"
