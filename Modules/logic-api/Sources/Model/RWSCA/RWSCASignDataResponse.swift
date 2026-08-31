//
//  RWSCASignDataResponse.swift
//  logic-api
//

import Foundation

public struct RWSCASignDataResponse: Codable, Equatable {

  enum CodingKeys: String, CodingKey {
    case rwscdKeyBindingSignature = "rwscd_key_binding_signature"
  }

  public let rwscdKeyBindingSignature: String

  public init(rwscdKeyBindingSignature: String) {
    self.rwscdKeyBindingSignature = rwscdKeyBindingSignature
  }
}
