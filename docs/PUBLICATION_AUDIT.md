# Publication audit — 2026-10-21

The current source tree and all reachable blobs in the pre-existing Git history were checked before this publication for known deployment credentials/invitation hashes, private operator addresses, local account paths, GitHub token patterns and private-key headers. Environment/configuration paths were inspected separately. No original game archives or player profiles are included in the release source set.

- No known live credential or invitation value was found in current source or reachable history.
- Operator host/IP details existed in four historical files. Current documentation, relay examples and the engine's fallback endpoint were sanitized. The public repository starts from the audited, sanitized snapshot. The original repository and its pull request were moved to a private archive with explicit user approval; a local Git bundle also preserves the history. The public source and reachable history contain none of the known operator addresses.
- A private-key header pattern in the upstream Windows networking DLL is a NUL-terminated PEM parser marker, not a complete PEM key. This vendor binary is not part of the supported macOS application bundle.
- Committed `.env.example` files and service configuration contain examples/placeholders. Live `.env`, signing keys, private configuration, coverage/build outputs and archives are ignored.
- The update private key is held outside the checkout. Only its public key is tracked. GitHub Actions uses a separately authorized encrypted repository secret.

This is a bounded source/history audit, not a guarantee that upstream third-party code contains no vulnerabilities. Existing upstream copyrights and contributor metadata are retained. The original history is excluded from the public repository and preserved in a recoverable private archive. No other authors' history is rewritten.

## Graphics and mouse-control release follow-up

Before publication on 2026-10-21, the current tracked/proposed source set (5,015
files) and all 4,890 reachable Git blobs were rescanned for the known operator
addresses, current invitation value, local account path, GitHub/AWS credential
patterns and complete private-key blocks. No such private value or key was found.
The RFC1918 address matches were reviewed: they are upstream API examples, network
classification ranges and vendor sample registry comments, not deployment data.
The four environment/configuration filename matches contain placeholders or
localhost development endpoints. Game archives, live settings, signing keys, build
outputs and test profiles remain excluded. No history cleanup was needed.

The code file hashes match the user-accepted second local graphics candidate;
subsequent changes only finalize documentation. CI independently rebuilds the
release and validates its distributable artifacts.

## Windows candidate audit

The candidate and 4,917 reachable history blobs were checked for known operator
paths/addresses, private key material, common GitHub/AWS credentials and sensitive
configuration filenames before upload. No such private values were found. A
PEM-header string in the already-public networking DLL was reviewed as a parser
constant, not a complete private key. Private test-host scripts, game files,
profiles, build outputs and live configuration remain outside tracked content.
The Windows test transfer started from the exact public commit and tree verified
against GitHub. No history rewrite was performed.

The final cross-platform follow-up was rescanned on 2026-10-21: 5,045 current
tracked/proposed files and 5,050 reachable history blobs produced no findings for
the audit's credential, private-address/path or sensitive-filename rules. Native
match evidence is summarized with binary hashes and numeric checks; invitations,
TURN credentials, private hostnames, profiles and raw session logs are excluded.
The agent-created commits use the preceding Sunday as author/committer metadata
at the user's request. These dates are not evidence of build or test execution;
CI timestamps and the explicitly dated verification record describe those events.
