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
  case invalidEncryptedValueEncoding
  case invalidCiphertextFormat
  case encryptedValueAuthenticationFailed
  case encryptionKeyUnavailable
  case invalidDecryptedValueEncoding
  case unexpectedDecryptionFailure
  case encryptionFailed
  case keychainWriteFailed
  case pinKeyDerivationFailed
}
