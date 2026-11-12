### Release Notes - v0.3.0 (75)

Features
- Added a numbered overview of the issuance steps before the consent screen
- The issuance consent screen now lists the PID data, with a show more/less toggle
- Applied the final designs across the PID issuance, onboarding and PIN screens
- Added an explanation sheet for the card PIN and the PIN letter
- Closing the issuance or presentation flow now asks for confirmation
- Cancelling PID issuance now stops the flow and discards the pending credential
- The privacy policy now opens without leaving the app
- The wallet locks itself when the account is revoked
- Added the Common Codes EUDI Hub sandbox trust anchors

Fixes
- The success animation at the end of issuance moved the message on screen

Known issues
- PID credentials are displayed incorrectly or not at all (german-national-wallet/issues-tracker-ios#20)
- After entering CAN, PID re-issuance only works after reinstalling the app
