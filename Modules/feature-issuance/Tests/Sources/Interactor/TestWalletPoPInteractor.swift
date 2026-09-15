//
//  TestWalletPoPInteractor.swift
//  feature-issuance
//
//  Created by Pankaj Sachdeva on 02.02.25.
//

@testable import logic_test
@testable import logic_business

final class TestWalletPoPInteractor: XCTestCase {
    var interactor: WalletPoPControllerImpl!
    var mockPrivateKey: SecKey!
    var mockPublicKey: SecKey!
    
    override func setUp() {
        super.setUp()
        interactor = WalletPoPControllerImpl()
        
        // Generate a mock private key for testing
        let attributes: [String: Any] = [
            kSecAttrKeyType as String: kSecAttrKeyTypeECSECPrimeRandom,
            kSecAttrKeySizeInBits as String: 256
        ]
        var error: Unmanaged<CFError>?
        guard let privateKey = SecKeyCreateRandomKey(attributes as CFDictionary, &error) else {
            XCTFail("Failed to create mock private key: \(error!.takeRetainedValue())")
            return
        }
        mockPrivateKey = privateKey
        
        // Generate a mock public key for testing
        guard let publicKey = SecKeyCopyPublicKey(privateKey) else {
            XCTFail("Failed to create mock public key")
            return
        }
        mockPublicKey = publicKey
    }

    override func tearDown() {
        interactor = nil
        mockPrivateKey = nil
        mockPublicKey = nil
        super.tearDown()
    }
    
    func testGetProofOfPossession_Success() {
        let challenge = "test-challenge"
        
        do {
            let pop = try interactor.getProofOfPossession(
                claimType: .wiPop,
                challenge: challenge,
                privateKey: mockPrivateKey,
                addPublicKey: true,
                issuer: "mock_issuer",
                audience: "mock_audience"
            )
            XCTAssertFalse(pop.isEmpty, "Proof of Possession should not be empty")
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    func testGetProofOfPossession_EmptyChallenge() {
        let challenge = ""
        
        XCTAssertThrowsError(try interactor.getProofOfPossession(
            claimType: .wiPop,
            challenge: challenge,
            privateKey: mockPrivateKey,
            addPublicKey: true,
            issuer: "mock_issuer",
            audience: "mock_audience"
        )) { error in
            XCTAssertEqual(error as? PoPGenerationError, .missingChallenge)
        }
    }

    func testGetProofOfPossession_InvalidPrivateKey() {
      let challenge = "test-challenge"
      _ = createInvalidSecKeyMock()
      
      XCTAssertThrowsError(try interactor.getProofOfPossession(
          claimType: .wiPop,
          challenge: challenge,
          privateKey: mockPublicKey,
          addPublicKey: true,
          issuer: "mock_issuer",
          audience: "mock_audience"
      )) { error in
          XCTAssertEqual(error as? PoPGenerationError, .jwsGenerationFailed)
      }
  }
    
    func testGetSerializedJWT_Success() {
        let serializedString = "eyJhbGciOiJFUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJ0ZXN0Iiwic3ViIjoidGVzdCIsImNuZiI6eyJqd2siOnsia3R5IjoiRUMiLCJ1c2UiOiJzaWciLCJjcnYiOiJQLTI1NiIsIngiOiJ0ZXN0IiwieSI6InRlc3QifX0sImlhdCI6MTY1MTI3MzAwMCwiZXhwIjoxNjUxMjc2NjAwfQ.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c"
        
        do {
            let jwt = try interactor.getSerializedJWT(serializedString: serializedString, privateKey: mockPrivateKey)
            XCTAssertNotNil(jwt, "JWT should not be nil")
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testGetSerializedJWT_InvalidSerializedString() {
        let invalidSerializedString = "invalid-jwt-string"
        
        XCTAssertThrowsError(try interactor.getSerializedJWT(serializedString: invalidSerializedString, privateKey: mockPrivateKey)) { error in
            XCTAssertEqual(error as? PoPGenerationError, .invalidJWT)
        }
    }
    
    func testGetPublicKeyJWK_Success() {
        let algo = "ES256"
        
        do {
            let jwk = try interactor.getPublicKeyJWK(algo: algo, privateKey: mockPrivateKey)
            XCTAssertNotNil(jwk, "JWK should not be nil")
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
  
  func createInvalidSecKeyMock() -> SecKey? {
      // Create a public key instead of a private key to simulate invalid use
      let attributes: [String: Any] = [
          kSecAttrKeyType as String:            kSecAttrKeyTypeRSA,
          kSecAttrKeyClass as String:           kSecAttrKeyClassPublic, // <- public key used for signing will fail
          kSecAttrKeySizeInBits as String:      2048,
          kSecReturnPersistentRef as String:    true
      ]

      return SecKeyCreateRandomKey(attributes as CFDictionary, nil)
  }
}
