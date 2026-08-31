//
//  SecureEnclaveControllerError.swift
//  logic-business
//

import Foundation

public enum SecureEnclaveControllerError: Error {
  case keyCreationFailed
  case keyStoreFailed
  case publicKeyUnavailable
  case publicKeyEncodingFailed
}
