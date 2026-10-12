//
//  IssuerMetadataVerificationTests.swift
//  logic-core-tests
//

import XCTest
import Cuckoo
import EudiWalletKit
import OpenID4VCI
import logic_business
@testable import logic_core

final class IssuerMetadataVerificationTests: XCTestCase {

  // MARK: - Error mapping

  func testIsIssuerMetadataVerificationFailure_WhenSignedMetadataIsInvalid_ThenReturnsTrue() {
    let error = CredentialIssuerMetadataError.invalidSignedMetadata("Failed to verify chain (.byCertificateChain)")

    XCTAssertTrue(error.isIssuerMetadataVerificationFailure)
  }

  func testIsIssuerMetadataVerificationFailure_WhenIssuerReturnsJsonForRequiredSignedMetadata_ThenReturnsTrue() {
    XCTAssertTrue(CredentialIssuerMetadataError.missingRightContentTypeHeader.isIssuerMetadataVerificationFailure)
  }

  func testIsIssuerMetadataVerificationFailure_WhenWrappedInWalletError_ThenReturnsTrue() {
    let error = WalletError(
      description: "Failed to resolve issuer metadata",
      code: .issuerMetadataResolutionFailed,
      innerError: CredentialIssuerMetadataError.nonParseableSignedMetadata
    )

    XCTAssertTrue(error.isIssuerMetadataVerificationFailure)
  }

  func testIsIssuerMetadataVerificationFailure_WhenMetadataCannotBeFetched_ThenReturnsFalse() {
    let error = WalletError(
      description: "Failed to resolve issuer metadata",
      code: .issuerMetadataResolutionFailed,
      innerError: CredentialIssuerMetadataError.unableToFetchCredentialIssuerMetadata(cause: URLError(.notConnectedToInternet))
    )

    XCTAssertFalse(error.isIssuerMetadataVerificationFailure)
  }

  func testIsIssuerMetadataVerificationFailure_WhenUnrelatedError_ThenReturnsFalse() {
    XCTAssertFalse(WalletCoreError.unableToIssueAndStore.isIssuerMetadataVerificationFailure)
  }

  // MARK: - Issuer identifier

  func testTrimmingTrailingSlash_WhenUrlEndsWithSlash_ThenRemovesIt() {
    XCTAssertEqual("https://issuer.example.com/".trimmingTrailingSlash, "https://issuer.example.com")
    XCTAssertEqual("https://issuer.example.com".trimmingTrailingSlash, "https://issuer.example.com")
  }

  // MARK: - Policies

  func testVciConfig_WhenBuilt_ThenPidIssuerRequiresSignedMetadataWithoutTrailingSlash() throws {
    try XCTSkipIf("VCI_REDIRECT_URI".valueFromBundle.isEmpty, "Needs the app's Info.plist (VCI_REDIRECT_URI)")
    let configLogic = MockConfigLogic()
    stub(configLogic) { mock in
      when(mock.vciIssuerURL.get).thenReturn("https://issuer.example.com/")
    }

    let config = try XCTUnwrap(makeSUT(configLogic: configLogic).vciConfig?["issuer.example.com"])

    XCTAssertEqual(config.credentialIssuerURL, "https://issuer.example.com")
    guard case .requireSigned = config.issuerMetadataPolicy else {
      return XCTFail("PID issuer must require signed metadata")
    }
  }

  private func makeSUT(configLogic: MockConfigLogic = MockConfigLogic()) -> WalletKitConfigImpl {
    WalletKitConfigImpl(
      configLogic: configLogic,
      walletKitAttestationProvider: WalletAttestationProviderImpl(
        wiaIssuanceService: MockWIAIssuanceService(),
        secureEnclaveController: MockSecureEnclaveController()
      )
    )
  }
}
