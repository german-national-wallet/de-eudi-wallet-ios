//
//  Error+Extensions.swift
//  logic-core
//
//  Created by Pankaj Sachdeva on 26.08.26.
//

import Foundation
import EudiWalletKit
import OpenID4VCI

public extension Error {
  var isGrantRejection: Bool {
    if let walletError = self as? WalletError, let inner = walletError.innerError {
      return inner.isGrantRejection
    }
    guard let issuanceError = self as? CredentialIssuanceError else { return false }
    switch issuanceError {
    case .pushedAuthorizationRequestFailed(let error, _),
        .accessTokenRequestFailed(let error, _):
      return error == "invalid_grant"
    default:
      return false
    }
  }

  /// The issuer's signed metadata is missing, not trusted or invalid, which is an issuer-side failure.
  var isIssuerMetadataVerificationFailure: Bool {
    if let walletError = self as? WalletError, let inner = walletError.innerError {
      return inner.isIssuerMetadataVerificationFailure
    }
    guard let metadataError = self as? CredentialIssuerMetadataError else { return false }
    switch metadataError {
    case .missingSignedMetadata,
        .missingContentType,
        .missingRightContentTypeHeader,
        .invalidSignedMetadata,
        .invalidJOSEHeader,
        .invalidJWTClaims,
        .nonParseableSignedMetadata,
        .invalidIssuerTrust:
      return true
    default:
      return false
    }
  }
}
