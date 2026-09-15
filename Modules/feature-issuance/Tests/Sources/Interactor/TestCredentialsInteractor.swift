//
//  TestCredentialsInteractor.swift
//  feature-issuance
//
//  Created by Pankaj Sachdeva on 01.04.25.
//

@testable import logic_core
@testable import logic_test
@testable import feature_issuance
@testable import EudiWalletKit
@testable import feature_test
@testable import logic_business

import OpenID4VCI
import JOSESwift
import MdocDataModel18013

final class TestCredentialsInteractor: XCTestCase {
  private var mockWalletKitController: MockWalletKitController!
  private var mockWalletPoPController: FakeWalletPoPInteractor!
  private var mockSecureEnclaveController: MockSecureEnclaveController!
  private var interactor: CredentialsInteractor!
  
  override func setUp() {
      super.setUp()
      mockWalletKitController = MockWalletKitController()
      mockWalletPoPController = FakeWalletPoPInteractor()
      mockSecureEnclaveController = MockSecureEnclaveController()
      interactor = CredentialsInteractorImpl(
          walletKitController: mockWalletKitController,
          walletPoPController: mockWalletPoPController,
          secureEnclaveController: mockSecureEnclaveController
      )
  }
  
  override func tearDown() {
      interactor = nil
      mockWalletKitController = nil
      mockWalletPoPController = nil
      mockSecureEnclaveController = nil
      super.tearDown()
  }
  
  func testGetCredentialsWithRefreshToken_Success() async throws {
    let privateKey = SecKeyMock.generateFakePrivateKey()
        let expectedDocument = WalletStorage.Document(
            id: "123", 
            docType: "testType", 
            docDataFormat: .cbor, 
            data: Data(), 
            docKeyInfo: nil, 
            createdAt: nil, 
            metadata: nil, 
            displayName: "Test Document", 
            status: .pending
        )
    
    guard let serializedJWT = try mockWalletPoPController.getSerializedJWT(serializedString: "wia", privateKey: privateKey) else { throw PoPGenerationError.invalidJWT }
    
    guard let publicKeyJWK = try mockWalletPoPController.getPublicKeyJWK(algo: SignatureAlgorithm.ES256.rawValue, privateKey: privateKey, kid: nil) else { throw  PoPGenerationError.invalidJWT }
    
    let issuerDPoPConstructorParam = IssuerDPoPConstructorParam(clientID: "", expirationDuration: TimeInterval(3600), aud: nil, jti: UUID().uuidString, jwk: publicKeyJWK, privateKey: privateKey)
    
    guard let mockWalletKitController = mockWalletKitController else {
        XCTFail("MockWalletKitController is nil")
        return
    }
    
    stub(mockWalletKitController) { stub in
      when(stub.getCredentialsWithRefreshToken(credentialTypes: any(), issuerDPopConstructorParam: any())
        .thenReturn([expectedDocument]))
    }

    let documents = try await interactor.getCredentialsWithRefreshToken([CredentialType(documentType: "", scope: "", identifier: "", docDataFormat: .sdjwt)], privateKey: privateKey)

        XCTAssertEqual(documents.first?.id, expectedDocument.id)
        XCTAssertEqual(documents.first?.docType, expectedDocument.docType)
    }
  
  func testGetCredentialsWithRefreshToken_KeyGenerationFails() async throws {
    let privateKey = SecKeyMock.generateFakePrivateKey()
    mockWalletPoPController.throwSerializationError = true
    do {
      _ = try await interactor.getCredentialsWithRefreshToken(
        [CredentialType(documentType: "", scope: "", identifier: "", docDataFormat: .sdjwt)],
        privateKey: privateKey
      )
      XCTFail("Expected an error, but no error was thrown") // Fails if no error occurs
    } catch let error as PoPGenerationError {
      XCTAssertEqual(error, .keyGenerationFailed) // Verify expected error
    } catch {
      XCTFail("Unexpected error: \(error)") // Catches unexpected errors
    }
  }

  class FakeWalletPoPInteractor: WalletPoPController {

    
    func getProofOfPossessionForRWSCD(using parameters: logic_business.ProofofPossessionParams, withPublicKeyJWK: Bool) throws -> String {
      return "testPop"
    }
  
    func getProofOfPossessionForRWSCD(using parameters: logic_business.ProofofPossessionParams) throws -> String {
      return "testPop"
    }
  
    var throwSerializationError = false
  
    func getPublicKeyJWK(algo: String, privateKey: SecKey, kid: String?) throws -> (any JOSESwift.JWK)? {
      if throwSerializationError {
        throw PoPGenerationError.keyGenerationFailed
      }
  
      guard let publicKey = SecKeyCopyPublicKey(privateKey) else {
        throw JOSEError.invalidPublicKey
      }
  
      let jwk = try ECPublicKey(publicKey: publicKey, additionalParameters: ["alg": algo, "use": "sig", "kid": UUID().uuidString])
      return jwk
    }
  
    func getSerializedJWT(serializedString: String, privateKey: SecKey) throws -> JWTSerializedDto? {
      if throwSerializationError {
        throw PoPGenerationError.invalidJWT
      } else {
        return JWTSerializedDto(iss: "iss", sub: "sub", cnf: JWKDto(jwk: JWKDetailDto(
          kty: "kty",
          use: "use",
          crv: "crv",
          x: "x",
          y: "y"
        )), iat: 1, exp: 1)
      }
    }
  
    public let defaultPoP = "default_PoP"

    func getProofOfPossession(claimType: logic_business.WalletAttestationClaimTypes, challenge: String, privateKey: SecKey, addPublicKey: Bool, issuer: String, audience: String) throws -> String {
      return defaultPoP
    }

    func getProofOfPossession(using parameters: ProofofPossessionParams) throws -> String {
      return "rwscd_account_id"
    }
  }
}

extension IssuerDPoPConstructorParam: Equatable {
    public static func == (lhs: IssuerDPoPConstructorParam, rhs: IssuerDPoPConstructorParam) -> Bool {
        return lhs.clientID == rhs.clientID &&
               lhs.expirationDuration == rhs.expirationDuration &&
               lhs.aud == rhs.aud &&
               lhs.jti == rhs.jti &&
               areKeysEqual(lhs.privateKey, rhs.privateKey)
    }

    private static func areKeysEqual(_ key1: SecKey, _ key2: SecKey) -> Bool {
        guard let data1 = key1.externalRepresentation(),
              let data2 = key2.externalRepresentation() else {
            return false
        }
        return data1 == data2
    }
}

extension IssuerDPoPConstructorParam: Matchable {
    public var matcher: ParameterMatcher<IssuerDPoPConstructorParam> {
        return ParameterMatcher { other in
            return self == other
        }
    }
}

private extension SecKey {
    func externalRepresentation() -> Data? {
        var error: Unmanaged<CFError>?
        guard let data = SecKeyCopyExternalRepresentation(self, &error) else {
            return nil
        }
        return data as Data
    }
}

extension DocDataFormat: Matchable {
    public var matcher: ParameterMatcher<DocDataFormat> {
        return ParameterMatcher { testedValue in
            return self == testedValue
        }
    }
}
