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
  "$root/work/zero-hour-macos/Core/GameEngine/Include/Common/FixedStepBudget.h" \
  "$root/work/zero-hour-macos/Core/GameEngine/Include/Common/MatchClock.h"
"${cov[@]}" show "$output/fixed-step-tests" -instr-profile="$output/coverage.profdata" \
  -format=html -output-dir="$output/html" \
  "$root/work/zero-hour-macos/Core/GameEngine/Include/Common/FixedStepBudget.h" \
  "$root/work/zero-hour-macos/Core/GameEngine/Include/Common/MatchClock.h"

# Compile the real shared pacing implementation; only external game/platform services are stubbed.
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

# Exercise production network frame advancement with no render-generated messages.
python3 "$root/work/performance-tests/network_frame_test.py" "$output/network-frame.cpp"
"${compiler[@]}" -std=c++17 -Wall -Wextra -Werror -D__APPLE__ -fprofile-instr-generate -fcoverage-mapping \
  -DRETAIL_COMPATIBLE_NETWORKING=0 "$output/network-frame.cpp" -o "$output/network-frame-tests"
LLVM_PROFILE_FILE="$output/network-frame.profraw" "$output/network-frame-tests"
"${profdata[@]}" merge -sparse "$output/network-frame.profraw" -o "$output/network-frame.profdata"
"${cov[@]}" show "$output/network-frame-tests" -instr-profile="$output/network-frame.profdata" \
  -format=html -output-dir="$output/html/network-frame" "$output/network-frame.cpp"

# Exercise the actual latency estimator, including disabled debug logging.
python3 "$root/work/performance-tests/network_latency_test.py" "$output/network-latency.cpp"
"${compiler[@]}" -std=c++20 -Wall -Wextra -Werror -fprofile-instr-generate -fcoverage-mapping \
  "$output/network-latency.cpp" -o "$output/network-latency-tests"
LLVM_PROFILE_FILE="$output/network-latency.profraw" "$output/network-latency-tests"
"${profdata[@]}" merge -sparse "$output/network-latency.profraw" -o "$output/network-latency.profdata"
"${cov[@]}" show "$output/network-latency-tests" -instr-profile="$output/network-latency.profdata" \
  -format=html -output-dir="$output/html/network-latency" "$output/network-latency.cpp"

# An incoming peer can arrive before the outgoing connection is registered.
python3 "$root/work/performance-tests/incoming_connection_test.py" "$output/incoming-connection.cpp"
"${compiler[@]}" -std=c++17 -Wall -Wextra -Werror -fprofile-instr-generate -fcoverage-mapping \
  "$output/incoming-connection.cpp" -o "$output/incoming-connection-tests"
LLVM_PROFILE_FILE="$output/incoming-connection.profraw" "$output/incoming-connection-tests"
"${profdata[@]}" merge -sparse "$output/incoming-connection.profraw" -o "$output/incoming-connection.profdata"
"${cov[@]}" show "$output/incoming-connection-tests" -instr-profile="$output/incoming-connection.profdata" \
  -format=html -output-dir="$output/html/incoming-connection" "$output/incoming-connection.cpp"

# Diagnostic flags must not change the live protocol cadence.
for retail in 0 1; do
  for diagnostic in 0 1; do
    flags=(-D__APPLE__ "-DRETAIL_COMPATIBLE_NETWORKING=$retail")
    if [[ "$diagnostic" == 1 ]]; then flags+=(-DDEBUG_CRC); fi
    "${compiler[@]}" -std=c++17 -Wall -Wextra -Werror "${flags[@]}" \
      "$output/network-frame.cpp" -o "$output/network-cadence-$retail-$diagnostic"
    "$output/network-cadence-$retail-$diagnostic"
  done
done
