/*
 * Copyright (c) 2023 European Commission
 *
 * Licensed under the EUPL, Version 1.2 or - as soon they will be approved by the European
 * Commission - subsequent versions of the EUPL (the "Licence"); You may not use this work
 * except in compliance with the Licence.
 *
 * You may obtain a copy of the Licence at:
 * https://joinup.ec.europa.eu/software/page/eupl
 *
 * Unless required by applicable law or agreed to in writing, software distributed under
 * the Licence is distributed on an "AS IS" basis, WITHOUT WARRANTIES OR CONDITIONS OF
 * ANY KIND, either express or implied. See the Licence for the specific language
 * governing permissions and limitations under the Licence.
 */
import Foundation
import logic_ui
import feature_common
import logic_core
import logic_business
import logic_api

public protocol StartupInteractor {
  func initialize(with splashAnimationDuration: TimeInterval) async -> AppRoute
  func initializeAppFlow(with splashAnimationDuration: TimeInterval) async -> AppRoute
  func clearFirstRunFlag()
  func storedRevocationCode() -> String?
  func hasSeenRevocationCode() -> Bool
  func markRevocationCodeSeen()
}

final class StartupInteractorImpl: StartupInteractor {

  private let walletKitController: WalletKitController
  private let quickPinInteractor: QuickPinInteractor
  private let keyChainController: KeyChainController
  private let prefsController: PrefsController
  private let mdvmInteractor: MDVMInteractor
  private let rwscaInteractor: RWSCAInteractor
  private let remoteWSCA: RemoteWSCAService?
  private let secureEnclaveController: SecureEnclaveController
  private let pidRevokeInteractor: PIDRevokeInteractor

  private var hasDocuments: Bool {
    return !walletKitController.fetchAllDocuments().isEmpty
  }

  init(
    walletKitController: WalletKitController,
    quickPinInteractor: QuickPinInteractor,
    keyChainController: KeyChainController,
    prefsController: PrefsController,
    mdvmInteractor: MDVMInteractor,
    rwscaInteractor: RWSCAInteractor,
    remoteWSCA: RemoteWSCAService? = nil,
    secureEnclaveController: SecureEnclaveController,
    pidRevokeInteractor: PIDRevokeInteractor
  ) {
    self.walletKitController = walletKitController
    self.quickPinInteractor = quickPinInteractor
    self.keyChainController = keyChainController
    self.prefsController = prefsController
    self.mdvmInteractor = mdvmInteractor
    self.rwscaInteractor = rwscaInteractor
    self.remoteWSCA = remoteWSCA
    self.secureEnclaveController = secureEnclaveController
    self.pidRevokeInteractor = pidRevokeInteractor
  }

  public func initialize(with splashAnimationDuration: TimeInterval) async -> AppRoute {
    await manageStorageForFirstRun()
    try? await walletKitController.loadDocuments()
    try? await Task.sleep(nanoseconds: splashAnimationDuration.nanoseconds)
    if quickPinInteractor.hasPin() {
      return .featureCommonModule(
        .biometry(
          config: UIConfig.Biometry(
            navigationTitle: .custom(""),
            title: .loginTitle,
            caption: .loginCaption,
            quickPinOnlyCaption: .loginCaptionQuickPinOnly,
            navigationSuccessType: .push(
              hasDocuments
              ? .featureDashboardModule(.dashboard)
              : .featureIssuanceModule(.issuanceAddDocument(config: IssuanceFlowUiConfig(flow: .noDocument)))
            ),
            navigationErrorScreen: nil,
            navigationBackType: nil,
            isPreAuthorization: true,
            shouldInitializeBiometricOnCreate: true,
            invalidPinTitle: .issuanceErrorWrongCan,
            pinScreenType: .issueEidPinFlow
          )
        )
      )
    } else {
      return .featureCommonModule(
        .quickPin(config: QuickPinUiConfig(flow: .set))
      )
    }
  }

  public func initializeAppFlow(with splashAnimationDuration: TimeInterval) async -> AppRoute {
    await manageStorageForFirstRun()
    try? await walletKitController.loadDocuments()
    try? await Task.sleep(nanoseconds: splashAnimationDuration.nanoseconds)
    if hasDocuments {
      return .featureDashboardModule(.dashboard)
    } else {
      return .featureIssuanceModule(.issuanceAddDocument(config: IssuanceFlowUiConfig(flow: .noDocument)))
    }
  }

  private func manageStorageForFirstRun() async {
    await migrateOldWalletIfNeeded()
    if !prefsController.getBool(forKey: .runAtLeastOnce) {
      await walletKitController.clearAllDocuments()
      keyChainController.clear()
      keyChainController.clearAllKeychainItems()
      prefsController.remove(forKey: .isPinInitialized)
      prefsController.remove(forKey: .hasSeenRevocationCode)
      prefsController.setValue(true, forKey: .runAtLeastOnce)
    }
  }

  /// Before WPB, the wallet backend ID was stored as .wiID ("com.dewallet.wiID")
  /// If found, the user has a pre-WPB wallet -> we wipe all backend state so fresh MDVM + WPB registration can run cleanly
  /// .wiID (the migration marker) is deleted last, so if the app crashes mid-migration the cleanup re-runs on the next launch
  private func migrateOldWalletIfNeeded() async {
    guard secureEnclaveController.retrieveStringFromKeychain(keyTag: .wiID) != nil else {
      return
    }

    //TODO: Remove this in future versions
    /// Warning: deletePIDFromWallet works off the in-memory document list, which is only populated by loadDocuments
    /// Migration need to run after the app loaded documents, otherwise PID is never found
    try? await walletKitController.loadDocuments()

    try? await pidRevokeInteractor.deletePIDFromWallet()

    //clean up of old .regPrivKey
    _ = secureEnclaveController.deletePrivateKey(with: .custom("com.dewallet.registration.privateKey"))
    _ = secureEnclaveController.deletePrivateKey(with: .wiMdvmAuthPrivateKey)
    _ = secureEnclaveController.deletePrivateKey(with: .wiaPrivateKey)
    secureEnclaveController.deleteKeychainItem(keyTag: .wbWIID)
    secureEnclaveController.deleteKeychainItem(keyTag: .wpbWiRevocationCode)

    /// Deleted last: the marker only goes away once the cleanup above has fully completed
    secureEnclaveController.deleteKeychainItem(keyTag: .wiID)
  }

  func clearFirstRunFlag() {
    prefsController.remove(forKey: .runAtLeastOnce)
    keyChainController.clear()
    keyChainController.clearAllKeychainItems()
  }

  func storedRevocationCode() -> String? {
    guard let code = secureEnclaveController.retrieveDecryptedString(keyTag: .wpbWiRevocationCode),
          !code.isEmpty else {
      return nil
    }
    return code
  }

  func hasSeenRevocationCode() -> Bool {
    prefsController.getBool(forKey: .hasSeenRevocationCode)
  }

  func markRevocationCodeSeen() {
    prefsController.setValue(true, forKey: .hasSeenRevocationCode)
  }
}

enum StartupError: LocalizedError, Equatable {
  case mdvmRegistrationFailed
}
