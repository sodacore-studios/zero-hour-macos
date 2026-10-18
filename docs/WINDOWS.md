# Windows client

Development candidate: native x86 client for Windows 10/11 on Intel/AMD PCs.
Windows ARM and Wine are not verified. The hardware test matrix is recorded in
`VERIFICATION.md`; source changes and passing unit tests alone do not establish
working graphics or a completed Internet match.

## Installation and use

Extract the Windows ZIP into a user-writable folder and run `Start-ZeroHour.cmd`.
The launcher uses the Windows PowerShell and Windows Forms included with Windows.
Select your own installed Zero Hour folder (containing `INIZH.big`) and original
Generals folder (containing `INI.big`). Original game archives and the proprietary
Bink/Miles runtime files are not distributed. Keep the complete legitimate game
installations available. The launcher does not replace the EA executable.

Choose a resolution from the dropdown, WASD camera control, right-click orders
and windowed or fullscreen mode before starting. The list includes standard and
ultrawide sizes, connected display sizes and a previously saved custom size.
Fullscreen modes must be supported by the graphics adapter; otherwise the engine
falls back to a safe mode. Use windowed mode if a chosen size is unavailable.
Arrow keys and the mouse wheel remain available.
Middle-button camera controls and command-button hotkey labels use the same
shared implementation as macOS. Rendering uses Direct3D 8 on Windows; the Metal
buffer fixes apply only to macOS.

Settings and the separate game profile are stored under
`%LOCALAPPDATA%\sodacore studios\Zero Hour`. The invitation is passed only to the
launched game and is not saved in `Launcher.json`. Enter the private HTTPS server,
player name, invitation and optional TURN relay for online play. A blank server
selects a closed local endpoint for offline play.

## Online compatibility

Binary admission still checks the actual executable CRC and protocol versions.
The private server can explicitly associate validated binary CRCs with a shared
simulation CRC using `PrivateService:AcceptedClients`. That seed still includes
the game version and multiplayer script checksums. Never group binaries merely
because they build: verify a real cross-platform match and deterministic replay
checksums. Existing single-build deployments retain `NativeClientCRC32` behavior
when no explicit mapping is configured. Publication does not deploy the server.

## Updates and rollback

Download the latest Windows package from the project's GitHub Releases page.
Close the game, extract the new version into a separate folder, and start it.
Keep the previous folder for rollback; user settings live outside either package.
The macOS signed automatic updater is platform-specific. This Windows candidate
uses manual package updates and is not Authenticode-signed.

## Building and troubleshooting

Install Visual Studio 2022 Build Tools with MSVC x86/x64, Windows SDK, ATL and
CMake components, plus Strawberry Perl for OpenSSL. Networking dependencies are
built from pinned source revisions with Release runtimes. Run `powershell -File work/windows/Build.ps1` from the checkout.
Builds target x86 to match the supplied networking and original media runtimes.
A missing `mss32.dll` or `binkw32.dll` means the selected original installation is
incomplete. Check the profile logs after a start failure. Do not disable TLS or
version checks to work around an online failure.
