//
//  WalletRevocationInteractor.swift
//  logic-core
//

import Foundation
import logic_api
import logic_business

public protocol WalletRevocationInteractor: Sendable {
  var isWalletRevoked: Bool { get }

  func confirmRevocation() async
  func resetAfterRevocation()
}

public final class WalletRevocationInteractorImpl: WalletRevocationInteractor {

  private static let propagationRetryDelay: TimeInterval = 3

  private let renewalService: MDVMTokenRenewalService
  private let store: WalletRevocationStore
  private let prefsController: PrefsController
  private let logger: Logging?

  public init(
    renewalService: MDVMTokenRenewalService,
    store: WalletRevocationStore,
    prefsController: PrefsController,
    logger: Logging?
  ) {
    self.renewalService = renewalService
    self.store = store
    self.prefsController = prefsController
    self.logger = logger
  }

  public var isWalletRevoked: Bool {
    store.isWalletRevoked
  }

  public func confirmRevocation() async {
    guard !isWalletRevoked else {
      store.markRevoked()
      return
    }
    await attemptConfirmation(isRetryAllowed: true)
  }

  private func attemptConfirmation(isRetryAllowed: Bool) async {
    do {
      try await renewalService.renewMDVMTokenIgnoringFreshness()

      guard isRetryAllowed else {
        logger?.d("[Revocation] renewal still succeeds, wallet is not revoked")
        return
      }
      logger?.d("[Revocation] renewal succeeded, retrying once for propagation")
      try? await Task.sleep(nanoseconds: UInt64(Self.propagationRetryDelay * 1_000_000_000))
      await attemptConfirmation(isRetryAllowed: false)
    } catch let error as BackendError where error.errorCode == MDVMServerErrorCode.revoked {
      store.markRevoked()
    } catch {
      logger?.e("[Revocation] could not confirm revocation, leaving the wallet unlocked: \(error.logDescriptor)")
    }
  }

  public func resetAfterRevocation() {
    prefsController.remove(forKey: .mdvmInstallationIdentifier)
    prefsController.remove(forKey: .biometryEnabled)
    prefsController.remove(forKey: .hasSeenRevocationCode)
    store.clearRevoked()
    logger?.d("[Revocation] local state reset, the wallet can be set up again")
  }

}
