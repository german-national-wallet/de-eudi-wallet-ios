//
//  WPBConstants.swift
//  wallet-backend
//

enum WPBConstants {
  enum Path {
    static let challenge = "v1/wpb/challenge"
    static let register = "v1/wpb/register"
    static let attestation = "v1/wpb/attestation"
    static let deleteAccount = "v1/wpb/deleteAccount"
  }

  enum Header {
    static let contentType = "Content-Type"
    static let authChallenge = "auth-challenge"
    static let mdvmToken = "mdvm-token"
    static let wbWIID = "wpb-wi-id"
    static let contentDigest = "Content-Digest"

    enum Method {
      static let post = "POST"
      static let delete = "DELETE"
    }

    enum ContentType {
      static let json = "application/json"
    }
  }

  enum Signature {
    static let nameAuthSig = "wpb-auth-sig"
    static let nameWIASig = "wpb-wia-sig"
    static let keyID = "wi-mdvm-auth-key"
    static let keyIDWIA = "wi-wia-key"
    static let algorithm = "ecdsa-p256-sha256"

    static let registerFields = [
      "@method",
      "@path",
      "auth-challenge",
      "mdvm-token"
    ]

    static let attestationFields = [
      "@method",
      "@path",
      "wpb-wi-id",
      "auth-challenge",
      "mdvm-token",
      "content-digest"
    ]

    static let deleteAccountFields = [
      "@method",
      "@path",
      "wpb-wi-id",
      "auth-challenge",
      "mdvm-token"
    ]
  }
}
