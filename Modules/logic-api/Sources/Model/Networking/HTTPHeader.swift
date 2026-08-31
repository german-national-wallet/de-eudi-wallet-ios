//
//  HTTPHeader.swift
//  logic-api
//

public struct HTTPHeader {
  public let name: String
  public let value: String

  public init(name: String, value: String) {
    self.name = name
    self.value = value
  }
}
