### Release v0.4.3 (81)

**Note:** Updating to this latest release will clear the current wallet.

**Features**
- Added an Activity list: users can see all credential activity (issuance and presentations) in the wallet dashboard, including a details view for each entry.
- Retry action added to failed presentations.
- Added updated trust anchors for Sandbox Registrar and EUDI Hub.
- The first PID/EAA presentation now shows the overview screen.
- Credential response encryption is limited to ECDH-ES on P-256 with AES-GCM, and RSA is switched off.
- The simulated eID card now uses a random pseudonym key.

**Fixes**
- The wallet follows the Relying Party's redirect_uri when the user declines a presentation.
- The consent screen loading state is fixed.
- PIN view focus handling is fixed.
- Failed AES-GCM authentication now throws an error instead of failing silently.
- Hardened the wallet PIN key derivation.

**Known issues**
- PID credentials may display incorrectly or not at all (german-national-wallet/issues-tracker-ios#20).
