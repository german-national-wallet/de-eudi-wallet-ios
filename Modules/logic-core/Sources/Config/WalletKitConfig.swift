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
import Security

struct VciConfig: Sendable {
  public let issuerUrl: String
  public let clientId: String
  public let redirectUri: URL
  public let walletProviderUrl: String
  public let walletOTLPUrl: String
}

public struct ReaderConfig {
  public let trustedCerts: [Data]

  var trustedRootCertificates: [x5chain] {
    trustedCerts.compactMap { certData in
      guard let cert = SecCertificateCreateWithData(nil, certData as CFData) else {
        return nil
      }
      return [cert]
    }
  }
}

protocol WalletKitConfig: Sendable {

  /**
   * VCI Configuration
   */
  var vciConfig: [String: OpenId4VciConfiguration]? { get }

  /**
   * VP Configuration
   */
  var vpConfig: OpenId4VpConfiguration { get }
  /**
   * Reader Configuration
   */
  var readerConfig: ReaderConfig { get }

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

  /**
   * Issuer credential-configuration identifier for the mso_mdoc PID credential.
   */
  var pidMsoMdocConfigId: String { get }

  /**
   * Issuer credential-configuration identifier for the SD-JWT PID credential.
   */
  var pidSdJwtConfigId: String { get }

  var batchRefreshThreshold: Int { get }
}

struct WalletKitConfigImpl: WalletKitConfig {
  let configLogic: ConfigLogic
  let walletKitAttestationProvider: WalletAttestationsProvider

  init(
    configLogic: ConfigLogic,
    walletKitAttestationProvider: WalletAttestationsProvider
  ) {
    self.configLogic = configLogic
    self.walletKitAttestationProvider = walletKitAttestationProvider
  }

  var userAuthenticationRequired: Bool {
    getBundleValue(key: "CORE_USER_AUTH").toBool()
  }

  var pidIssuerName: String {
    configLogic.vciIssuerName ?? ""
  }

  var pidMsoMdocConfigId: String {
    configLogic.pidMsoMdocConfigId
  }

  var pidSdJwtConfigId: String {
    configLogic.pidSdJwtConfigId
  }

  var vciConfig: [String: OpenId4VciConfiguration]? {
    let openId4VciConfigurations: [OpenId4VciConfiguration] = [
      .init(
        credentialIssuerURL: configLogic.vciIssuerURL,
        keyAttestationsConfig: .init(walletAttestationsProvider: walletKitAttestationProvider),
        authFlowRedirectionURI: URL(string: getBundleValue(key: "VCI_REDIRECT_URI"))!,
        requireDpop: true,
        cacheIssuerMetadata: true
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

  var vpConfig: OpenId4VpConfiguration {
    .init(
      clientIdSchemes: [.x509SanDns, .x509Hash],
      preferredResponseMode: .directPostJWT
    )
  }

  var readerConfig: ReaderConfig {
    guard let certificateURLs = Bundle.main.urls(forResourcesWithExtension: "der", subdirectory: "Wallet/Certificates") else {
      return .init(trustedCerts: [])
    }
    return .init(trustedCerts: certificateURLs.compactMap { try? Data(contentsOf: $0) })
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
          numberOfCredentials: getBundleValue(key: "BATCH_COUNT").toInteger() ?? 10
        ),
        DocumentTypeIdentifier.sdJwtPid: DocumentIssuanceRule(
          policy: .oneTimeUse,
          numberOfCredentials: getBundleValue(key: "BATCH_COUNT").toInteger() ?? 10
        )
      ]
    )
  }

  var batchRefreshThreshold: Int {
    2
  }
}
