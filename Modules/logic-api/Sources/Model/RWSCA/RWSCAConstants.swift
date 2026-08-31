//
//  RWSCAConstants.swift
//  logic-api
//

enum RWSCAConstants {
  enum Path {
    static let challenge = "v1/rwsca/challenge"
    static let register = "v1/rwsca/register"
    static let startPinSession = "v1/rwsca/startPinSession"
    static let initializePinAndStartPinSession = "v1/rwsca/initializePinAndStartPinSession"
    static let createKeys = "v1/rwsca/createKeys"
    static let signData = "v1/rwsca/signData"
    static let deleteAccount = "v1/rwsca/deleteAccount"
  }

  enum Header {
    static let contentType = "Content-Type"
    static let authChallenge = "auth-challenge"
    static let signatureInput = "Signature-Input"
    static let signature = "Signature"
    static let mdvmToken = "mdvm-token"
    static let rwscaAccountId = "rwsca-account-id"
    static let contentDigest = "Content-Digest"
    static let rwscaPinSessionToken = "rwsca-pin-session-token"

    enum Method {
      static let post = "POST"
      static let delete = "DELETE"
    }

    enum ContentType {
      static let json = "application/json"
    }
  }

  enum Signature {
    static let nameAuthSig = "rwsca-auth-sig"
    static let namePinSig = "rwsca-pin-sig"
    static let keyID = "wi-mdvm-auth-key"
    static let keyIDPin = "wi-rwsca-pin-key"
    static let algorithm = "ecdsa-p256-sha256"
    static let registerFields = [
      "@method",
      "@path",
      "auth-challenge",
      "mdvm-token"
    ]
    static let startPinSessionFields = [
      "@method",
      "@path",
      "rwsca-account-id",
      "auth-challenge",
      "mdvm-token"
    ]
    static let initializePinAndStartPinSessionFields = [
      "@method",
      "@path",
      "content-digest",
      "rwsca-account-id",
      "auth-challenge",
      "mdvm-token"
    ]
    static let createKeysFields = [
      "@method",
      "@path",
      "content-digest",
      "rwsca-account-id",
      "auth-challenge",
      "mdvm-token"
    ]
    static let signDataFields = [
      "@method",
      "@path",
      "content-digest",
      "rwsca-account-id",
      "auth-challenge",
      "mdvm-token",
      "rwsca-pin-session-token"
    ]
    static let deleteAccountFields = [
      "@method",
      "@path",
      "rwsca-account-id",
      "auth-challenge",
      "mdvm-token"
    ]
  }
}
