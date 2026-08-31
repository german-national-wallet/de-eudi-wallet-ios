//
//  MDVMInteractor.swift
//  logic-core
//

import Foundation
import CryptoKit
import UIKit
import logic_api
import logic_business
import logic_feature_flags

public protocol MDVMInteractor {
  /// Ensures a valid MDVM token exists by registering, reusing, or renewing as needed.
  func ensureFreshMDVMToken() async throws -> MDVMStoredRegistration?
}

public final class MDVMInteractorImpl: MDVMInteractor {

  private var isSkipIntegrityChecksEnabled: Bool {
#if targetEnvironment(simulator)
    // Enabling skipIntegrityChecks only on `dev` on simulators
    configLogic.appBuildVariant == .DEV
#else
    false
#endif
  }

  private let mdvmRepository: MDVMRepository
  private let platformAttestationInteractor: PlatformAttestationInteractor
  private let secureEnclaveController: SecureEnclaveController
  private let configLogic: ConfigLogic
  private let prefsController: PrefsController
  private let featureFlagRepository: FeatureFlagRepository
  private let walletRevocationStore: WalletRevocationStore
  private let logger: Logging?

  public init(
    mdvmRepository: MDVMRepository,
    platformAttestationInteractor: PlatformAttestationInteractor,
    secureEnclaveController: SecureEnclaveController,
    configLogic: ConfigLogic,
    prefsController: PrefsController,
    featureFlagRepository: FeatureFlagRepository,
    walletRevocationStore: WalletRevocationStore,
    logger: Logging?
  ) {
    self.mdvmRepository = mdvmRepository
    self.platformAttestationInteractor = platformAttestationInteractor
    self.secureEnclaveController = secureEnclaveController
    self.configLogic = configLogic
    self.prefsController = prefsController
    self.featureFlagRepository = featureFlagRepository
    self.walletRevocationStore = walletRevocationStore
    self.logger = logger
  }

  public func ensureFreshMDVMToken() async throws -> MDVMStoredRegistration? {
    if let storedRegistration = mdvmRepository.getStoredRegistration() {
      guard await shouldRenewToken(storedRegistration) else {
        return storedRegistration
      }
      try await renew(using: storedRegistration)
    } else {
      try await register()
    }
    return mdvmRepository.getStoredRegistration()
  }

  private func register() async throws {
    prefsController.remove(forKey: .mdvmInstallationIdentifier)
    secureEnclaveController.deleteKeychainItem(keyTag: .mdvmAppAttestKeyID)
    _ = secureEnclaveController.deletePrivateKey(with: .wiMdvmAuthPrivateKey)
    let mdvmPrivateKey = try secureEnclaveController.getOrCreatePrivateKey(with: .wiMdvmAuthPrivateKey)
    let mdvmAuthChallenge = try await mdvmRepository.fetchChallenge()
    let publicKey = try secureEnclaveController.getPublicKeyInfo(from: mdvmPrivateKey)

    let attestationInput = createInput(
      challenge: mdvmAuthChallenge,
      publicKeyX963: publicKey.x963
    )

    var platformAttestation = ""
    var platformAssertion = ""

    if !isSkipIntegrityChecksEnabled {
      platformAttestation = try await platformAttestationInteractor.fetchAttestation(for: attestationInput)
      platformAssertion = try await platformAttestationInteractor.fetchAssertion(for: attestationInput)
    }

    let payload = MDVMRegistrationPayload(
      wiDeviceClass: getDeviceClass(),
      wiMDVMAuthPubk: publicKey.derBase64,
      papDeviceCheckAttestation: platformAttestation,
      papDeviceCheckAssertion: platformAssertion
    )

    try await markRevocationIfConfirmed {
      try await mdvmRepository.register(
        payload: payload,
        authChallenge: mdvmAuthChallenge,
        skipIntegrityChecks: isSkipIntegrityChecksEnabled,
        privateKey: mdvmPrivateKey
      )
    }
  }

  private func renew(using storedRegistration: MDVMStoredRegistration) async throws {
    let mdvmPrivateKey = try secureEnclaveController.getOrCreatePrivateKey(with: .wiMdvmAuthPrivateKey)
    let mdvmAuthChallenge = try await mdvmRepository.fetchChallenge()
    let publicKey = try secureEnclaveController.getPublicKeyInfo(from: mdvmPrivateKey)

    let attestationInput = createInput(
      challenge: mdvmAuthChallenge,
      publicKeyX963: publicKey.x963
    )

    var platformAssertion = ""

    if !isSkipIntegrityChecksEnabled {
      platformAssertion = try await platformAttestationInteractor.fetchAssertion(for: attestationInput)
    }

    let payload = MDVMRenewalPayload(
      wiDeviceClass: getDeviceClass(),
      papDeviceCheckAssertion: platformAssertion
    )

    try await markRevocationIfConfirmed {
      try await mdvmRepository.renew(
        payload: payload,
        mdvmWIID: storedRegistration.mdvmWIID,
        authChallenge: mdvmAuthChallenge,
        skipIntegrityChecks: isSkipIntegrityChecksEnabled,
        privateKey: mdvmPrivateKey
      )
    }
  }

  private func markRevocationIfConfirmed(_ operation: () async throws -> Void) async throws {
    do {
      try await operation()
    } catch let error as BackendError where error.errorCode == MDVMServerErrorCode.revoked {
      walletRevocationStore.markRevoked()
      throw error
    }
  }

  private func shouldRenewToken(_ storedRegistration: MDVMStoredRegistration) async -> Bool {
    guard let expirationDate = storedRegistration.expirationDate else {
      return true
    }

    let bufferDuration: String = await featureFlagRepository.getFlagValue(.mdvmTokenFreshnessBuffer)
    let bufferMinutes = bufferDuration.minutesFromISO8601DurationString() ?? 10
    let bufferSeconds = TimeInterval(max(0, bufferMinutes) * 60)
    return expirationDate.timeIntervalSinceNow <= bufferSeconds
  }

  private func createInput(challenge: String, publicKeyX963: Data) -> Data {
    let challengeHash = SHA256.hash(data: Data(challenge.utf8))
    let encodedChallengeHash = Data(challengeHash).base64EncodedString().toBase64URL()
    let encodedPublicKey = publicKeyX963.base64EncodedString().toBase64URL()
    let clientDataJSON =
      "{\"purpose\":\"ios app-attest: secure enclave protected key\"," +
      "\"publicKey\":\"\(encodedPublicKey)\"," +
      "\"challenge\":\"\(encodedChallengeHash)\"}"
    return Data(clientDataJSON.utf8)
  }

  private func getDeviceClass() -> MDVMDeviceClass {
    MDVMDeviceClass(
      systemVersion: UIDevice.current.systemVersion,
      model: UIDevice.current.model,
      identifierForVendor: installationIdentifier(),
      uname: ProcessInfo.processInfo.environment["COMPUTERNAME"] ?? "",
      osVersion: ProcessInfo.processInfo.operatingSystemVersionString
    )
  }

  private func installationIdentifier() -> String {
    if let identifier = prefsController.getString(forKey: .mdvmInstallationIdentifier), !identifier.isEmpty {
      return identifier
    }

    let identifier = UUID().uuidString
    prefsController.setValue(identifier, forKey: .mdvmInstallationIdentifier)
    return identifier
  }
}

extension MDVMInteractorImpl: MDVMTokenRenewalService {

  public func renewMDVMTokenIgnoringFreshness() async throws {
    guard let storedRegistration = mdvmRepository.getStoredRegistration() else {
      throw MDVMRepositoryError.notRegistered
    }
    try await renew(using: storedRegistration)
  }
}
