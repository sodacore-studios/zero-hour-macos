# GitHub updater architecture

The launcher queries `GET /repos/sodacore-studios/zero-hour-macos/releases/latest`. Only stable, non-draft releases with a greater three-component version are eligible. The repository is fixed in code; the game server and relay settings do not change the update origin.

Release assets include `update.json`, its raw Ed25519 signature `update.sig`, and a versioned ARM64 ZIP. The manifest binds version, architecture, minimum OS, bundle identity, archive filename, byte size and SHA-256. The public key is embedded in the app's Info.plist. The private signing key is stored separately and supplied to GitHub Actions as the `UPDATE_SIGNING_KEY` secret (base64-encoded 32-byte Ed25519 seed). Never commit it. Retain a private recovery copy: losing it prevents updates trusted by existing installations.

Public release checks and downloads need no token. Optional private-repository tokens are stored in the macOS Keychain. Requests use an ephemeral URLSession. Authorization is sent only to api.github.com and explicitly removed on redirects to the allowed GitHub release asset CDNs. Credentials are never put in URLs or shell arguments. Fine-grained tokens need repository Contents read permission; see [GitHub's release asset API](https://docs.github.com/en/rest/releases/assets).

After signature and checksum verification, the launcher extracts the archive, checks the bundle identity/version and validates its code signature. A small native helper waits for the launcher to exit, stages a copy on the destination filesystem, validates it again and renames the old/new apps. Failed validation leaves the old app untouched. A failed rename or launch request restores the backup. The helper does not elevate privileges; use a writable Applications directory. The installer is inactive during a running match. Original assets embedded in an older complete package are copied outside the app first.

Update signature verification uses [Apple CryptoKit's Ed25519 API](https://developer.apple.com/documentation/cryptokit/curve25519/signing). This authenticates the publisher's manifest independently of GitHub transport. Ad-hoc bundle signing is an integrity check, not a substitute for Apple notarization. A compromised release signing key remains a trusted-publisher compromise; protect the repository and Actions secrets accordingly.

## Troubleshooting

- **GitHub not reachable / authorization:** check Internet access, repository access, token expiry and organization approval. No token is preconfigured in the package.
- **Invalid signature or checksum:** installation stops. Retry later; never bypass the checks.
- **App on a disk image / translocation / read-only directory:** copy it to a writable Applications folder and relaunch.
- **Match running:** the verified update waits until the child game process exits.
- **Online version mismatch after update:** ask the server operator to coordinate the same release on all Macs and the matching binary CRC. The updater does not alter server configuration.
- **Keychain access after an ad-hoc signed app update:** macOS may ask to allow the rebuilt launcher to read the existing entry. Allow only your intended app; Developer ID signing is a future improvement.

The update core is tested with synthetic keys and temporary app directories, including tamper rejection and rollback. Real GitHub release retrieval/download and package checks are verified during delivery. An unattended end-to-end update across two future releases is not implied by those tests.
