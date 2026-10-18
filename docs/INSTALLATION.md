# Installation and operation

1. Download the latest `Zero-Hour-<version>-macOS-arm64.dmg` from this repository's Releases page. Public downloads do not require a GitHub account.
2. Open the image and copy `Zero Hour.app` to Applications or your user Applications folder. Run it from that writable folder, not from the disk image.
3. Select the parent folder containing your installed Generals and Zero Hour files. Keep this folder on the Mac. Original game content is not included in GitHub downloads.
4. Select resolution, fullscreen and camera controls. Leave the server empty for single-player, or enter your operator's HTTPS address, player name and invitation. A separate relay can be entered as `hostname:port`.

The app is ad-hoc signed and not notarized. On first launch, macOS may require an explicit allowance in System Settings → Privacy & Security. Do not disable system-wide Gatekeeper protection.

## Moving from a local complete package

Older complete packages store game content inside `Contents/Resources/Spieldaten`. Before manually replacing one with the GitHub download, copy that folder to a permanent location outside the app and select it in the new launcher. Keep the old app until the new installation works. Automatic updates from an updater-enabled complete package perform this migration themselves, to `~/Library/Application Support/Zero Hour/Spieldaten`.

## Controls and settings

WASD and arrow keys move the camera; the mouse wheel zooms. Command–Return toggles fullscreen. WASD camera mode replaces the original unmodified W/A/S/D commands during play while preserving text entry. Disable it for the original hotkeys.

The launcher and in-game Options menu offer standard, ultrawide and super-ultrawide resolutions, including 5120 × 1440, 6016 × 3384 and 7680 × 2160. Lower render resolutions reduce GPU load; the performance scheduler prevents ordinary slower rendering from halving simulation speed.

Settings, saves and logs live under `~/Library/Application Support/Zero Hour/`. The launcher opens this folder. Back it up before changing versions. A GitHub update does not overwrite it.

## Automatic updates

Public releases update without signing in or entering a token. Use **Zero Hour → Updates …** to change automatic updates or check manually. For a private deployment only, this dialog can store a fine-grained GitHub token with **Contents: Read-only** access in the macOS Keychain. Organization policy may require approving such a token.

Automatic updates are enabled by default. The launcher checks at startup and every six hours while running. It downloads the latest stable release, verifies its signature and archive checksum, and replaces/reopens the app when no match is running. You can disable automatic updates or remove the token in the same dialog. The old 0.2.x launcher needs one manual installation to gain this updater.

A failed check does not stop offline play. No GitHub account or token is necessary for public releases.

## Multiplayer and rollback

All players must use the same engine build. The operator must set `NativeClientCRC32` from the release's `Version.json` on the private service before using a new binary online. Do not disable version checks. A GitHub update cannot migrate an independently hosted server.

The installer retains `Zero Hour.app.previous` beside the installed app. Close the game and launcher, move the new app aside and rename the backup to `Zero Hour.app` to roll back. Disable automatic updates before rolling back to avoid installing the newer release again. The installer restores the old app automatically if replacement or the launch request fails; it cannot detect a later gameplay crash. Keep user data backups separately.
