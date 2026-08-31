//
//  MDVMRenewalPayload.swift
//  logic-api
//

import Foundation

public struct MDVMRenewalPayload: Encodable, Equatable {
  public let wiDeviceClass: MDVMDeviceClass
  public let papDeviceCheckAssertion: String

  enum CodingKeys: String, CodingKey {
    case wiDeviceClass = "wi_device_class"
    case papDeviceCheckAssertion = "pap_devicecheck_assertion"
  }

  public init(wiDeviceClass: MDVMDeviceClass, papDeviceCheckAssertion: String) {
    self.wiDeviceClass = wiDeviceClass
    self.papDeviceCheckAssertion = papDeviceCheckAssertion
  }
}
