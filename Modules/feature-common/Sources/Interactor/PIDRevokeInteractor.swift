//
//  PIDRevokeInteractor.swift
//  feature-common
//

import logic_core
import logic_business
import logic_api

public protocol PIDRevokeInteractor {
  func deletePIDFromWallet() async throws
}

final class PIDRevokeInteractorImpl: PIDRevokeInteractor {
  private let walletKitController: WalletKitController
  private let prefsController: PrefsController
  private let secureEnclaveController: SecureEnclaveController
  private let rwscaInteractor: RWSCAInteractor
  private let logger: Logging

  init(
    walletKitController: WalletKitController,
    prefsController: PrefsController,
    secureEnclaveController: SecureEnclaveController,
    rwscaInteractor: RWSCAInteractor,
    logger: Logging
  ) {
    self.walletKitController = walletKitController
    self.prefsController = prefsController
    self.secureEnclaveController = secureEnclaveController
    self.rwscaInteractor = rwscaInteractor
    self.logger = logger
  }

  func deletePIDFromWallet() async throws {
    do {
      do {
        try await rwscaInteractor.deleteAccount()
      } catch RWSCARepositoryError.notRegistered {
        logger.d("deletePIDFromWallet: no RWSCA account registered, skipping server-side delete")
      }

      let pidDocuments = walletKitController.fetchIssuedDocuments(with: [.mDocPid, .sdJwtPid])
      for document in pidDocuments {
        try? await walletKitController.deleteDocument(with: document.id, status: .issued)
      }

      prefsController.remove(forKey: .isPinInitialized)
      prefsController.remove(forKey: .mdvmInstallationIdentifier)
      secureEnclaveController.deleteKeychainItem(keyTag: .rwscaAccountID)
      secureEnclaveController.deleteKeychainItem(keyTag: .pinSessionToken)
      secureEnclaveController.deleteKeychainItem(keyTag: .rwscaAuthPrivateKeySalt)
    } catch {
      logger.e("unable to delete pid from wallet: \(error)")
      throw error
    }
  }
}
