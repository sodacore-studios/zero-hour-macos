# Publication audit — 2026-10-21

The current source tree and all reachable blobs in the pre-existing Git history were checked before this publication for known deployment credentials/invitation hashes, private operator addresses, local account paths, GitHub token patterns and private-key headers. Environment/configuration paths were inspected separately. No original game archives or player profiles are included in the release source set.

- No known live credential or invitation value was found in current source or reachable history.
- Operator host/IP details existed in four historical files. Current documentation, relay examples and the engine's fallback endpoint were sanitized. The public repository starts from the audited, sanitized snapshot. The original repository and its pull request were moved to a private archive with explicit user approval; a local Git bundle also preserves the history. The public source and reachable history contain none of the known operator addresses.
- A private-key header pattern in the upstream Windows networking DLL is a NUL-terminated PEM parser marker, not a complete PEM key. This vendor binary is not part of the supported macOS application bundle.
- Committed `.env.example` files and service configuration contain examples/placeholders. Live `.env`, signing keys, private configuration, coverage/build outputs and archives are ignored.
- The update private key is held outside the checkout. Only its public key is tracked. GitHub Actions uses a separately authorized encrypted repository secret.

This is a bounded source/history audit, not a guarantee that upstream third-party code contains no vulnerabilities. Existing upstream copyrights and contributor metadata are retained. The original history is excluded from the public repository and preserved in a recoverable private archive. No other authors' history is rewritten.
