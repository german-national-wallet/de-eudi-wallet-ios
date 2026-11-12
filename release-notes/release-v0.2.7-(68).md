### Release Notes - v0.2.7 (68)

Features
- Implement new color tokens and fonts
- Implement splash screen with branded colors
- Validate NiScy's OpenID4VP request encryption implementation
- implement credential presentation during credential issuance
- Implement delete RWSCA endpoint and clean up the key deletion

Fixes
- After disabling and re-enabling PA, the wallet is deleted, but PID could only be issued after app restart
- Not all requested claims were returned to the verifier
- When disabling and re-enabling platform authentication, after re-issuing the PID, it only showed up in the wallet after restarting the application

Known issues

- Transport pin flow is not working as expected
