# Verification status

## Performance

The user reported successful performance testing and approved publication on 2026-10-21. The exact display mode, duration and multiplayer conditions of that acceptance were not specified. This is acceptance of the performance preview, not a claim that every test matrix case was executed.

Controlled tests on the local Apple Silicon Mac restored median simulation speed from 0.5x to 1.0x at a 30 FPS render ceiling. The new scheduler also sustained 60 logic ticks per second at 15 render FPS. Thirty-six paired simulation checksum checkpoints matched through frame 21,600. The final signed preview completed a full 28:35 replay headlessly in 01:44 with exit code zero and no reported CRC mismatch. See `performance-results.json`.

## Updater and delivery

Deterministic Swift tests cover semantic version ordering, invalid versions, signature/hash rejection, OS gating, URL origin policy, failed staging validation, failed launch rollback and successful app replacement. C++ tests cover fixed-step pacing, irregular render intervals, suspend/transition limits, network deadlines and completed-tick performance sampling. These tests operate in isolated temporary directories.

The release workflow builds ARM64 binaries and publishes coverage reports. Package validation checks code signatures, architecture, dependency paths, checksums and absence of original game archives. Actual GitHub run results and release artifacts are the delivery evidence, not commit dates.

## Terrain, selection and mouse controls

On 2026-10-21, local tests reproduced two defects in the production Metal code:
ordinary writes changed shared buffers already referenced by queued GPU work, and
disabled texture-stage projector state discarded valid UI fragments. The original
buffer implementation failed delayed GPU readback for vertex, 16-bit index and
32-bit index buffers; all pass after copy-on-write. Both original disabled-stage
shader regression cases failed; all ten shader cases pass with active-stage-only
clipping. An asset-free in-memory device suite adds 55 deterministic assertions
against the actual production buffer classes, with LLVM coverage for CI.

The user confirmed that terrain grid lines were gone. The follow-up candidate
also updated selection hints from current drag messages, bounded AppKit input work
between frames and added a default-on launcher option for right-click orders.
On 2026-10-21 the user confirmed that both continuous drag selection and the new
mouse controls worked correctly and approved publication. The local candidate's
engine SHA-256 was `f36e5a01ab8a412c8632e1c06900f710e494c2adaf36d452986a3e49c516e174`.
The precise map, test duration and opponent configuration were not specified.

Deterministic event fairness and launcher migration/opt-out tests pass. See
`work/renderer-tests/README.md` and `work/input-tests/README.md` for commands and
scope. CI rebuilds and packages the release independently; local user acceptance
does not establish a new two-Mac match or performance benchmark of that rebuilt
binary. The live server keeps its existing accepted checksum until coordinated.

## Remaining limits

- The user previously confirmed stable multiplayer, but no new two-Mac live match with the final updater release is claimed.
- GitHub publication does not change the live server's allowed binary CRC.
- Apple Developer ID signing/notarization and all supported macOS versions have not been validated.
- The original automated render benchmarks used a 1728 × 882 target with audio bypassed on a locked desktop. They do not establish 5120 × 1440 GPU frame rates or new audio behavior.
- The update installer tests verify launch-request rollback; they cannot guarantee that a future version will not crash later during play.

## Windows and cross-platform candidate (2026-10-21)

The test device was identified over SSH before changes: Windows 10 build 19045,
Intel HD Graphics and AMD Radeon R5 M255. A native x86 Release build used pinned
networking dependencies and the installed original EA game files. No EA executable
was replaced. The original INIZH, MapsZH and GensecZH archive hashes match the Mac.

### Native online match

A Mac host and Windows guest completed a controlled match on Alpine Assault (2)
through the isolated staging service and a forced public TURN route. Both players
produced a second construction dozer, completed a power plant and moved units with
short right clicks. Windows WASD camera movement worked during the match. The Mac
surrendered after approximately three minutes; both clients received the defeat
and displayed the same result table with two units and two buildings per player.

The Mac validated 12,655 received CRC pairs through simulation frame 12,688, with
no unequal or missing checksums. The Windows performance samples reported no
mismatch and approximately 59–60 logic updates per second during most of the run.
Both native transports confirmed TURN. Both machines used the same Internet access
network; this is not verification across two unrelated ISPs, a long competitive
match, large armies, spectators, reconnects or every map/faction combination.

Tested executable SHA-256 values:

- macOS ARM64: `534a2b4d060308038e1e6f785ea5c516a3999a58a9082d461dbd3ecc20cdc320`
- Windows x86: `594ddc851d030dd0ab19c8748375f3fbb96ba1be44c47177ff19a986abd0fb33`

The Mac executable came from CI source 886b2df; the Windows build additionally
includes 0071ff4, which makes the already active Mac CRC cadence apply to Windows.
CI/release rebuilds receive different binary hashes and need their own server
admission. Publication does not change the production service's accepted binaries.

### Replay and regression checks

Both local candidates completed the same full 28:35 replay with exit zero: macOS
in 01:45 and Windows in 04:49. All 1,716 simulation CRC checkpoints, every 60 frames
through frame 102,900, matched. Shared compatibility definitions fixed a Windows
pathfinding allocation-counter difference without disabling CRC validation.

The online tests also found and fixed three independent startup/protocol defects:

- Network frame advancement depended on render-generated messages and could skip
  initialization during catch-up. Production-function tests cover empty streams,
  high shell frames, actual multiplayer startup, repeated frames and leaving.
- First incoming transport handles were not registered. The production acceptance
  test covers authenticated lobby membership, malformed/self/duplicate identities,
  missing authentication/lobby, pending handles and transport failure.
- Diagnostic builds used a different live CRC interval. The cadence now depends
  on the networking protocol compatibility mode, with all four combinations of
  retail compatibility and diagnostic flags compiled in the isolated suite.

Private service tests cover invitation rejection, authenticated WebSockets,
password-protected lobby create/join and wrong-password rejection. A public TURN
probe exchanged ten exact bidirectional payloads and rejected an excluded peer.
The .NET 10 Release server build passed without warnings or errors. Shared pacing,
clock and input-budget tests also passed under native MSVC on the test device.
CI publishes isolated core/launcher/renderer coverage and gates releases.

### Windows interaction and remaining limits

The Windows Forms launcher detected both EA game folders and rejected an empty
player name. Its resolution dropdown selected 1280 x 800, persisted that value,
and opened a measured 1280 x 800 windowed viewport. Native Direct3D 8 skirmish and
online rendering, WASD, left-click selection, short right-click movement, hotkey
labels, Escape pause and normal process closure were observed.

Fullscreen startup and normal exit were observed, but requesting 1280 x 800 on
this hardware fell back to a smaller mode. The engine retries an adapter-supported
resolution if Direct3D rejects the requested fullscreen mode. The dropdown does
not guarantee that every listed fullscreen resolution is supported by a GPU.

The former prebuilt networking DLLs required debug CRT/Sentry runtimes. They were
replaced with pinned source builds and Release runtime/dependency closure checks;
the replacement package starts natively. Windows replay testing used the
interactive desktop because the legacy Miles backend failed in the SSH session.
Audio output, Windows 11 hardware, Windows ARM and Wine remain unverified.
Windows updates are manual and packages are not Authenticode-signed. The macOS
signed automatic updater remains unchanged. Production configuration is unchanged.

The Windows launcher also started the native client at 1920×1080 fullscreen on the test adapter. The prior 1280×800 fullscreen choice fell back to 800×600; 1280×800 windowed mode worked. The test profile was restored to windowed mode afterward.
