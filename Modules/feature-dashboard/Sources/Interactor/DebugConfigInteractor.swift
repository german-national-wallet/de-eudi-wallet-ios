//
//  DebugConfigInteractor.swift
//  feature-dashboard
//

import Foundation
import logic_business
import logic_core

struct DebugConfigDefaults: Sendable {
  let walletHostURL: String
  let otlpHostURL: String
  let pidProviderURL: String
}

protocol DebugConfigInteractor: Sendable {
  var defaults: DebugConfigDefaults { get }
  var overrides: DebugConfigOverrides { get }

  func apply(_ overrides: DebugConfigOverrides, wipingData: Bool) async
  func reset(wipingData: Bool) async
}

final class DebugConfigInteractorImpl: DebugConfigInteractor {

  private let debugConfigController: DebugConfigController
  private let walletKitController: WalletKitController
  private let keyChainController: KeyChainController
  private let prefsController: PrefsController

  init(
    debugConfigController: DebugConfigController,
    walletKitController: WalletKitController,
    keyChainController: KeyChainController,
    prefsController: PrefsController
  ) {
    self.debugConfigController = debugConfigController
    self.walletKitController = walletKitController
    self.keyChainController = keyChainController
    self.prefsController = prefsController
  }

  var defaults: DebugConfigDefaults {
    .init(
      walletHostURL: "WALLET_HOST_URL".valueFromBundle,
      otlpHostURL: "WALLET_OTLP_HOST_URL".valueFromBundle,
      pidProviderURL: "VCI_ISSUER_URL".valueFromBundle
    )
  }

  var overrides: DebugConfigOverrides {
    debugConfigController.overrides
  }

  func apply(_ overrides: DebugConfigOverrides, wipingData: Bool) async {
    if wipingData {
      await clearAllData()
    }
    debugConfigController.store(overrides)
    restart()
  }

  func reset(wipingData: Bool) async {
    if wipingData {
      await clearAllData()
    }
    debugConfigController.clearAll()
    restart()
  }

  /// Must run before storing the overrides, the keychain wipe would otherwise delete them.
  /// Also keeps the first-run flag untouched. Clearing it would trigger the first-run keychain
  /// wipe on the next launch, which would delete the stored overrides again
  private func clearAllData() async {
    await walletKitController.clearAllDocuments()
    keyChainController.clear()
    keyChainController.clearKeyChainBiometry()
    keyChainController.clearAllKeychainItems()
    prefsController.remove(forKey: .isPinInitialized)
    prefsController.remove(forKey: .hasSeenRevocationCode)
  }

  /// Terminate so the next launch rebuilds the DI graph (WalletKit, OTel, network) with the new values
  private func restart() {
    /// UserDefaults flushes asynchronously. Without forcing it, exit(0) can lose the just-written values
    UserDefaults.standard.synchronize()
    exit(0)
  }
}
