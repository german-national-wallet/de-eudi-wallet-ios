//
//  PNSConstants.swift
//  push-notification-service
//

enum PNSConstants {
  enum Path {
    static let challenge = "v1/pns/challenge"
    static let register = "v1/pns/register"
  }

  enum Header {
    static let contentType = "Content-Type"
    static let authChallenge = "auth-challenge"
    static let mdvmToken = "mdvm-token"
    static let contentDigest = "Content-Digest"

    enum Method {
      static let post = "POST"
    }

    enum ContentType {
      static let json = "application/json"
    }
  }

  enum Signature {
    static let nameAuthSig = "pns-auth-sig"
    static let keyID = "wi-mdvm-auth-key"
    static let algorithm = "ecdsa-p256-sha256"

    /// The `wi_pns_auth_pop` of the PNS spec: the proof of possession covers the challenge for
    /// freshness, the `mdvm_token` to identify the Wallet Instance, and the `mpp_registration_token`
    /// through the digest of the request body, so the new token is bound to this authenticated request.
    static let registerFields = [
      "@method",
      "@path",
      "auth-challenge",
      "mdvm-token",
      "content-digest"
    ]
  }
}
