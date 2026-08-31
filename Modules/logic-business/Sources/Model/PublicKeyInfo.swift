//
//  PublicKeyInfo.swift
//  logic-business
//

import Foundation

public struct PublicKeyInfo {
  public let x963: Data
  public let derBase64: String

  public init(x963: Data, derBase64: String) {
    self.x963 = x963
    self.derBase64 = derBase64
  }
}
