//
//  RWSCAInteractor.swift
//  logic-core
//

import Foundation
import logic_api
import logic_business
import CryptoKit

public protocol RWSCAInteractor: Sendable {
  func register(mdvmStoredRegistration: MDVMStoredRegistration) async throws
  func getRWSCAID() -> String?
  func deleteAccount() async throws
  func startPinSession(pin: String) async throws -> RWSCAPinSessionResponse
  func createKeys(numberOfKeys: Int, ppCNonce: String) async throws -> RWSCACreateKeysResponse
  func signData(wrappedPrivateKey: String, keyBindingData: Data, pinSessionToken: String) async throws -> RWSCASignDataResponse
}

public final class RWSCAInteractorImpl: RWSCAInteractor, @unchecked Sendable {
  private let rwscaRepository: RWSCARepository
  private let mdvmRepository: MDVMRepository
  private let secureEnclaveController: SecureEnclaveController
  private let prefsController: PrefsController
  private let walletPinRepository: WalletPinRepository

  init(
    rwscaRepository: RWSCARepository,
    mdvmRepository: MDVMRepository,
    secureEnclaveController: SecureEnclaveController,
    prefsController: PrefsController,
    walletPinRepository: WalletPinRepository
  ) {
    self.rwscaRepository = rwscaRepository
    self.mdvmRepository = mdvmRepository
    self.secureEnclaveController = secureEnclaveController
    self.prefsController = prefsController
    self.walletPinRepository = walletPinRepository
  }

  public func register(mdvmStoredRegistration: MDVMStoredRegistration) async throws {
    if let rwscaID = rwscaRepository.getRWSCAID(), !rwscaID.isEmpty {
      return
    }
    let challenge = try await rwscaRepository.fetchChallenge()

    let mdvmPrivateKey = try secureEnclaveController.getOrCreatePrivateKey(with: .wiMdvmAuthPrivateKey)
    try await rwscaRepository.register(mdvmToken: mdvmStoredRegistration.mdvmToken, authChallenge: challenge, privateKey: mdvmPrivateKey)
  }

  public func getRWSCAID() -> String? {
    rwscaRepository.getRWSCAID()
  }

  public func deleteAccount() async throws {
    let mdvmToken = try getMDVMStoredRegistration().mdvmToken
    let rwscaID = try getRegisteredRWSCAID()

    guard let mdvmPrivateKey = secureEnclaveController.retrievePrivateKey(with: .wiMdvmAuthPrivateKey) else {
      throw RWSCARepositoryError.notRegistered
    }

    try await rwscaRepository.deleteAccount(
      mdvmToken: mdvmToken,
      challenge: try await rwscaRepository.fetchChallenge(),
      rwscaID: rwscaID,
      mdvmPrivateKey: mdvmPrivateKey
    )
    prefsController.remove(forKey: .isPinInitialized)
  }

  public func startPinSession(pin: String) async throws -> RWSCAPinSessionResponse {
    if prefsController.getBool(forKey: .isPinInitialized) {
      do {
        return try await resumePinSession(pin: pin)
      } catch RWSCARepositoryError.serverError(let code, _, _) where code == RWSCAServerErrorCode.pinNotInitialized {
        return try await initializePinSession(pin: pin)
      }
    } else {
      do {
        return try await initializePinSession(pin: pin)
      } catch RWSCARepositoryError.serverError(let code, _, _) where code == RWSCAServerErrorCode.pinAlreadyInitialized {
        let pinSession = try await resumePinSession(pin: pin)
        prefsController.setValue(true, forKey: .isPinInitialized)
        return pinSession
      }
    }
  }

  private func resumePinSession(pin: String) async throws -> RWSCAPinSessionResponse {
    let context = try await preparePinSessionContext(pin: pin)
    return try await rwscaRepository.startPinSession(
      mdvmToken: context.mdvmToken,
      challenge: context.challenge,
      privateKey: context.mdvmPrivateKey,
      pinPrivateKey: context.pinPrivKey,
      rwscaID: context.rwscaID
    )
  }

  private func initializePinSession(pin: String) async throws -> RWSCAPinSessionResponse {
    let context = try await preparePinSessionContext(pin: pin)
    let pinPublicKey = try secureEnclaveController.getPublicKeyInfo(from: context.pinPrivKey).derBase64
    let pinSession = try await rwscaRepository.initializePinAndStartPinSession(
      mdvmToken: context.mdvmToken,
      challenge: context.challenge,
      rwscaID: context.rwscaID,
      pinPrivateKey: context.pinPrivKey,
      mdvmPrivateKey: context.mdvmPrivateKey,
      payload: RWSCAInitializePinAndStartPinSessionPayload(wiRwscaPinPubk: pinPublicKey)
    )
    prefsController.setValue(true, forKey: .isPinInitialized)
    return pinSession
  }

  public func createKeys(numberOfKeys: Int, ppCNonce: String) async throws -> RWSCACreateKeysResponse {
    return try await rwscaRepository.createKeys(
      mdvmToken: try getMDVMStoredRegistration().mdvmToken,
      challenge: try await rwscaRepository.fetchChallenge(),
      rwscaID: try getRegisteredRWSCAID(),
      // This private key is the MDVM-attested possession factor used for HTTP message signing.
      mdvmPrivateKey: try secureEnclaveController.getOrCreatePrivateKey(with: .wiMdvmAuthPrivateKey),
      payload: RWSCACreateKeysPayload(numberOfKeys: numberOfKeys, ppCNonce: ppCNonce)
    )
  }

  public func signData(wrappedPrivateKey: String, keyBindingData: Data, pinSessionToken: String) async throws -> RWSCASignDataResponse {
    return try await rwscaRepository.signData(
      mdvmToken: try getMDVMStoredRegistration().mdvmToken,
      challenge: try await rwscaRepository.fetchChallenge(),
      rwscaID: try getRegisteredRWSCAID(),
      pinSessionToken: pinSessionToken,
      // This private key is the MDVM-attested possession factor used for HTTP message signing.
      mdvmPrivateKey: try secureEnclaveController.getOrCreatePrivateKey(with: .wiMdvmAuthPrivateKey),
      payload: RWSCASignDataPayload(
        // The wrapped private key stays on the app and is sent back only for signData.
        rwscaWIWrappedPrvk: wrappedPrivateKey,
        // The backend expects the hash of the actual wi_key_binding_data, so the caller passes the raw data here.
        wiKeyBindingDataHash: Data(SHA256.hash(data: keyBindingData)).base64EncodedString()
      )
    )
  }

  private func preparePinSessionContext(pin: String) async throws -> PinSessionContext {
    guard let mdvmStoredRegistration = mdvmRepository.getStoredRegistration() else {
      throw RWSCARepositoryError.notRegistered
    }
    guard let rwscaID = rwscaRepository.getRWSCAID(), !rwscaID.isEmpty else {
      throw RWSCARepositoryError.notRegistered
    }

    let challenge = try await rwscaRepository.fetchChallenge()
    // This private key is the MDVM-attested possession factor used for HTTP message signing
    let mdvmPrivateKey = try secureEnclaveController.getOrCreatePrivateKey(with: .wiMdvmAuthPrivateKey)
    let pinPrivKey = try await walletPinRepository.getPinPrivateKey(pin: pin)

    return PinSessionContext(
      mdvmToken: mdvmStoredRegistration.mdvmToken,
      rwscaID: rwscaID,
      challenge: challenge,
      mdvmPrivateKey: mdvmPrivateKey,
      pinPrivKey: pinPrivKey
    )
  }

  private func getMDVMStoredRegistration() throws -> MDVMStoredRegistration {
    guard let mdvmStoredRegistration = mdvmRepository.getStoredRegistration() else {
      throw RWSCARepositoryError.notRegistered
    }
    return mdvmStoredRegistration
  }

  private func getRegisteredRWSCAID() throws -> String {
    guard let rwscaID = rwscaRepository.getRWSCAID(), !rwscaID.isEmpty else {
      throw RWSCARepositoryError.notRegistered
    }
    return rwscaID
  }

  private struct PinSessionContext {
    let mdvmToken: String
    let rwscaID: String
    let challenge: String
    // This private key is the MDVM-attested possession factor used for HTTP message signing
    let mdvmPrivateKey: SecKey
    // This private key is derived from the user PIN and proves the knowledge factor during PIN session setup
    let pinPrivKey: SecKey
  }
}
