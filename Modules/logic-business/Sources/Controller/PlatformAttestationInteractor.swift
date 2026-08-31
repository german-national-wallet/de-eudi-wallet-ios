//
//  PlatformAttestationInteractor.swift
//  logic-business
//

import Foundation
import DeviceCheck
import CryptoKit

enum AppAttestationError: Error, Equatable {
  static func == (lhs: AppAttestationError, rhs: AppAttestationError) -> Bool {
    switch (lhs, rhs) {
    case (.attestationNotSupported, .attestationNotSupported):
      return lhs.localizedDescription == rhs.localizedDescription
    case (.invalidChallenge, .invalidChallenge):
      return lhs.localizedDescription == rhs.localizedDescription
    case (.customError, .customError):
      return lhs.localizedDescription == rhs.localizedDescription
    case (.keyGenerationFailed, .keyGenerationFailed):
      return lhs.localizedDescription == rhs.localizedDescription
    case (.attestationGenerationFailed, .attestationGenerationFailed):
      return lhs.localizedDescription == rhs.localizedDescription
    default: return false
    }
  }

  case attestationNotSupported
  case invalidChallenge
  case customError(String)
  case keyGenerationFailed(Error?)
  case attestationGenerationFailed(Error?)
}

public protocol PlatformAttestationInteractor {
  /// Generates a DeviceCheck attestation for the challenge and keeps the attested key id for later assertions.
  func fetchAttestation(for challenge: Data) async throws -> String

  /// Generates a DeviceCheck assertion for the challenge using the previously attested key id.
  func fetchAssertion(for challenge: Data) async throws -> String
}

public final class PlatformAttestationInteractorImpl: PlatformAttestationInteractor {
  private let attestationService: DCAppAttestService
  private let secureEnclaveController: SecureEnclaveController
  private let isUITesting: Bool

  public init(
    attestationService: DCAppAttestService = DCAppAttestService.shared,
    secureEnclaveController: SecureEnclaveController,
    isUITesting: Bool = false
  ) {
    self.attestationService = attestationService
    self.secureEnclaveController = secureEnclaveController
    self.isUITesting = isUITesting
  }

  public func fetchAttestation(for challenge: Data) async throws -> String {
    if isUITesting { return "" }

    guard !challenge.isEmpty else {
      throw AppAttestationError.invalidChallenge
    }
    let attestation = try await generateAttestation(
      keyID: try await getOrCreateKeyID(),
      challenge: challenge
    )
    return attestation.base64EncodedString()
  }

  public func fetchAssertion(for challenge: Data) async throws -> String {
    if isUITesting { return "" }

    guard !challenge.isEmpty else {
      throw AppAttestationError.invalidChallenge
    }

    let assertion = try await generateAssertion(
      keyID: try await getOrCreateKeyID(),
      challenge: challenge
    )
    return assertion.base64EncodedString()
  }

  private func getOrCreateKeyID() async throws -> String {
    if let stored = secureEnclaveController.retrieveStringFromKeychain(keyTag: .mdvmAppAttestKeyID) {
      return stored
    }
    let result: String = try await withCheckedThrowingContinuation { continuation in
      attestationService.generateKey { keyID, error in
        guard let keyID, !keyID.isEmpty else {
          continuation.resume(throwing: AppAttestationError.keyGenerationFailed(error))
          return
        }
        continuation.resume(returning: keyID)
      }
    }
    _ = secureEnclaveController.storeStringInKeychain(value: result, keyTag: .mdvmAppAttestKeyID)
    return result
  }

  private func generateAttestation(keyID: String, challenge: Data) async throws -> Data {
    let challengeHash = Data(SHA256.hash(data: challenge))

    return try await withCheckedThrowingContinuation { continuation in
      attestationService.attestKey(keyID, clientDataHash: challengeHash) { attestation, error in
        if let attestationValue = attestation {
          continuation.resume(returning: attestationValue)
        } else if let dcError = error as? DCError, dcError.code == .invalidKey {
          continuation.resume(throwing: AppAttestationError.attestationGenerationFailed(dcError))
        } else {
          continuation.resume(throwing: AppAttestationError.attestationGenerationFailed(error))
        }
      }
    }
  }

  private func generateAssertion(keyID: String, challenge: Data) async throws -> Data {
    let challengeHash = Data(SHA256.hash(data: challenge))

    return try await withCheckedThrowingContinuation { continuation in
      attestationService.generateAssertion(keyID, clientDataHash: challengeHash) { assertion, error in
        if let assertion {
          continuation.resume(returning: assertion)
        } else {
          continuation.resume(throwing: AppAttestationError.attestationGenerationFailed(error))
        }
      }
    }
  }
}
