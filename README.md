# EUDI Wallet DE — iOS

This is a source code of the German National Wallet iOS application.

This repository is one-way, read-only and flows out of an internal repository.

## Building

This mirror carries the complete application source: the Xcode project, the app
target, every module package and the tests. It opens in Xcode and the structure
and protocol implementations can be followed end to end.

It also builds and runs as published, with no configuration step. Every
endpoint, token and service credential is a **placeholder**, so the app starts
and the UI is navigable, but nothing that talks to a service works until you
supply your own — see
[Supplying your own services](#supplying-your-own-services).

### Requirements

- **Xcode 16 or newer.** The project is `objectVersion` 70.
- **iOS 18.0** deployment target for the app; module targets go back to 16.6.
- **Swift 5** language mode.
- Dependencies resolve through Swift Package Manager from the published
  `Package.resolved`; all of them are public.

### Schemes and configurations

Four schemes are published, each pairing with `Debug` and `Release`:

| Scheme | Configurations | Bundle id |
|---|---|---|
| IDGo Dev | `DevDebug`, `DevRelease` | `org.sprind.wallet.dev` |
| IDGo Sandbox | `SandboxDebug`, `SandboxRelease` | `org.sprind.wallet.sandbox` |
| IDGo Staging | `StagingDebug`, `StagingRelease` | `org.sprind.wallet` |
| IDGo Prod | `ProdDebug`, `ProdRelease` | `codes.common.dyou.prod` |

Signing is not published: `DEVELOPMENT_TEAM` is set, but no provisioning
profiles or certificates accompany it.

### Build and run

Open `IDGo.xcodeproj`, pick a scheme and build. Swift Package Manager resolves
everything from `Package.resolved`; all dependencies are public.

One caveat on the command line: the project depends on `swift-secp256k1`, which
ships a build-tool plugin. Xcode prompts to trust it on first build, but
`xcodebuild` needs the flag explicitly:

```sh
xcodebuild build -project IDGo.xcodeproj -scheme "IDGo Dev" \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -skipMacroValidation -skipPackagePluginValidation
```

The only omission that changes the build is the brand typeface, which degrades
typography but nothing else — see [Fonts](#fonts).

## Supplying your own services

Every published endpoint is a `PLACEHOLDER_*` token rather than a host, so
nothing resolves and the app cannot quietly reach infrastructure someone else
controls.

### Build settings

Per-environment settings live in `Wallet/Config/Wallet{Dev,Sandbox,Staging}.xcconfig`.
The published files carry the **real key set with placeholder values**;
`oss-sync/check-placeholders.sh` fails the sync if the key set drifts from the
internal one, so this list cannot silently rot.

| Key | What it is for |
|---|---|
| `WALLET_HOST_URL` | Wallet backend (registration, attestation, remote signing) |
| `VCI_ISSUER_URL` | OpenID4VCI credential issuer |
| `PID_ISSUER_NAME` | Display name of the PID issuer |
| `PID_MSO_MDOC_CONFIG_ID`, `PID_SD_JWT_CONFIG_ID` | Credential configuration ids requested at issuance |
| `TLS_PIN_HOST_SUFFIXES` | Host suffixes subject to certificate pinning |
| `WALLET_OTLP_HOST_URL`, `WALLET_OTLP_SERVICE_NAME` | OpenTelemetry collector and per-variant service name |
| `FEATURE_FLAG_BASE_URL` | Feature-flag service |
| `APP_UPDATE_URL` | Target of the force-upgrade screen |
| `PRIVACY_POLICY_LINK` | Privacy policy shown in-app |

Values left real are structural and identify nothing: `BUILD_VARIANT`,
`CORE_USER_AUTH`, `BATCH_COUNT`, `APS_ENVIRONMENT`, `VCI_REDIRECT_URI`
(derived from the bundle id) and `BURGERAMT_SERVICE_LINK` (a public bund.de
service). `version.xcconfig` is published unchanged — it carries only the
marketing and build version.

### Secrets

Three tokens reach the app through a `.env` file at the repository root, copied
in as a resource. The published `.env` carries `PLACEHOLDER_*` values; replace
them with your own:

| Key | What it is for |
|---|---|
| `API_KEY` | Authenticates the app against your wallet backend |
| `X_AUTH_API_TOKEN` | Bearer token for the telemetry/analytics endpoint |
| `FEATURE_FLAG_API_KEY` | Auth for the feature-flag service |

### Telemetry

The app exports traces over OTLP to `WALLET_OTLP_HOST_URL`, authenticated with
`X_AUTH_API_TOKEN`, tagged with `WALLET_OTLP_SERVICE_NAME`. Against the
placeholder host every export simply fails, which is harmless.

### Feature flags

Flags are fetched from `FEATURE_FLAG_BASE_URL` and cached. When the fetch fails
the app falls back to the defaults compiled into each flag, so it keeps running.

### Push notifications

The `GoogleService-Info-*.plist` files are **placeholders** — project
`eudi-wallet-placeholder`, no real API key. They carry the same key set as the
real files, so the *Copy GoogleService-Info.plist* build phase (which maps one
plist per configuration) succeeds and everything except push works. Replace the
one for your configuration with your own from the Firebase console to enable
it.

### Certificates and pinning

Unlike the above, the trust anchors in `Wallet/Certificates/` are published
**unchanged**, because they are public CA certificates and the pin set is part
of the security model: PID issuer CAs, the German registrar, and the D-Trust
and Let's Encrypt roots the app pins. They contain no private key material, and
publishing them is what lets a reader see which CAs the wallet actually trusts.
The published set is pinned exactly by the sync pipeline, so a new certificate
cannot ride along unnoticed.

`CertificatePinner` applies them to the hosts named by `TLS_PIN_HOST_SUFFIXES`.

### eID card reading

Card reading goes through the AusweisApp2 SDK against Governikus servers. It
needs real NFC hardware and a real German ID card; there is no simulator path.
The NFC and App Attest entitlements are published in `IDGo.entitlements`.

## Tests

Unit and UI test targets, the test plans and the Cuckoo mocking configuration
are published. The generated mocks are not — they are build output in all but
name — and neither is the 45 MB Cuckoo generator binary. Fetch the generator
once, then regenerate:

```sh
Cuckoo/run --download   # downloads the version pinned in Cuckoo/version
./GenerateMocks.sh
```

Much of the suite will not compile until you do: `GeneratedMocks.swift` defines
the `Mock*` types that roughly half the test files reference.

## Fonts

The brand typeface, Diatype, is commercially licensed and cannot be
redistributed. No substitute is supplied, so text falls back to the system font
and typography will not match production. To restore it, drop the six licensed
`.ttf` files into `Modules/logic-ui/Sources/DesignSystem/Resources/EUDI Diatype/`,
keeping the filenames `CustomFonts.swift` registers.

## Relationship to the released app

A build produced from this source will not match the App Store binary byte for
byte, so it cannot be used to reproduce or verify that build.

A wallet is also more than the app on the phone: issuing and presenting
credentials involves an issuer, a verifier and a wallet backend, which live
outside this repository.

## Scope

Published: application source, the module packages under `Modules/`, resources
and localizations, the Xcode project and its schemes, the resolved dependency
graph, unit and UI tests with their test plans, and the Cuckoo harness.

Not published:

- **Real endpoints and per-environment configuration** — replaced by the
  `PLACEHOLDER_*` values documented above.
- **Secrets and configuration** — the `.env` file and the
  `GoogleService-Info-*.plist` files are omitted.
- **Signing, CI and release tooling** — GitHub Actions workflows, fastlane, the
  Xcode Cloud scripts and the signing configuration.
- **Licensed material** — the brand typefaces.
- **Generated mocks and the Cuckoo generator binary**, both reproducible from
  what is published.
- **Internal documentation** and the tooling that produces this mirror.

## Upstream

The application is a fork of the European Commission reference implementation,
[`eu-digital-identity-wallet/eudi-app-ios-wallet-ui`](https://github.com/eu-digital-identity-wallet/eudi-app-ios-wallet-ui).
The upstream reference implementation already uses the EUPL-1.2 licence, hence
we are open sourcing it under the same licence. Upstream copyright headers are
preserved in the files that carry them.

## Dependencies of note

- **AusweisApp2 SDK** ([Governikus](https://github.com/Governikus/AusweisApp2-SDK-iOS)) —
  eID card reading. Public Swift package.
- **wallet-kit** —
  [our fork](https://github.com/german-national-wallet/de-eudi-lib-ios-wallet-kit)
  of the EU wallet-kit protocol layer, where the OpenID4VCI and OpenID4VP code
  lives. Public, and pinned by commit in `Package.resolved`.
- The full resolved dependency graph is published as `Package.resolved`.

## Related documentation

- [Architecture reference docs](https://bmi.usercontent.opencode.de/eudi-wallet/wallet-development-documentation-public/latest/)

## Design System

The link below contains the Design System for the d-you App, including Guidelines, Assets, Template, Components, and the main happy flows for App Onboarding (Wallet Activation), Dashboard, Activities and Settings, PID & EAA Issuance/Inspection/Presentation: [**Figma Design System**](https://www.figma.com/design/vGhn8VyJ987JzmJenIuvI1/2026_09-Design-System-d-you-and-flows)

This Design System is a work in progress and will keep evolving through future iterations. We will periodically push updates with the latest designs. Some components, assets, or templates may change over time.

## Contributing and issues

Issue tracking and pull requests are **not** enabled on this mirror right now.
Issue tracking is planned to be enabled in October, 2026. For more details, see
[CONTRIBUTING.md](CONTRIBUTING.md). For security reports, see
[SECURITY.md](SECURITY.md).

## Licence

EUPL-1.2. See [LICENSE.txt](LICENSE.txt) and [NOTICE.txt](NOTICE.txt).
