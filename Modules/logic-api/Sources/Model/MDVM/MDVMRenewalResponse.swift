//
//  MDVMRenewalResponse.swift
//  logic-api
//

import Foundation

struct MDVMRenewalResponse: Decodable, Equatable {
  let mdvmToken: String

  enum CodingKeys: String, CodingKey {
    case mdvmToken = "mdvm_token"
  }
}
