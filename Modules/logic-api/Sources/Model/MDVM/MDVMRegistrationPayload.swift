//
//  MDVMRegistrationPayload.swift
//  logic-api
//

import Foundation

public struct MDVMRegistrationPayload: Encodable, Equatable {
  public let wiDeviceClass: MDVMDeviceClass
  public let wiMDVMAuthPubk: String
  public let papDeviceCheckAttestation: String
  public let papDeviceCheckAssertion: String

  enum CodingKeys: String, CodingKey {
    case wiDeviceClass = "wi_device_class"
    case wiMDVMAuthPubk = "wi_mdvm_auth_pubk"
    case papDeviceCheckAttestation = "pap_devicecheck_attestation"
    case papDeviceCheckAssertion = "pap_devicecheck_assertion"
  }

  public init(
    wiDeviceClass: MDVMDeviceClass,
    wiMDVMAuthPubk: String,
    papDeviceCheckAttestation: String,
    papDeviceCheckAssertion: String
  ) {
    self.wiDeviceClass = wiDeviceClass
    self.wiMDVMAuthPubk = wiMDVMAuthPubk
    self.papDeviceCheckAttestation = papDeviceCheckAttestation
    self.papDeviceCheckAssertion = papDeviceCheckAssertion
  }
}
