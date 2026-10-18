# Input scheduling regression

Run `bash work/input-tests/run.sh /tmp/zero-hour-input-tests` on macOS or Linux
with Clang and LLVM tools. The suite uses the production AppKit event budget in
a deterministic, asset-free continuous-input simulation. It checks that a long
queue yields to rendering without dropping/reordering events, that expensive
handlers yield by elapsed time, and that the millisecond clock may wrap or jump.
Coverage HTML is produced in the output directory and published by core CI.

The macOS engine services at most 128 events or 4 ms of event work before returning
to the frame loop; at least one event is allowed to ensure progress. Window updates
run once after the batch. This bounds the outer pump, not the duration of a single
AppKit handler. The selection translator also consumes current left-drag positions
instead of relying solely on the previous-frame periodic position message.

These tests do not simulate AppKit itself or establish visible drag-rectangle
behavior. The full-game moving drag, right-click orders and normal menu interaction
are interactive checks. The user accepted continuous drag selection and right-click controls on 2026-10-21; the exact map and test duration were not specified.
