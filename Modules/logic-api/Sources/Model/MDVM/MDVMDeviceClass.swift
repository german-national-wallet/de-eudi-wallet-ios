//
//  MDVMDeviceClass.swift
//  logic-api
//

import Foundation

public struct MDVMDeviceClass: Encodable, Equatable {
  public let systemVersion: String
  public let model: String
  public let identifierForVendor: String
  public let uname: String
  public let osVersion: String

  public init(
    systemVersion: String,
    model: String,
    identifierForVendor: String,
    uname: String,
    osVersion: String
  ) {
    self.systemVersion = systemVersion
    self.model = model
    self.identifierForVendor = identifierForVendor
    self.uname = uname
    self.osVersion = osVersion
  }
}
