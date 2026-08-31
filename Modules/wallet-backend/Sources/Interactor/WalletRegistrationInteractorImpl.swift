//
//  WalletRegistrationInteractorImpl.swift
//  wallet-backend
//

import Foundation
import logic_api
import logic_core

public protocol WalletRegistrationInteractor {
  func registerWalletInstance() async throws -> String
}

final class WalletRegistrationInteractorImpl: WalletRegistrationInteractor {

  private let mdvmInteractor: MDVMInteractor
  private let wpbInteractor: WPBInteractor
  private let walletRevocationInteractor: WalletRevocationInteractor

  init(
    mdvmInteractor: MDVMInteractor,
    wpbInteractor: WPBInteractor,
    walletRevocationInteractor: WalletRevocationInteractor
  ) {
    self.mdvmInteractor = mdvmInteractor
    self.wpbInteractor = wpbInteractor
    self.walletRevocationInteractor = walletRevocationInteractor
  }

  public func registerWalletInstance() async throws -> String {
    /// A revoked wallet must never register again. The self-lock wipes local state, which would
    /// otherwise leave the app looking like a fresh install and let it silently enrol a brand-new
    /// Wallet Instance underneath the lock screen.
    guard !walletRevocationInteractor.isWalletRevoked else {
      throw BackendError.notRegistered
    }
    guard let mdvmRegistration = try await mdvmInteractor.ensureFreshMDVMToken() else {
      throw BackendError.unknown
    }
    return try await wpbInteractor.register(mdvmStoredRegistration: mdvmRegistration)
  }
}
