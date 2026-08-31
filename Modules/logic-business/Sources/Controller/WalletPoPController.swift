//
//  WalletPoPController.swift
//  logic-business
//

import Foundation
import JOSESwift
import OpenID4VCI

public enum PoPGenerationError: Error, Equatable {
  case missingChallenge
  case invalidPrivateKey
  case keyGenerationFailed
  case saltGenerationFailed
  case cryptographicAlgorithmNotSupported
  case signerGenerationFailed
  case jwsGenerationFailed
  case invalidJWT
  case invalidPublicKey
  case passwordCacheNotFound
  case error(reason: String)
}

public enum WalletAttestationClaimTypes: String, Equatable {
  case wiPop = "wi-wb-auth-pop+jwt"
  case wiaPop = "oauth-client-attestation-pop+jwt"
  case wiRwscdAuthPop = "wi-rwscd-auth-pop+jwt"
  case wiRwscdPinPop = "wi-rwscd-pin-pop+jwt"
}

public protocol WalletPoPController {
  func getProofOfPossession(
    claimType: WalletAttestationClaimTypes,
    challenge: String,
    privateKey: SecKey,
    addPublicKey: Bool,
    issuer: String,
    audience: String
  ) throws -> String

  func getProofOfPossession(using parameters: ProofofPossessionParams) throws -> String

  func getProofOfPossessionForRWSCD(
    using parameters: ProofofPossessionParams,
    withPublicKeyJWK: Bool
  ) throws -> String

  func getSerializedJWT(
    serializedString: String,
    privateKey: SecKey
  ) throws -> JWTSerializedDto?

  func getPublicKeyJWK(
    algo: String,
    privateKey: SecKey,
    kid: String?
  ) throws -> JWK?
}

public struct ProofofPossessionParams {
  let claimType: WalletAttestationClaimTypes
  let challenge: String
  let privateKey: SecKey
  let publicKey: SecKey
  let publicKeyName: String
  let rwscdOperationHash: String

  public init(
    claimType: WalletAttestationClaimTypes,
    challenge: String,
    privateKey: SecKey,
    publicKey: SecKey,
    publicKeyName: String,
    rwscdOperationHash: String = ""
  ) {
    self.claimType = claimType
    self.challenge = challenge
    self.privateKey = privateKey
    self.publicKey = publicKey
    self.publicKeyName = publicKeyName
    self.rwscdOperationHash = rwscdOperationHash
  }
}

public final class WalletPoPControllerImpl: WalletPoPController {

  public struct PublicKeyParams {
    public static let kty = "kty"
    public static let crv = "crv"
    public static let kid = "kid"
  }

  public struct JWTClaimNames {
    static let audience = "aud"
    static let issuer = "iss"
    static let issuedAt = "iat"
    static let expiredAt = "exp"
    static let type = "typ"
    static let jwk = "jwk"
    static let alg = "alg"
    static let jwtId = "jti"
    static let challenge = "challenge"
    static let nonce = "wb_auth_challenge"
    static let rwscdNonce = "rwscd_auth_challenge"
    static let rwscdOperation = "wi_rwscd_operation_hash"
    static let htm = "htm"
    static let htu = "htu"
    static let kid = "kid"
  }

  private let GERMAN_EUDI_WALLET = "german-eudi-wallet"
  private let WALLET_BACKEND = "wallet-backend"
  private let WALLET_APP = "wallet-app"
  private let POST_METHOD = "POST"
  private let SIG_VALUE = "sig"
  private let KTY_VALUE = "EC"
  private let CRV_VALUE = "P-256"
  private let KID_VALUE = "wi_pub"

  let alg = JWSAlgorithm(.ES256)
  let expireyTimeInterval: TimeInterval = 60 * 5

  public init () { }

  public func getProofOfPossession(claimType: WalletAttestationClaimTypes, challenge: String, privateKey: SecKey, addPublicKey: Bool, issuer: String, audience: String) throws -> String {
    guard !challenge.isEmpty else {
      throw PoPGenerationError.missingChallenge
    }

    guard let publicKey = try? KeyController.generateECDHPublicKey(from: privateKey) else {
      throw PoPGenerationError.keyGenerationFailed
    }

    let publicKeyJWK = try ECPublicKey(
      publicKey: publicKey,
      additionalParameters: [
        PublicKeyParams.kty: KTY_VALUE,
        PublicKeyParams.crv: CRV_VALUE
      ]
    )

    var header: JWSHeader
    if addPublicKey {
      header = try JWSHeader(parameters: [
        JWTClaimNames.type: claimType.rawValue,
        JWTClaimNames.alg: alg.name,
        JWTClaimNames.jwk: publicKeyJWK.toDictionary()
      ])
    } else {
      header = try JWSHeader(parameters: [
        JWTClaimNames.type: claimType.rawValue,
        JWTClaimNames.alg: alg.name
      ])
    }

    let dictionary: [String: Any] = [
      JWTClaimNames.issuer: issuer,
      JWTClaimNames.audience: audience,
      JWTClaimNames.issuedAt: Int(Date().timeIntervalSince1970.rounded()),
      JWTClaimNames.expiredAt: Int(Date().addingTimeInterval(expireyTimeInterval).timeIntervalSince1970.rounded()),
      JWTClaimNames.nonce: challenge,
      JWTClaimNames.jwtId: "1"
    ]
    let payload = Payload(try dictionary.toThrowingJSONData())

    guard let signatureAlgorithm = SignatureAlgorithm(rawValue: alg.name) else {
      throw PoPGenerationError.cryptographicAlgorithmNotSupported
    }

    guard let signer = Signer(
      signatureAlgorithm: signatureAlgorithm,
      key: privateKey
    ) else {
      throw PoPGenerationError.signerGenerationFailed
    }
    do {
      let jws = try JWS(
        header: header,
        payload: payload,
        signer: signer
      )
      return jws.compactSerializedString
    } catch {
      throw PoPGenerationError.jwsGenerationFailed
    }
  }

  public func getSerializedJWT(serializedString: String, privateKey: SecKey) throws -> JWTSerializedDto? {
    do {
      let jws = try JWS(compactSerialization: serializedString)
      return try JSONDecoder().decode(JWTSerializedDto.self, from: jws.payload.data())
    } catch {
      throw PoPGenerationError.invalidJWT
    }
  }

  public func getPublicKeyJWK(algo: String, privateKey: SecKey, kid: String? = nil) throws -> JWK? {
    guard let publicKey = try? KeyController.generateECDHPublicKey(from: privateKey) else {
      throw PoPGenerationError.keyGenerationFailed
    }
    do {
      let ecPublcKeyJWK = try ECPublicKey(publicKey: publicKey, additionalParameters: ["alg": algo, "use": "sig", "kid": kid ?? "KID_DEFAULT"])
      return ecPublcKeyJWK
    } catch {
      throw PoPGenerationError.keyGenerationFailed
    }
  }

  public func getProofOfPossession(using parameters: ProofofPossessionParams) throws -> String {
    guard !parameters.challenge.isEmpty else {
      throw PoPGenerationError.missingChallenge
    }

    guard let extractedPublicKey = try? KeyController.generateECDHPublicKey(from: parameters.privateKey) else {
      throw PoPGenerationError.keyGenerationFailed
    }

    let publicKeyJWK = try ECPublicKey(
      publicKey: extractedPublicKey,
      additionalParameters: [
        PublicKeyParams.kty: KTY_VALUE,
        PublicKeyParams.crv: CRV_VALUE
      ]
    )

    let header = try JWSHeader(parameters: [
      JWTClaimNames.type: parameters.claimType.rawValue,
      JWTClaimNames.alg: alg.name,
      JWTClaimNames.jwk: publicKeyJWK.toDictionary()
    ])
    var dictionary: [String: Any] = [
      JWTClaimNames.issuedAt: Int(Date().timeIntervalSince1970.rounded()),
      JWTClaimNames.expiredAt: Int(Date().addingTimeInterval(expireyTimeInterval).timeIntervalSince1970.rounded()),
      JWTClaimNames.nonce: parameters.challenge,
      parameters.publicKeyName: [
        PublicKeyParams.kty: KTY_VALUE,
        PublicKeyParams.crv: CRV_VALUE,
        "x": "x",
        "y": "y"
      ]
    ]
    if !parameters.rwscdOperationHash.isEmpty {
      dictionary[JWTClaimNames.rwscdOperation] = parameters.rwscdOperationHash
    }
    let payload = Payload(try dictionary.toThrowingJSONData())

    guard let signatureAlgorithm = SignatureAlgorithm(rawValue: alg.name) else {
      throw PoPGenerationError.cryptographicAlgorithmNotSupported
    }

    guard let signer = Signer(
      signatureAlgorithm: signatureAlgorithm,
      key: parameters.privateKey
    ) else {
      throw PoPGenerationError.error(reason: "Unable to create JWS signer")
    }

    let jws = try JWS(
      header: header,
      payload: payload,
      signer: signer
    )

    return jws.compactSerializedString
  }

  public func getProofOfPossessionForRWSCD(using parameters: ProofofPossessionParams, withPublicKeyJWK: Bool) throws -> String {
    guard !parameters.challenge.isEmpty else {
      throw PoPGenerationError.missingChallenge
    }
    guard let extractedPublicKey = try? KeyController.generateECDHPublicKey(from: parameters.privateKey) else {
      throw PoPGenerationError.keyGenerationFailed
    }

    let publicKeyJWK = try ECPublicKey(
      publicKey: extractedPublicKey,
      additionalParameters: [
        PublicKeyParams.kty: KTY_VALUE,
        PublicKeyParams.crv: CRV_VALUE
      ]
    )

    var header: JWSHeader

    if withPublicKeyJWK {
      header = try JWSHeader(parameters: [
        JWTClaimNames.type: parameters.claimType.rawValue,
        JWTClaimNames.alg: alg.name,
        JWTClaimNames.jwk: publicKeyJWK.toDictionary()
      ])
    } else {
      header = try JWSHeader(parameters: [
        JWTClaimNames.type: parameters.claimType.rawValue,
        JWTClaimNames.alg: alg.name
      ])
    }
    guard let xData = try? parameters.publicKey.ecPublicKeyComponents().x,
          let yData = try? parameters.publicKey.ecPublicKeyComponents().y else {
      throw PoPGenerationError.invalidPublicKey
    }

    let x = xData.base64URLEncodedString()
    let y = yData.base64URLEncodedString()

    var dictionary: [String: Any] = [
      JWTClaimNames.rwscdNonce: parameters.challenge,
      parameters.publicKeyName: [
        PublicKeyParams.kty: KTY_VALUE,
        PublicKeyParams.crv: CRV_VALUE,
        "x": x,
        "y": y
      ]
    ]
    if !parameters.rwscdOperationHash.isEmpty {
      dictionary[JWTClaimNames.rwscdOperation] = parameters.rwscdOperationHash
    }
    let payload = Payload(try dictionary.toThrowingJSONData())

    guard let signatureAlgorithm = SignatureAlgorithm(rawValue: alg.name) else {
      throw PoPGenerationError.cryptographicAlgorithmNotSupported
    }

    guard let signer = Signer(
      signatureAlgorithm: signatureAlgorithm,
      key: parameters.privateKey
    ) else {
      throw PoPGenerationError.error(reason: "Unable to create JWS signer")
    }

    let jws = try JWS(
      header: header,
      payload: payload,
      signer: signer
    )

    return jws.compactSerializedString
  }
}

public struct JWTSerializedDto: Codable {
  public let iss: String
  public let sub: String
  public let cnf: JWKDto
  public let iat: Int
  public let exp: Int

  public init(iss: String, sub: String, cnf: JWKDto, iat: Int, exp: Int) {
    self.iss = iss
    self.sub = sub
    self.cnf = cnf
    self.iat = iat
    self.exp = exp
  }
}
public struct JWKDto: Codable {
  let jwk: JWKDetailDto

  public init(jwk: JWKDetailDto) {
    self.jwk = jwk
  }
}
public struct JWKDetailDto: Codable {
  let kty: String?
  let use: String?
  let crv: String?
  let x: String
  let y: String

  public init(kty: String, use: String, crv: String, x: String, y: String) {
    self.kty = kty
    self.use = use
    self.crv = crv
    self.x = x
    self.y = y
  }
}
