//
//  RWSCACreateKeysPayload.swift
//  logic-api
//

import Foundation

public struct RWSCACreateKeysPayload: Codable, Equatable {

  enum CodingKeys: String, CodingKey {
    case numberOfKeys = "number_of_keys"
    case ppCNonce = "pp_c_nonce"
  }

  public let numberOfKeys: Int
  public let ppCNonce: String

  public init(numberOfKeys: Int, ppCNonce: String) {
    self.numberOfKeys = numberOfKeys
    self.ppCNonce = ppCNonce
  }
}
