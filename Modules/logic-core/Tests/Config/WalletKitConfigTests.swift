//
//  WalletKitConfigTests.swift
//  WalletKitConfigTests
//
//  Created by Tamas Dancsi  on 05.05.26.
//

import XCTest
import Cuckoo
import OpenID4VCI
import logic_business
@testable import logic_core

final class WalletKitConfigTests: XCTestCase {

  func testPIDIssuerName_WhenConfigLogicHasIssuerName_ThenReturnsIssuerName() {
    let configLogic = MockConfigLogic()
    stub(configLogic) { mock in
      when(mock.vciIssuerName.get).thenReturn("PID issuer")
    }
    let sut = makeSUT(configLogic: configLogic)

    XCTAssertEqual(sut.pidIssuerName, "PID issuer")
  }

  func testDocumentStorageServiceName_WhenRequested_ThenReturnsDocumentStorageSuffix() {
    let sut = makeSUT()

    XCTAssertTrue(sut.documentStorageServiceName.hasSuffix(".eudi.document.storage"))
  }

  func testGetBundleValue_WhenBundleKeyExists_ThenReturnsBundleValue() {
    let sut = makeSUT()

    XCTAssertEqual(
      sut.getBundleValue(key: "CFBundleShortVersionString"),
      "CFBundleShortVersionString".valueFromBundle
    )
  }

  func testDocumentCategories_WhenRequested_ThenGroupsPIDDocumentsUnderGovernment() {
    let categories = makeSUT().documentsCategories

    XCTAssertEqual(categories.keys.first, .Government)
    XCTAssertTrue(categories[.Government]?.contains(.mDocPid) == true)
    XCTAssertTrue(categories[.Government]?.contains(.sdJwtPid) == true)
  }

  func testDocumentIssuanceConfig_WhenRequested_ThenUsesOneTimeRulesForPIDDocuments() {
    let config = makeSUT().documentIssuanceConfig

    XCTAssertEqual(config.rule(for: .mDocPid).numberOfCredentials, 5)
    XCTAssertEqual(config.rule(for: .sdJwtPid).numberOfCredentials, 5)
    XCTAssertEqual(config.rule(for: nil).numberOfCredentials, 1)
  }

  func testVciConfig_WhenBuilt_ThenUsesTheApprovedResponseEncryptionAllowlist() throws {
    let configLogic = MockConfigLogic()
    stub(configLogic) { mock in
      when(mock.vciIssuerURL.get).thenReturn("https://issuer.example.com")
    }
    let config = try XCTUnwrap(makeSUT(configLogic: configLogic).vciConfig?["issuer.example.com"])
    let encryption = config.encryptionSupportConfig

    XCTAssertNil(encryption.rsaConfig)
    XCTAssertEqual(encryption.ecConfig?.ecKeyCurve, .P256)
    XCTAssertEqual(encryption.supportedEncryptionAlgorithms.map(\.name), Self.approvedAlgorithms)
    XCTAssertEqual(encryption.supportedEncryptionMethods.map(\.name), Self.approvedMethods)
  }

  func testResponseEncryptionConfig_WhenRequested_ThenDefersEncryptionRequirementToIssuerMetadata() {
    XCTAssertEqual(WalletKitConfigImpl.responseEncryptionConfig.credentialResponseEncryptionPolicy, .supported)
  }

  func testResponseEncryptionConfig_WhenRequested_ThenExcludesWeakJWEPrimitives() {
    let encryption = WalletKitConfigImpl.responseEncryptionConfig
    let algorithms = encryption.supportedEncryptionAlgorithms.map(\.name)
    let methods = encryption.supportedEncryptionMethods.map(\.name)

    let weakAlgorithms: [JWEAlgorithm.AlgorithmType] = [.RSA1_5, .RSA_OAEP, .RSA_OAEP_256, .A128KW, .DIR, .ECDH_ES_A128KW]
    let weakMethods: [JOSEEncryptionMethod.EncryptionMethodType] = [.A128CBC_HS256, .A192CBC_HS384, .A256CBC_HS512]

    for weak in weakAlgorithms.map(\.rawValue) {
      XCTAssertFalse(algorithms.contains(weak), "\(weak) must not be allowed")
    }
    for weak in weakMethods.map(\.rawValue) {
      XCTAssertFalse(methods.contains(weak), "\(weak) must not be allowed")
    }
  }

  func testResponseEncryptionAllowlist_WhenCheckedAgainstOpenID4VCI_ThenIsStillSupported() {
    let supportedAlgorithms = EcConfig.platformSupportedAlgorithms.map(\.name)
    let supportedMethods = EncryptionSupportConfig.platformSupportedEncryptionMethods.map(\.name)

    XCTAssertTrue(Set(Self.approvedAlgorithms).isSubset(of: supportedAlgorithms))
    XCTAssertTrue(Set(Self.approvedMethods).isSubset(of: supportedMethods))
  }

  func testTrustConfiguration_WhenBuilt_ThenEnforcesStatusListTokenTrust() {
    XCTAssertEqual(makeSUT().trustConfiguration.statusTrustPolicy, .enforce)
  }

  func testTrustConfiguration_WhenBuilt_ThenEnforcesRegistrationCertificateTrustForPresentationAndIssuance() {
    let trustConfiguration = makeSUT().trustConfiguration

    XCTAssertEqual(trustConfiguration.wrprcVpTrustPolicy, .enforce)
    XCTAssertEqual(trustConfiguration.wrprcVciTrustPolicy, .enforce)
  }

  func testTrustConfiguration_WhenBuilt_ThenEnforcesReaderCertificateTrust() {
    XCTAssertEqual(makeSUT().trustConfiguration.readerTrustPolicy, .enforce)
  }

  func testTrustConfiguration_WhenBuilt_ThenOnlyWarnsOnUntrustedIssuedDocumentSigners() {
    let trustConfiguration = makeSUT().trustConfiguration

    XCTAssertEqual(trustConfiguration.defaultPolicy, .warning)
    XCTAssertEqual(trustConfiguration.policy(for: DocumentTypeIdentifier.mDocPid.rawValue), .warning)
    XCTAssertEqual(trustConfiguration.policy(for: DocumentTypeIdentifier.sdJwtPid.rawValue), .warning)
  }

  private static let approvedAlgorithms = ["ECDH-ES"]
  private static let approvedMethods = ["A256GCM", "A128GCM"]

  private func makeSUT(configLogic: MockConfigLogic = MockConfigLogic()) -> WalletKitConfigImpl {
    WalletKitConfigImpl(
      configLogic: configLogic,
      walletKitAttestationProvider: WalletAttestationProviderImpl(
        wiaIssuanceService: MockWIAIssuanceService(),
        secureEnclaveController: MockSecureEnclaveController()
      ),
      vciRedirectURI: "eudi-openid4ci://authorize"
    )
  }
}
