//
//  HTTPMessageSignature.swift
//  logic-api
//

import Foundation
import Security

public struct HTTPMessageSignature {
  public let name: String
  public let keyID: String
  public let algorithm: String
  public let fields: [String]
  /// Uses the caller-provided private key for HTTP message signing.
  public let privateKey: SecKey
  public let encryptSignature: ((Data) throws -> Data)?

  public init(
    name: String,
    keyID: String,
    algorithm: String,
    fields: [String],
    privateKey: SecKey,
    encryptSignature: ((Data) throws -> Data)? = nil
  ) {
    self.name = name
    self.keyID = keyID
    self.algorithm = algorithm
    self.fields = fields
    self.privateKey = privateKey
    self.encryptSignature = encryptSignature
  }
}
