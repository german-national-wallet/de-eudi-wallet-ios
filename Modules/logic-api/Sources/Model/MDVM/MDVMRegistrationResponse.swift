//
//  MDVMRegistrationResponse.swift
//  logic-api
//

import Foundation

public struct MDVMRegistrationResponse: Decodable, Equatable {
  public let mdvmWIID: String
  public let mdvmToken: String

  enum CodingKeys: String, CodingKey {
    case mdvmWIID = "mdvm_wi_id"
    case mdvmToken = "mdvm_token"
  }

  public init(mdvmWIID: String, mdvmToken: String) {
    self.mdvmWIID = mdvmWIID
    self.mdvmToken = mdvmToken
  }
}
