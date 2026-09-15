//
//  WalletAttestationsProviderTests.swift
//  logic-core
//
//  Created by Tamas Dancsi on 30.05.26.
//

import Testing
import Foundation
import JOSESwift
import OpenID4VCI
import Security

@testable import logic_core
@testable import logic_business
@testable import logic_test

struct WalletAttestationsProviderTests {

  private let wiaPrivateKey = makePrivateKey()

  @Test
  func getWalletAttestation_WithSecKey_CallsWIAIssuanceServiceAndReturnsToken() async throws {
    let wiaService = MockWIAIssuanceService()
    stub(wiaService) { mock in
      when(mock.issueWIA(wiaPrivateKey: any())).thenReturn("issued-wia-token")
    }
    let sut = makeSUT(wiaIssuanceService: wiaService)

    let result = try await sut.getWalletAttestation(signingKey: .secKey(wiaPrivateKey))

    #expect(result == "issued-wia-token")
    verify(wiaService).issueWIA(wiaPrivateKey: any())
  }

  @Test
  func getWalletAttestation_WithUnsupportedSigningKey_ThrowsError() async throws {
    let wiaService = MockWIAIssuanceService()
    let sut = makeSUT(wiaIssuanceService: wiaService)

    await #expect(throws: (any Error).self) {
      _ = try await sut.getWalletAttestation(signingKey: .custom(StubAsyncSigner(publicKey: try makeJWK(from: wiaPrivateKey))))
    }
    verify(wiaService, never()).issueWIA(wiaPrivateKey: any())
  }

  @Test
  func getKeysAttestation_WhenDocTypeHasStoredWTE_ReturnsThenDeletes() async throws {
    let secureEnclaveController = MockSecureEnclaveController()
    stub(secureEnclaveController) { mock in
      when(mock.retrieveStringFromKeychain(keyTag: equal(to: .custom("docType")))).thenReturn("stored-wte")
      when(mock.deleteKeychainItem(keyTag: equal(to: .custom("docType")))).thenDoNothing()
    }
    let sut = WalletAttestationProviderImpl(
      wiaIssuanceService: MockWIAIssuanceService(),
      secureEnclaveController: secureEnclaveController
    )

    let result = try await sut.getKeysAttestation(docType: "docType")

    #expect(result == "stored-wte")
    verify(secureEnclaveController).deleteKeychainItem(keyTag: equal(to: .custom("docType")))
  }

  @Test
  func getKeysAttestation_WhenDocTypeHasNoStoredWTE_ReturnsNil() async throws {
    let secureEnclaveController = MockSecureEnclaveController()
    stub(secureEnclaveController) { mock in
      when(mock.retrieveStringFromKeychain(keyTag: equal(to: .custom("docType")))).thenReturn(nil)
      when(mock.deleteKeychainItem(keyTag: equal(to: .custom("docType")))).thenDoNothing()
    }
    let sut = WalletAttestationProviderImpl(
      wiaIssuanceService: MockWIAIssuanceService(),
      secureEnclaveController: secureEnclaveController
    )

    let result = try await sut.getKeysAttestation(docType: "docType")

    #expect(result == nil)
  }

  // MARK: - Helpers

  private func makeSUT(wiaIssuanceService: WIAIssuanceService) -> WalletAttestationProviderImpl {
    WalletAttestationProviderImpl(
      wiaIssuanceService: wiaIssuanceService,
      secureEnclaveController: MockSecureEnclaveController()
    )
  }

  private static func makePrivateKey() -> SecKey {
    let attributes: [String: Any] = [
      kSecAttrKeyType as String: kSecAttrKeyTypeECSECPrimeRandom,
      kSecAttrKeySizeInBits as String: 256
    ]
    var error: Unmanaged<CFError>?
    guard let key = SecKeyCreateRandomKey(attributes as CFDictionary, &error) else {
      fatalError("Failed to create key: \(String(describing: error))")
    }
    return key
  }

  /// Minimal `AsyncSignerProtocol` stub for the `.custom` signing-key case (unsupported by the provider).
  private struct StubAsyncSigner: AsyncSignerProtocol {
    let publicKey: any JWK
    func signAsync(_ header: Data, _ payload: Data) async throws -> Data { Data() }
  }

  private func makeJWK(from privateKey: SecKey) throws -> any JWK {
    guard let publicKey = SecKeyCopyPublicKey(privateKey) else {
      throw NSError(domain: "TestHelpers", code: -1)
    }
    return try ECPublicKey(publicKey: publicKey, additionalParameters: ["alg": "ES256", "use": "sig", "kid": "test-kid"])
  }
}
