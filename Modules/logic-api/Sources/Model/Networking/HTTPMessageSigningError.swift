//
//  HTTPMessageSigningError.swift
//  logic-api
//

public enum HTTPMessageSigningError: Error, Equatable {
  case missingSignatures
  case missingSignedHeader(String)
  case signingFailed
}
