//
//  HTTPSignatureServiceTests.swift
//  logic-api
//
//  Created by Tamas Dancsi on 18.02.26.
//

import Foundation
import Security
import Testing

@testable import logic_api

struct HTTPSignatureServiceTests {

  @Test
  func createContentDigest_ReturnsExpectedFormat() {
    let service = HTTPSignatureServiceImpl()
    let digest = service.createContentDigest(for: Data("abc".utf8))
    #expect(digest == "sha-256=:ungWv48Bz+pBQUDeXa4iI7ADYaOWF3qctBD/YfIAFa0=:")
  }

  @Test
  func createSignatureInput_BuildsExpectedHeaderValueFormat() {
    let service = HTTPSignatureServiceImpl()
    let value = service.createSignatureInput(
      fields: ["@method", "@path", "auth-challenge"],
      keyID: "wi-mdvm-auth-key",
      algorithm: "ecdsa-p256-sha256"
    )

    #expect(value.hasPrefix("(\"@method\" \"@path\" \"auth-challenge\");keyid=\"wi-mdvm-auth-key\";alg=\"ecdsa-p256-sha256\";created="))
    let createdPart = value.components(separatedBy: ";created=").last ?? ""
    #expect(Int(createdPart) != nil)
  }

  @Test
  func createSignatureBase_BuildsCanonicalLines() {
    let service = HTTPSignatureServiceImpl()
    let base = service.createSignatureBase(
      method: "POST",
      path: "/v1/mdvm/ios/register",
      signedHeaders: [
        ("auth-challenge", "challenge"),
        ("mdvm-token", ""),
        ("content-digest", "sha-256=:abc:"),
        ("skip-integrity-checks", "true")
      ],
      signatureInput: "(\"@method\");keyid=\"k\";alg=\"a\";created=1"
    )

    #expect(
      base == "\"@method\": POST\n\"@path\": /v1/mdvm/ios/register\n\"auth-challenge\": challenge\n\"mdvm-token\": \n\"content-digest\": sha-256=:abc:\n\"skip-integrity-checks\": true\n\"@signature-params\": (\"@method\");keyid=\"k\";alg=\"a\";created=1"
    )
  }

  @Test
  func createSignature_ThrowsWhenKeyCannotSign() throws {
    let service = HTTPSignatureServiceImpl()
    let privateKey = try makePrivateKey()
    guard let publicKey = SecKeyCopyPublicKey(privateKey) else {
      Issue.record("Expected generated public key")
      return
    }

    #expect(throws: HTTPMessageSigningError.signingFailed) {
      _ = try service.createSignature(
        base: "test-base",
        privateKey: publicKey, // Passing a public key should trigger signing error
        algorithm: .ecdsaSignatureMessageX962SHA256
      )
    }
  }

  @Test
  func makeSignatureHeaders_BuildsSingleSignatureHeaders() throws {
    let service = HTTPSignatureServiceImpl()
    let headers = try service.makeSignatureHeaders(
      context: HTTPMessageSigningContext(
        method: RWSCAConstants.Header.Method.post,
        path: RWSCAConstants.Path.register,
        headers: [
          RWSCAConstants.Header.authChallenge: "challenge",
          RWSCAConstants.Header.mdvmToken: "mdvm-token"
        ],
        contentTypeHeader: nil
      ),
      signatures: [
        HTTPMessageSignature(
          name: RWSCAConstants.Signature.nameAuthSig,
          keyID: RWSCAConstants.Signature.keyID,
          algorithm: RWSCAConstants.Signature.algorithm,
          fields: RWSCAConstants.Signature.registerFields,
          privateKey: try makePrivateKey()
        )
      ]
    )

    #expect(headers[RWSCAConstants.Header.contentType] == nil)
    #expect(headers[MDVMConstants.Header.signatureInput]?.contains(RWSCAConstants.Signature.nameAuthSig) == true)
    #expect(headers[MDVMConstants.Header.signature]?.contains(RWSCAConstants.Signature.nameAuthSig) == true)
  }

  @Test
  func makeSignatureHeaders_BuildsDoubleSignatureHeaders() throws {
    let service = HTTPSignatureServiceImpl()
    let headers = try service.makeSignatureHeaders(
      context: HTTPMessageSigningContext(
        method: RWSCAConstants.Header.Method.post,
        path: RWSCAConstants.Path.initializePinAndStartPinSession,
        headers: [
          RWSCAConstants.Header.authChallenge: "challenge",
          RWSCAConstants.Header.mdvmToken: "mdvm-token",
          RWSCAConstants.Header.rwscaAccountId: "rwsca-id",
          RWSCAConstants.Header.contentDigest: "sha-256=:digest:"
        ],
        contentTypeHeader: HTTPHeader(
          name: RWSCAConstants.Header.contentType,
          value: RWSCAConstants.Header.ContentType.json
        )
      ),
      signatures: [
        HTTPMessageSignature(
          name: RWSCAConstants.Signature.nameAuthSig,
          keyID: RWSCAConstants.Signature.keyID,
          algorithm: RWSCAConstants.Signature.algorithm,
          fields: RWSCAConstants.Signature.initializePinAndStartPinSessionFields,
          privateKey: try makePrivateKey()
        ),
        HTTPMessageSignature(
          name: RWSCAConstants.Signature.namePinSig,
          keyID: RWSCAConstants.Signature.keyIDPin,
          algorithm: RWSCAConstants.Signature.algorithm,
          fields: RWSCAConstants.Signature.initializePinAndStartPinSessionFields,
          privateKey: try makePrivateKey()
        )
      ]
    )

    #expect(headers[RWSCAConstants.Header.contentType] == RWSCAConstants.Header.ContentType.json)
    #expect(headers[MDVMConstants.Header.signatureInput]?.contains(RWSCAConstants.Signature.nameAuthSig) == true)
    #expect(headers[MDVMConstants.Header.signatureInput]?.contains(RWSCAConstants.Signature.namePinSig) == true)
    #expect(headers[MDVMConstants.Header.signature]?.contains(RWSCAConstants.Signature.nameAuthSig) == true)
    #expect(headers[MDVMConstants.Header.signature]?.contains(RWSCAConstants.Signature.namePinSig) == true)
  }

  @Test
  func makeSignatureHeaders_ThrowsWhenRequiredHeaderIsMissingForSingleSignature() throws {
    let service = HTTPSignatureServiceImpl()

    #expect(throws: HTTPMessageSigningError.missingSignedHeader(RWSCAConstants.Header.mdvmToken)) {
      try service.makeSignatureHeaders(
        context: HTTPMessageSigningContext(
          method: RWSCAConstants.Header.Method.post,
          path: RWSCAConstants.Path.register,
          headers: [
            RWSCAConstants.Header.authChallenge: "challenge"
          ],
          contentTypeHeader: nil
        ),
        signatures: [
          HTTPMessageSignature(
            name: RWSCAConstants.Signature.nameAuthSig,
            keyID: RWSCAConstants.Signature.keyID,
            algorithm: RWSCAConstants.Signature.algorithm,
            fields: RWSCAConstants.Signature.registerFields,
            privateKey: try makePrivateKey()
          )
        ]
      )
    }
  }

  @Test
  func makeSignatureHeaders_ThrowsWhenRequiredHeaderIsMissingForDoubleSignature() throws {
    let service = HTTPSignatureServiceImpl()

    #expect(throws: HTTPMessageSigningError.missingSignedHeader("content-digest")) {
      try service.makeSignatureHeaders(
        context: HTTPMessageSigningContext(
          method: RWSCAConstants.Header.Method.post,
          path: RWSCAConstants.Path.initializePinAndStartPinSession,
          headers: [
            RWSCAConstants.Header.authChallenge: "challenge",
            RWSCAConstants.Header.mdvmToken: "mdvm-token",
            RWSCAConstants.Header.rwscaAccountId: "rwsca-id"
          ],
          contentTypeHeader: HTTPHeader(
            name: RWSCAConstants.Header.contentType,
            value: RWSCAConstants.Header.ContentType.json
          )
        ),
        signatures: [
          HTTPMessageSignature(
            name: RWSCAConstants.Signature.nameAuthSig,
            keyID: RWSCAConstants.Signature.keyID,
            algorithm: RWSCAConstants.Signature.algorithm,
            fields: RWSCAConstants.Signature.initializePinAndStartPinSessionFields,
            privateKey: try makePrivateKey()
          ),
          HTTPMessageSignature(
            name: RWSCAConstants.Signature.namePinSig,
            keyID: RWSCAConstants.Signature.keyIDPin,
            algorithm: RWSCAConstants.Signature.algorithm,
            fields: RWSCAConstants.Signature.initializePinAndStartPinSessionFields,
            privateKey: try makePrivateKey()
          )
        ]
      )
    }
  }

  @Test
  func makeSignatureHeaders_MapsSigningErrors() throws {
    let service = HTTPSignatureServiceImpl()
    let privateKey = try makePrivateKey()
    guard let publicKey = SecKeyCopyPublicKey(privateKey) else {
      Issue.record("Expected generated public key")
      return
    }

    #expect(throws: HTTPMessageSigningError.signingFailed) {
      try service.makeSignatureHeaders(
        context: HTTPMessageSigningContext(
          method: RWSCAConstants.Header.Method.post,
          path: RWSCAConstants.Path.initializePinAndStartPinSession,
          headers: [
            RWSCAConstants.Header.authChallenge: "challenge",
            RWSCAConstants.Header.mdvmToken: "mdvm-token",
            RWSCAConstants.Header.rwscaAccountId: "rwsca-id",
            RWSCAConstants.Header.contentDigest: "sha-256=:digest:"
          ],
          contentTypeHeader: HTTPHeader(
            name: RWSCAConstants.Header.contentType,
            value: RWSCAConstants.Header.ContentType.json
          )
        ),
        signatures: [
          HTTPMessageSignature(
            name: RWSCAConstants.Signature.nameAuthSig,
            keyID: RWSCAConstants.Signature.keyID,
            algorithm: RWSCAConstants.Signature.algorithm,
            fields: RWSCAConstants.Signature.initializePinAndStartPinSessionFields,
            privateKey: publicKey
          ),
          HTTPMessageSignature(
            name: RWSCAConstants.Signature.namePinSig,
            keyID: RWSCAConstants.Signature.keyIDPin,
            algorithm: RWSCAConstants.Signature.algorithm,
            fields: RWSCAConstants.Signature.initializePinAndStartPinSessionFields,
            privateKey: try makePrivateKey()
          )
        ]
      )
    }
  }

  @Test
  func makeSignatureHeaders_ThrowsWhenNoSignaturesAreProvided() throws {
    let service = HTTPSignatureServiceImpl()

    #expect(throws: HTTPMessageSigningError.missingSignatures) {
      try service.makeSignatureHeaders(
        context: HTTPMessageSigningContext(
          method: "POST",
          path: "/v1/example",
          headers: [:],
          contentTypeHeader: nil
        ),
        signatures: []
      )
    }
  }

  private func makePrivateKey() throws -> SecKey {
    let attributes: [String: Any] = [
      kSecAttrKeyType as String: kSecAttrKeyTypeECSECPrimeRandom,
      kSecAttrKeySizeInBits as String: 256
    ]
    var error: Unmanaged<CFError>?
    guard let key = SecKeyCreateRandomKey(attributes as CFDictionary, &error) else {
      throw error?.takeRetainedValue() ?? NSError(domain: "HTTPSignatureServiceTests", code: -1)
    }
    return key
  }
}
