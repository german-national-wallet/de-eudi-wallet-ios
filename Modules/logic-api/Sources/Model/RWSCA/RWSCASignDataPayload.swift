//
//  RWSCASignDataPayload.swift
//  logic-api
//

import Foundation

public struct RWSCASignDataPayload: Codable, Equatable {

  enum CodingKeys: String, CodingKey {
    case rwscaWIWrappedPrvk = "rwsca_wi_wrapped_prvk"
    case wiKeyBindingDataHash = "wi_key_binding_data_hash"
  }

  public let rwscaWIWrappedPrvk: String
  public let wiKeyBindingDataHash: String

  public init(rwscaWIWrappedPrvk: String, wiKeyBindingDataHash: String) {
    self.rwscaWIWrappedPrvk = rwscaWIWrappedPrvk
    self.wiKeyBindingDataHash = wiKeyBindingDataHash
  }
}
