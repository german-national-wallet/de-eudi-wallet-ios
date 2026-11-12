### Release v0.4.13 (83)

**Features**
- The app detects when the device is offline at the network layer and shows an accessible "no internet" dialog during presentation, issuance, onboarding and PID deletion.
- The number of credentials requested per PID batch is now 5 by default (previously 10).

**Fixes**
- Credential request and response encryption now depends on the issuer's metadata (response encryption is supported, not forced). (Fixes german-national-wallet/issues-tracker-ios#29)
- The presentation request is now fetched only once.
- The eID card PIN retry after a wrong PIN is fixed.
- Keyboard navigation on iOS 27 is fixed.
- Accessibility focus on the "no internet" popup is fixed.
- PID credentials now display correctly (Fixes german-national-wallet/issues-tracker-ios#20).
