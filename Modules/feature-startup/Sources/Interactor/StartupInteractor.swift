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
import push_notification_service

public protocol StartupInteractor {
  func initialize(with splashAnimationDuration: TimeInterval) async -> AppRoute
  func initializeAppFlow(with splashAnimationDuration: TimeInterval) async -> AppRoute
  func clearFirstRunFlag()
  func storedRevocationCode() throws -> String?
  func hasSeenRevocationCode() -> Bool
  func markRevocationCodeSeen()
  func hasSeenAppIntro() -> Bool
  func markAppIntroSeen()
  func isAppSetupPending() -> Bool
  func markAppSetupCompleted()
  func hasSeenPlatformAuthIntro() -> Bool
  func markPlatformAuthIntroSeen()
  func isPlatformAuthenticationEnabled() async -> Bool
  func hasAcceptedPrivacyPolicy() -> Bool
  func markPrivacyPolicyAccepted()
  func hasSeenPushIntro() -> Bool
  func markPushIntroSeen()
  func requestPushAuthorization() async -> Bool
}

final class StartupInteractorImpl: StartupInteractor {

  /// Increment on breaking local storage changes: any change wipes the wallet on the next launch, like CURRENT_APP_DATA_VERSION on Android
  static let currentAppDataVersion = 2

  private let walletKitController: WalletKitController
  private let quickPinInteractor: QuickPinInteractor
  private let keyChainController: KeyChainController
  private let prefsController: PrefsController
  private let rwscaInteractor: RWSCAInteractor
  private let remoteWSCA: RemoteWSCAService?
  private let secureEnclaveController: SecureEnclaveController
  private let appBlockingController: AppBlockingController
  private let pushAuthorizationProvider: PushAuthorizationProvider
  private let pnsAccountInteractor: PNSAccountInteractor

  private var hasDocuments: Bool {
    return !walletKitController.fetchAllDocuments().isEmpty
  }

  init(
    walletKitController: WalletKitController,
    quickPinInteractor: QuickPinInteractor,
    keyChainController: KeyChainController,
    prefsController: PrefsController,
    rwscaInteractor: RWSCAInteractor,
    remoteWSCA: RemoteWSCAService? = nil,
    secureEnclaveController: SecureEnclaveController,
    appBlockingController: AppBlockingController,
    pushAuthorizationProvider: PushAuthorizationProvider,
    pnsAccountInteractor: PNSAccountInteractor
  ) {
    self.walletKitController = walletKitController
    self.quickPinInteractor = quickPinInteractor
    self.keyChainController = keyChainController
    self.prefsController = prefsController
    self.rwscaInteractor = rwscaInteractor
    self.remoteWSCA = remoteWSCA
    self.secureEnclaveController = secureEnclaveController
    self.appBlockingController = appBlockingController
    self.pushAuthorizationProvider = pushAuthorizationProvider
    self.pnsAccountInteractor = pnsAccountInteractor
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
            navigationSuccessType: .push(.featureDashboardModule(.dashboard)),
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
    return .featureDashboardModule(.dashboard)
  }

  private func manageStorageForFirstRun() async {
    resetAppDataIfVersionChanged()
    if !prefsController.getBool(forKey: .runAtLeastOnce) {
      await walletKitController.clearAllDocuments()
      keyChainController.clear()
      keyChainController.clearAllKeychainItems()
      prefsController.remove(forKey: .isPinInitialized)
      prefsController.remove(forKey: .hasSeenRevocationCode)
      prefsController.remove(forKey: .hasSeenAppIntro)
      prefsController.remove(forKey: .hasSeenPlatformAuthIntro)
      prefsController.remove(forKey: .hasAcceptedPrivacyPolicy)
      prefsController.remove(forKey: .hasSeenPushIntro)
      prefsController.remove(forKey: .isAppSetupPending)
      prefsController.setValue(true, forKey: .runAtLeastOnce)
    }
  }

  /// On a change or first definition of the version, clearing all prefs (including .runAtLeastOnce) triggers the first-run wipe
  private func resetAppDataIfVersionChanged() {
    let storedVersion = prefsController.getValue(forKey: .appDataVersion) as? Int
    guard storedVersion != Self.currentAppDataVersion else {
      return
    }
    Prefs.Key.allCases
      .forEach { prefsController.remove(forKey: $0) }
    prefsController.setValue(Self.currentAppDataVersion, forKey: .appDataVersion)
  }

  func clearFirstRunFlag() {
    prefsController.remove(forKey: .runAtLeastOnce)
    keyChainController.clear()
    keyChainController.clearAllKeychainItems()
  }

  func storedRevocationCode() throws -> String? {
    guard let code = try secureEnclaveController.retrieveDecryptedString(keyTag: .wpbWiRevocationCode),
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

  func hasSeenAppIntro() -> Bool {
    prefsController.getBool(forKey: .hasSeenAppIntro)
  }

  func markAppIntroSeen() {
    prefsController.setValue(true, forKey: .hasSeenAppIntro)
    prefsController.setValue(true, forKey: .isAppSetupPending)
  }

  func isAppSetupPending() -> Bool {
    prefsController.getBool(forKey: .isAppSetupPending)
  }

  func markAppSetupCompleted() {
    prefsController.remove(forKey: .isAppSetupPending)
  }

  func hasSeenPlatformAuthIntro() -> Bool {
    prefsController.getBool(forKey: .hasSeenPlatformAuthIntro)
  }

  func markPlatformAuthIntroSeen() {
    prefsController.setValue(true, forKey: .hasSeenPlatformAuthIntro)
  }

  func isPlatformAuthenticationEnabled() async -> Bool {
    await appBlockingController.blockingState(for: [.platformAuthentication]) == nil
  }

  func hasAcceptedPrivacyPolicy() -> Bool {
    prefsController.getBool(forKey: .hasAcceptedPrivacyPolicy)
  }

  func markPrivacyPolicyAccepted() {
    prefsController.setValue(true, forKey: .hasAcceptedPrivacyPolicy)
  }

  func hasSeenPushIntro() -> Bool {
    prefsController.getBool(forKey: .hasSeenPushIntro)
  }

  func markPushIntroSeen() {
    prefsController.setValue(true, forKey: .hasSeenPushIntro)
  }

  func requestPushAuthorization() async -> Bool {
    let isGranted = await pushAuthorizationProvider.requestAuthorization()
    if isGranted {
      await pnsAccountInteractor.syncAccountIfNeeded()
    }
    return isGranted
  }
}

enum StartupError: LocalizedError, Equatable {
  case mdvmRegistrationFailed
}
