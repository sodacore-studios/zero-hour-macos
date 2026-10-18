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
