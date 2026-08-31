//
//  MDVMConstants.swift
//  logic-api
//

import Foundation

enum MDVMConstants {
  enum Path {
    static let challenge = "v1/mdvm/challenge"
    static let register = "v1/mdvm/ios/register"
    static let renewal = "v1/mdvm/ios/renewal"
  }

  enum Header {
    static let contentType = "Content-Type"
    static let authChallenge = "auth-challenge"
    static let skipIntegrityChecks = "skip-integrity-checks"
    static let contentDigest = "Content-Digest"
    static let signatureInput = "Signature-Input"
    static let signature = "Signature"
    static let mdvmToken = "mdvm-token"
    static let mdvmWIID = "mdvm-wi-id"

    enum Method {
      static let post = "POST"
    }

    enum ContentType {
      static let json = "application/json"
    }
  }

  enum Signature {
    static let name = "mdvm-auth-sig"
    static let keyID = "wi-mdvm-auth-key"
    static let algorithm = "ecdsa-p256-sha256"
    static let registerFields = [
      "@method",
      "@path",
      "auth-challenge",
      "mdvm-token",
      "content-digest",
      "skip-integrity-checks"
    ]
    static let renewalFields = [
      "@method",
      "@path",
      "mdvm-wi-id",
      "auth-challenge",
      "content-digest",
      "skip-integrity-checks"
    ]
  }
}
