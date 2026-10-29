//
//  WalletKitConfigTests.swift
//  WalletKitConfigTests
//
//  Created by Tamas Dancsi  on 05.05.26.
//

import XCTest
import Cuckoo
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

    XCTAssertEqual(config.rule(for: .mDocPid).numberOfCredentials, 10)
    XCTAssertEqual(config.rule(for: .sdJwtPid).numberOfCredentials, 10)
    XCTAssertEqual(config.rule(for: nil).numberOfCredentials, 1)
  }

  func testVciConfig_WhenBuilt_ThenDisablesRSAAndRequiresECResponseEncryption() throws {
    let configLogic = MockConfigLogic()
    stub(configLogic) { mock in
      when(mock.vciIssuerURL.get).thenReturn("https://issuer.example.com")
    }
    let config = try XCTUnwrap(makeSUT(configLogic: configLogic).vciConfig?["issuer.example.com"])
    let encryption = config.encryptionSupportConfig

    XCTAssertNil(encryption.rsaConfig)
    XCTAssertEqual(encryption.ecConfig?.ecKeyCurve, .P256)
    guard case .required = encryption.credentialResponseEncryptionPolicy else {
      return XCTFail("Expected required credential response encryption")
    }
  }

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
