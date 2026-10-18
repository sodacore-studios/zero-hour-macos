## Skirmish game speed

- Fix the Skirmish speed slider being ignored by the decoupled macOS simulation scheduler.
- Interpret the original slider scale consistently: 15 = half speed, 30 = normal speed, 60 = double speed. The far-right `--` setting runs as fast as the bounded catch-up budget and hardware allow.
- Preserve fractional tick credit at the catch-up ceiling so intermediate high-speed settings remain accurate at low render rates.
- Keep render FPS independent from game speed. Changing the graphics frame limit no longer overrides the selected local match speed.
- Reset the local speed at the start of a new match, campaign, load or replay. Multiplayer continues to use its network-controlled rate.
- Keep the live-match HUD clock in real active play time, regardless of the selected speed. Pauses, script freezes and network stalls do not advance it. Replays retain their recorded simulation-position clock.
- Test every numeric slider position with the production pacing code at 15, 30, 60 and 144 render FPS, plus unlimited, pause/halt, rate overrides and reset behavior. The existing one-hour pacing and network deadline tests also pass. Clock tests verify that one real hour displays as one hour at 0.5x, 1x, 2x and 8x, including pause/resume, long render frames and loading transitions.

Original game data is required and excluded from downloads. Packages support Apple Silicon and target macOS 13.3 or later; they are ad-hoc signed, not Apple-notarized. Automatic updates use signed manifests. All players and the private server's accepted client CRC must be coordinated using `Version.json` before online play; publication does not update the live server.

A fresh interactive Skirmish session and a two-Mac match with this exact build have not yet been verified.

Existing save files have no historical wall-time field. On load, the displayed clock starts from the saved simulation-time baseline and subsequently advances in real active time. The clock is presentation-only and does not change save formats, simulation rules or multiplayer checksums.
