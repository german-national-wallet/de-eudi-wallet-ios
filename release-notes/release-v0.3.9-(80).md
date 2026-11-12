### Release Notes - v0.3.9 (80)

Features
- Enforced Access Certificates and signed Issuer metadata, removed old trust anchors
- Enforced Registration Certificates, Presentation are refused when the query requests more than the Registration Certificate
- Added the settings screen, including wallet loss protection
- Added the app intro and platform authentication setup screens
- Presentation errors are now shown in designed dialogs, with a specific message for each
- Distinguish trust anchors per app environment
- Updated the wallet kit and RASP libraries

Fixes
- Presentation that are unsatisfiable or declined by the user redirect to the redirect_uri if provided by the Relying Party
- Refreshing an expired MDVM token that blocked calls to RWSCA and the Wallet Provider Backend
- Disabled eID developer mode in apps that do not offer PID simulation
- The retry button after a failed PID issuance went to the wrong screen
- SBOMs named the wrong supplier for packages that do not name one

Known issues
- PID credentials are displayed incorrectly or not at all (german-national-wallet/issues-tracker-ios#20)
