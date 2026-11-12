### Release Notes - v0.3.1 (76)

Features
- Connections to the wallet backend and rWSCA are now certificate-pinned
- The wallet now sends its device model to the wallet provider on registration

Known issues
- PID credential data is displayed incorrectly or not at all (german-national-wallet/issues-tracker-ios#20)
- After entering CAN, PID re-issuance only works after reinstalling the app
- A potential `account not found` error is unhandled when updating from older app versions
