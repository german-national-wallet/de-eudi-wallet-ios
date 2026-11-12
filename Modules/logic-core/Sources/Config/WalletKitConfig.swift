/*
 * Copyright (c) 2023 European Commission
 *
 * Licensed under the EUPL, Version 1.2 or - as soon they will be approved by the European
 * Commission - subsequent versions of the EUPL (the "Licence"); You may not use this work
 * except in compliance with the Licence.
 *
 * You may obtain a copy of the Licence at:
 * https://joinup.ec.europa.eu/software/page/eupl
 *
 * Unless required by applicable law or agreed to in writing, software distributed under
 * the Licence is distributed on an "AS IS" basis, WITHOUT WARRANTIES OR CONDITIONS OF
 * ANY KIND, either express or implied. See the Licence for the specific language
 * governing permissions and limitations under the Licence.
 */
import Foundation
import logic_business
import EudiWalletKit
import EudiEtsi1196x2
import MdocSecurity18013
import OpenID4VCI

protocol WalletKitConfig: Sendable {

  /**
   * VCI Configuration
   */
  var issuersConfig: [String: VciConfig] { get }

  /**
   * VCI Configuration
   */
  var vciConfig: [String: OpenId4VciConfiguration]? { get }

  /**
   * VP Configuration
   */
  var vpConfig: OpenId4VpConfiguration { get }

  /**
   * Trust configuration: ETSI LoTE (List of Trusted Entities) trust sources,
   * verification-context mappings and trust policies used for reader / issuer validation.
   */
  var trustConfiguration: TrustConfiguration { get }

  /**
   * User authentication required accessing core's secure storage
   */
  var userAuthenticationRequired: Bool { get }

  /**
   * Service name for documents key chain storage
   */
  var documentStorageServiceName: String { get }

  /**
   * The name of the file to be created to store logs
   */
  var logFileName: String? { get }
    
 /**
  * Document categories
  */
  var documentsCategories: DocumentCategories { get }

  /**
   * Configuration for document issuance, including default rules and specific overrides.
   */
  var documentIssuanceConfig: DocumentIssuanceConfig { get }

  var pidIssuerName: String { get }

  var batchRefreshThreshold: Int { get }
}

struct WalletKitConfigImpl: WalletKitConfig {
  let configLogic: ConfigLogic
  let walletKitAttestationProvider: WalletAttestationsProvider
  let vciRedirectURI: String

  init(
    configLogic: ConfigLogic,
    walletKitAttestationProvider: WalletAttestationsProvider,
    vciRedirectURI: String = "VCI_REDIRECT_URI".valueFromBundle
  ) {
    self.configLogic = configLogic
    self.walletKitAttestationProvider = walletKitAttestationProvider
    self.vciRedirectURI = vciRedirectURI
  }

  var userAuthenticationRequired: Bool {
    getBundleValue(key: "CORE_USER_AUTH").toBool()
  }

  var pidIssuerName: String {
    configLogic.vciIssuerName ?? ""
  }

  var issuersConfig: [String: VciConfig] {
    (vciConfig ?? [:]).mapValues { config in
      VciConfig(config: config, order: 0)
    }
  }

  var vciConfig: [String: OpenId4VciConfiguration]? {
    let openId4VciConfigurations: [OpenId4VciConfiguration] = [
      .init(
        credentialIssuerURL: configLogic.vciIssuerURL.map(\.trimmingTrailingSlash),
        clientId: getBundleNullableValue(key: "VCI_CLIENT_ID"),
        keyAttestationsConfig: .init(walletAttestationsProvider: walletKitAttestationProvider),
        authFlowRedirectionURI: URL(string: vciRedirectURI)!,
        allowPlainJwtProof: true,
        requireDpop: true,
        issuerMetadataPolicy: trustConfiguration.issuerMetadataPolicy,
        encryptionSupportConfig: Self.responseEncryptionConfig
      )
    ]
    return openId4VciConfigurations.reduce(
      into: [String: OpenId4VciConfiguration]()
    ) { dict, config in
      guard
        let issuer = config.credentialIssuerURL,
        let url = URL(string: issuer),
        let host = url.host
      else {
        return
      }
      dict[host] = config
    }
  }

  // HAIP: ECDH-ES on P-256 for alg, A256GCM or A128GCM for enc (the issuer's order picks between them). RSA is disabled.
  // Unregistered issuers get a copy of this configuration and inherit the setting.
  static let responseEncryptionAlgorithms: [JWEAlgorithm] = [JWEAlgorithm(.ECDH_ES)]
  static let responseEncryptionMethods: [JOSEEncryptionMethod] = [JOSEEncryptionMethod(.A256GCM), JOSEEncryptionMethod(.A128GCM)]

  static let responseEncryptionConfig = EncryptionSupportConfig(
    credentialResponseEncryptionPolicy: .supported,
    ecConfig: EcConfig(ecKeyCurve: .P256, supportedJWEAlgorithms: responseEncryptionAlgorithms),
    rsaConfig: nil,
    supportedEncryptionMethods: responseEncryptionMethods
  )

  var vpConfig: OpenId4VpConfiguration {
    .init(
      clientIdSchemes: [.x509SanDns, .x509Hash],
      preferredResponseMode: .directPostJWT,
      validateRegistrationCertificate: !AppEnvironment.skipsRegistrationCertificateValidation
    )
  }

  private static let crlChecker = CRLRevocationChecker()

  var trustConfiguration: TrustConfiguration {
    let loteLocations = SupportedLists<NSString>(
      pidProviders: "https://trustedlist.serviceproviders.eudiw.dev/LOTE/json/PIDProviders.jwt",
      walletProviders: nil,
      wrpacProviders: "https://trustedlist.serviceproviders.eudiw.dev/LOTE/json/WRPACProviders.jwt",
      wrprcProviders: nil,
      pubEaaProviders: "https://trustedlist.serviceproviders.eudiw.dev/LOTE/json/PubEAAProviders.jwt",
      qeaProviders: nil,
      eaaProviders: [:]
    )

    let classifications: EtsiContextTypeMappings = [
      DocumentTypeIdentifier.mDocPid.rawValue: .pid,
      DocumentTypeIdentifier.sdJwtPid.rawValue: .pid
    ]
    return TrustConfiguration(
      trustSource: .staticList(
        StaticListTrustSource(
          rootCertificates: staticRootCertificates,
          revocationPolicy: .crlOnly,
          crlChecker: Self.crlChecker
        )
      ),
      fallbackTrustSource: .etsi(
        EtsiTrustSource(
          loteLocations: loteLocations,
          contextTypeMappings: classifications,
          revocationPolicy: .crlOnly,
          crlChecker: Self.crlChecker
        )
      ),
      // No trust anchor is configured for the PID signer yet, so issued-document chains are only logged
      defaultPolicy: .warning,
      // Applies to credential offers, including EAA issuers; the PID issuer reuses `issuerMetadataPolicy` in `vciConfig`
      requireSignedMetadata: true,
      statusTrustPolicy: .enforce,
      readerTrustPolicy: .enforce,
      wrprcVpTrustPolicy: .enforce,
      wrprcVciTrustPolicy: .enforce
    )
  }

  var staticRootCertificates: [Data] {
    guard let certificateURLs = Bundle.main.urls(forResourcesWithExtension: "der", subdirectory: "Wallet/Certificates") else {
      return []
    }
    return certificateURLs
      .filter { !$0.lastPathComponent.hasPrefix("pidp-tls-pin-") }
      .compactMap { try? Data(contentsOf: $0) }
  }

  var documentStorageServiceName: String {
    guard let identifier = Bundle.main.bundleIdentifier else {
      return "eudi.document.storage"
    }
    return "\(identifier).eudi.document.storage"
  }

  var logFileName: String? {
    [.DEV, .SANDBOX].contains(AppBuildVariant.current) ? "eudi-ios-wallet-logs.txt" : nil
  }

  var documentsCategories: DocumentCategories {
    [
      .Government: [
        .mDocPid,
        .sdJwtPid,
        .mDocPseudonym,
        .other(formatType: "org.iso.18013.5.1.mDL"),
        .other(formatType: "eu.europa.ec.eudi.tax.1"),
        .other(formatType: "eu.europa.ec.eudi.pseudonym.age_over_18.deferred_endpoint")
      ],
      .Travel: [
        .other(formatType: "org.iso.23220.2.photoid.1"),
        .other(formatType: "org.iso.18013.5.1.reservation")
      ],
      .Finance: [
        .other(formatType: "eu.europa.ec.eudi.iban.1")
      ],
      .Education: [],
      .Health: [
        .other(formatType: "eu.europa.ec.eudi.hiid.1"),
        .other(formatType: "eu.europa.ec.eudi.ehic.1")
      ],
      .SocialSecurity: [
        .other(formatType: "eu.europa.ec.eudi.samplepda1.1")
      ],
      .Retail: [
        .other(formatType: "eu.europa.ec.eudi.loyalty.1"),
        .other(formatType: "eu.europa.ec.eudi.msisdn.1")
      ],
      .Other: [
        .other(formatType: "eu.europa.ec.eudi.por.1")
      ]
    ]
  }

  var documentIssuanceConfig: DocumentIssuanceConfig {
    DocumentIssuanceConfig(
      defaultRule: DocumentIssuanceRule(
        policy: .rotateUse,
        numberOfCredentials: 1
      ),
      documentSpecificRules: [
        DocumentTypeIdentifier.mDocPid: DocumentIssuanceRule(
          policy: .oneTimeUse,
          numberOfCredentials: getBundleValue(key: "BATCH_COUNT").toInteger() ?? 5
        ),
        DocumentTypeIdentifier.sdJwtPid: DocumentIssuanceRule(
          policy: .oneTimeUse,
          numberOfCredentials: getBundleValue(key: "BATCH_COUNT").toInteger() ?? 5
        )
      ]
    )
  }

  var batchRefreshThreshold: Int {
    1
  }
}
