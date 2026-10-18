# Metal renderer regression tests

Run on a Mac with a Metal GPU:

```sh
bash work/renderer-tests/run-gpu.sh /tmp/zero-hour-renderer-tests-output
```

The harness compiles the actual production `fragment_main`, appends synthetic vertex/uniform fixtures, renders to an 8 × 8 offscreen texture and checks every output pixel. It requires no original game assets, network service, user profile, or interactive window. An unavailable GPU is a failed/unperformed test, never a successful verification.

The cases cover solid selection geometry, disabled or uninitialized texture stages, termination of the stage cascade, unbound projected stages, negative nonprojected camera coordinates, and active projectors inside/outside their valid region.

Before the fix, stale projected coordinates in disabled stages discarded otherwise valid UI fragments. The original shader fails both disabled-stage regression cases; the corrected shader preserves the solid green geometry while still rejecting active out-of-range projected fragments.

These GPU checks currently run locally on Apple Silicon. They do not establish that every reported terrain seam is fixed. Final visual verification with the affected map, camera position and zoom remains necessary. Synthetic shader results are not a substitute for full-game confirmation. The user accepted the moving drag rectangle in the subsequent input-handling candidate on 2026-10-21.

## Queued buffer lifetime

```sh
# Deterministic CI tests, using production buffer classes and an in-memory device:
bash work/renderer-tests/run-buffers.sh /tmp/zero-hour-buffer-tests
# Actual Metal command-buffer readback, requiring an available GPU:
bash work/renderer-tests/run-buffers.sh /tmp/zero-hour-buffer-gpu --gpu
```

The CPU suite exercises both production buffer classes, 16-bit and 32-bit indices,
initial and deferred allocation, consecutive writes, partial-update preservation,
read-only/no-overwrite locks, discard, and allocation failure. It verifies that a
backing store already handed to a draw remains unchanged by an ordinary write.
CI runs these deterministic checks in the required launcher job and publishes an
LLVM coverage report. This suite does not claim to emulate Metal synchronization.

The GPU suite queues a real readback before a normal partial buffer update, then
submits it afterwards. All three buffer variants failed with the original code:
the GPU read the newer bytes. All pass with copy-on-write, and bytes outside the
updated range are preserved. Metal retains the previously bound buffer until
queued commands finish. Initial writes and no-overwrite appends retain their
existing direct-write path; the fix adds no per-frame GPU completion wait.

The reported terrain symptom occurs intermittently during fast pans, especially
at far zoom. The buffer tests prove a matching lifetime defect and its correction;
the user confirmed on 2026-10-21 that the terrain lines were gone. The user also accepted continuous drag selection in the subsequent input-handling candidate. This does not establish visual correctness for every map or hardware configuration.
