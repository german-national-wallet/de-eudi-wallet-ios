### Release Notes - v0.2.7 (64)

Features
- Added support for refreshing credentials when available credentials are low (current batch size is 10 per credential format)
- Migrated wallet backend integration to the newer v1/wpb endpoints and updated wallet registration flows
- Updated environment configuration to use the Youniqx backend setup
- Improved key protection by encrypting wallet data and binding previously unencrypted keys to the Platform Authenticator
- Added key attestation inside the DPoP proof

Fixes
- Fixed presentation parsing for nested claims
- Fixed EAA credential detail layout when credentials include a background image
- Fixed issuance success navigation so the stack is properly cleared

Known issues
- When disabling and re-enabling platform authentication, after re-issuing the PID, it only shows up in the wallet after restarting the application
