//
//  WalletRegistrationInteractorImpl.swift
//  wallet-backend
//

import Foundation
import logic_api
import logic_business
import logic_core

public protocol WalletRegistrationInteractor {
  func registerWalletInstance() async throws -> String
}

final class WalletRegistrationInteractorImpl: WalletRegistrationInteractor {

  private let mdvmInteractor: MDVMInteractor
  private let wpbInteractor: WPBInteractor
  private let walletRevocationInteractor: WalletRevocationInteractor
  private let secureEnclaveController: SecureEnclaveController

  init(
    mdvmInteractor: MDVMInteractor,
    wpbInteractor: WPBInteractor,
    walletRevocationInteractor: WalletRevocationInteractor,
    secureEnclaveController: SecureEnclaveController
  ) {
    self.mdvmInteractor = mdvmInteractor
    self.wpbInteractor = wpbInteractor
    self.walletRevocationInteractor = walletRevocationInteractor
    self.secureEnclaveController = secureEnclaveController
  }

  public func registerWalletInstance() async throws -> String {
    /// A revoked wallet must never register again. The self-lock wipes local state, which would
    /// otherwise leave the app looking like a fresh install and let it silently enrol a brand-new
    /// Wallet Instance underneath the lock screen.
    guard !walletRevocationInteractor.isWalletRevoked else {
      throw BackendError.notRegistered
    }

    // Missing walletInstanceID continues registration, but malformed throws
    if let walletInstanceID = try wpbInteractor.walletInstanceID() {
      return walletInstanceID
    }

    guard let mdvmRegistration = try await freshMDVMRegistration() else {
      throw BackendError.unknown
    }
    return try await wpbInteractor.register(mdvmStoredRegistration: mdvmRegistration)
  }

  /// Without a WPB account nothing is bound to the MDVM registration yet, so one the MDVM no longer knows
  /// (e.g. after a backend reset) is dropped and registered again. Otherwise every launch would renew the
  /// same unknown account and only a reinstall could recover the app.
  private func freshMDVMRegistration() async throws -> MDVMStoredRegistration? {
    do {
      return try await mdvmInteractor.ensureFreshMDVMToken()
    } catch let error as BackendError where error.errorCode == MDVMServerErrorCode.accountNotFound {
      secureEnclaveController.deleteKeychainItem(keyTag: .mdvmWIID)
      secureEnclaveController.deleteKeychainItem(keyTag: .mdvmToken)
      return try await mdvmInteractor.ensureFreshMDVMToken()
    }
  }
}
