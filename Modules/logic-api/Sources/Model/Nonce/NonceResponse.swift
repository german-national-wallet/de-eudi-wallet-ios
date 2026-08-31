//
//  NonceResponse.swift
//  logic-api
//

import Foundation

struct NonceResponse: Codable {
  let cNonce: String

  enum CodingKeys: String, CodingKey {
    case cNonce = "c_nonce"
  }
}
