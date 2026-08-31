//
//  RWSCACreateKeysResponse.swift
//  logic-api
//

import Foundation

public struct RWSCACreateKeysResponse: Codable, Equatable {

  enum CodingKeys: String, CodingKey {
    case rwscaWIKeys = "rwsca_wi_keys"
    case rwscaWTE = "rwsca_wte"
  }

  public let rwscaWIKeys: [KeyInfo]
  public let rwscaWTE: String

  public init(rwscaWIKeys: [KeyInfo], rwscaWTE: String) {
    self.rwscaWIKeys = rwscaWIKeys
    self.rwscaWTE = rwscaWTE
  }

  public struct KeyInfo: Codable, Equatable {

    enum CodingKeys: String, CodingKey {
      case rwscdWIPubk = "rwscd_wi_pubk"
      case rwscaWIWrappedPrvk = "rwsca_wi_wrapped_prvk"
    }

    public let rwscdWIPubk: String
    public let rwscaWIWrappedPrvk: String

    public init(rwscdWIPubk: String, rwscaWIWrappedPrvk: String) {
      self.rwscdWIPubk = rwscdWIPubk
      self.rwscaWIWrappedPrvk = rwscaWIWrappedPrvk
    }
  }
}
