//
//  PinSessionInteractor.swift
//  feature-common
//

import MdocDataModel18013
import logic_core

public protocol PinSessionInteractor {
  func set(pin: String) async throws
  func clear()
}
final public class PinSessionInteractorImpl: PinSessionInteractor {
  private let mdvmInteractor: MDVMInteractor
  private let rwscaInteractor: RWSCAInteractor
  private let secureEnclaveController: SecureEnclaveController

  init(
    mdvmInteractor: MDVMInteractor,
    rwscaInteractor: RWSCAInteractor,
    secureEnclaveController: SecureEnclaveController
  ) {
    self.mdvmInteractor = mdvmInteractor
    self.rwscaInteractor = rwscaInteractor
    self.secureEnclaveController = secureEnclaveController
  }

  public func set(pin: String) async throws {
    guard let mdvmStoredRegistration = try await mdvmInteractor.ensureFreshMDVMToken() else {
      return
    }
    try await rwscaInteractor.register(mdvmStoredRegistration: mdvmStoredRegistration)
    let pinSessionToken = try await rwscaInteractor.startPinSession(pin: pin).rwscaPinSessionToken

    if pinSessionToken.isEmpty {
      throw SecureAreaError("PIN session token is required for signing")
    }
    _ = secureEnclaveController.storeStringInKeychain(value: pinSessionToken, keyTag: .pinSessionToken)
  }

  public func clear() {
    secureEnclaveController.deleteKeychainItem(keyTag: .pinSessionToken)
  }
}
