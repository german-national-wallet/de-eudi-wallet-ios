//
//  RWSCARegistrationResponse.swift
//  logic-api
//

import Foundation

public struct RWSCARegistrationResponse: Codable, Equatable {
  public let rwscaAccountID: String

  enum CodingKeys: String, CodingKey {
    case rwscaAccountID = "rwsca_account_id"
  }

  public init(rwscaAccountID: String) {
    self.rwscaAccountID = rwscaAccountID
  }
}
