# EUDI Wallet DE — iOS

Source of the German EUDI Wallet iOS application, published for **transparency**.

This repository is a one-way, read-only mirror. Code flows out of an internal
repository through a sanitizing pipeline; it does not flow back.

## What this is not

**It might not build.** That is a scope boundary, not a defect:

- **Configuration is stripped and replaced with placeholders.** The
  per-environment build settings under `Wallet/Config/` carry their real keys
  with `PLACEHOLDER_*` values, so you can see which settings exist without
  learning where they point. `GoogleService-Info.plist` is omitted entirely.
- **Signing, CI and release tooling are absent** — GitHub Actions workflows,
  fastlane, and the Xcode Cloud scripts are not published.
- **Tests are absent** — test targets, test plans and the mocking harness are
  not published.
- **A commercially licensed typeface is omitted.** The app uses the Diatype
  family, which we cannot redistribute. The Roboto family alongside it
  (Apache-2.0) is published.

It is also not a reproducible build: no claim is made that this source
corresponds byte-for-byte to any build in the App Store.

## Upstream

The application is a fork of the European Commission reference implementation,
[`eu-digital-identity-wallet/eudi-app-ios-wallet-ui`](https://github.com/eu-digital-identity-wallet/eudi-app-ios-wallet-ui)
(EUPL-1.2) — a hard fork of the UI, and a soft fork of the wallet-kit protocol
layer. Upstream copyright headers are preserved in the files that carry them.

## Dependencies of note

- **AusweisApp2 SDK** ([Governikus](https://github.com/Governikus/AusweisApp2-SDK-iOS)) —
  eID card reading. Public Swift package.
- **wallet-kit** — our fork of the EU wallet-kit protocol layer. Referenced from
  the package manifests; publication of the fork itself is on the roadmap.
- The full resolved dependency graph is published as `Package.resolved`.

## Related documentation

- [Architecture reference docs](https://bmi.usercontent.opencode.de/eudi-wallet/wallet-development-documentation-public/latest/)

## Contributing and issues

Issue tracking and pull requests are **not** enabled on this mirror — see
[CONTRIBUTING.md](CONTRIBUTING.md). For security reports, see
[SECURITY.md](SECURITY.md).

## Licence

EUPL-1.2. See [LICENSE.txt](LICENSE.txt) and [NOTICE.txt](NOTICE.txt).
