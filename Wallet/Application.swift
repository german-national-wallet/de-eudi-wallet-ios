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
import SwiftUI
import PartialSheet
import logic_assembly
import feature_common
import logic_business

@main
struct Application: App {

  @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
  @Environment(\.scenePhase) var scenePhase

  @State var blurType: BlurType = .none
  @State var toolbarConfig: UIConfig.ToolBar = .init(Theme.shared.color.surface)
  @State private var blockingScreen: AppBlockingState?
  @StateObject private var appErrorPopupViewModel = ConfirmationPopupViewModel()

  private let routerHost: RouterHost
  private let appBlockingController: AppBlockingController
  private let deepLinkController: DeepLinkController
  private let walletKitController: WalletKitController
  private let keyChainController: KeyChainController
  private let debugConfigController: DebugConfigController
  private let walletRevocationInteractor: WalletRevocationInteractor

  init() {
    DIGraph.assembleDependenciesGraph()
   
    self.routerHost = DIGraph.resolver.force(RouterHost.self)
    self.appBlockingController = DIGraph.resolver.force(AppBlockingController.self)
    self.deepLinkController = DIGraph.resolver.force(DeepLinkController.self)
    self.walletKitController = DIGraph.resolver.force(WalletKitController.self)
    self.keyChainController = DIGraph.resolver.force(KeyChainController.self)
    self.debugConfigController = DIGraph.resolver.force(DebugConfigController.self)
    self.walletRevocationInteractor = DIGraph.resolver.force(WalletRevocationInteractor.self)
    
    self.toolbarConfig = routerHost.getToolbarConfig()

#if DEBUG
    if CommandLine.arguments.contains("--ui-testing") {
      // Start a UI-test run from a clean wallet: wipe all stored documents and the
      if CommandLine.arguments.contains("--reset-wallet") {
        keyChainController.clearAllKeychainItems()
        // Also reset the "revocation onboarding seen" flag so a reset wallet
        // re-shows the revocation screens, giving UI tests a deterministic state.
        DIGraph.resolver.force(PrefsController.self).remove(forKey: .hasSeenRevocationCode)
      }

      UIView.setAnimationsEnabled(false)
      UIApplication.shared
        .connectedScenes
        .filter { $0.activationState == .foregroundActive }
        .compactMap { $0 as? UIWindowScene }
        .first?
        .windows
        .first { $0.isKeyWindow }?.layer
        .speed = 100
    }
#endif
  }

  var body: some Scene {
    WindowGroup {
      ZStack {
        Rectangle()
          .fill(toolbarConfig.backgroundColor)
          .frame(maxWidth: .infinity, maxHeight: .infinity)
          .edgesIgnoringSafeArea(.all)
          .animation(
            .easeIn(duration: UINavigationController.hideShowBarDuration),
            value: toolbarConfig.backgroundColor
          )

        routerHost.composeApplication()
          .ignoresSafeArea()
          .attachPartialSheetToRoot()

        if blurType != .none {
          BlurView(style: .regular)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .ignoresSafeArea(.all)
        }
        if let blockingScreen {
          renderBlockingView(for: blockingScreen)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.white)
        }
        if appErrorPopupViewModel.isVisible {
          ConfirmationPopupView(viewModel: appErrorPopupViewModel)
        }
      }
      .preferredColorScheme(.light)
      .onOpenURL { url in
          if let deepLink = deepLinkController.hasDeepLink(url: url) {
            Task {
              deepLinkController.handleDeepLinkAction(
                routerHost: routerHost,
                deepLinkExecutable: deepLink,
                remoteSessionCoordinator: deepLink.requiresCoordinator
                ? await walletKitController.startSameDevicePresentation(deepLink: deepLink.link)
                : nil
              )
            }
          }
      }
      .task {
        await startAppBlockingStateChecks()
      }
      .onChange(of: scenePhase) { phase in
        switch phase {
        case .background:
          self.blurType = .background
        case .inactive:
          self.blurType = .inactive
        case .active:
          Task {
            await evaluateBlockingStates()
            refreshFeatureFlagsInBackground()
          }
        default: break
        }
      }
      .onReceive(NotificationCenter.default.publisher(for: .shouldChangeBackgroundColor), perform: { _ in
        self.toolbarConfig = routerHost.getToolbarConfig()
      })
      .onReceive(NotificationCenter.default.publisher(for: .showAppSecurityError), perform: { _ in
        appErrorPopupViewModel.configureDefaultError { }
      })
      .onReceive(NotificationCenter.default.publisher(for: .walletRevocationConfirmed), perform: { _ in
        Task {
          await evaluateBlockingStates(for: [.walletRevoked])
        }
      })
    }
  }
 
  private func deleteAllData() async {
    await walletKitController.clearAllDocuments()
    keyChainController.clear()
    keyChainController.clearKeyChainBiometry()
    keyChainController.clearAllKeychainItems()
    await deepLinkController.clearFirstRunFlag()
    /// Runs on the attestation-blocking path: overrides pointing at an environment that fails
    /// attestation would block every launch before the side menu is reachable, so drop them here
    debugConfigController.clearAll()
  }

  @MainActor
  private func startAppBlockingStateChecks() async {
    await evaluateBlockingStates(for: [.walletRevoked, .minimumAppVersion])
    refreshFeatureFlagsInBackground()
  }

  /// Flags are only fetched when the cached payload is stale, so this is a "no-op" on most launches and resumes, but can help if a user doesn't kill the app every day
  private func refreshFeatureFlagsInBackground() {
    Task {
      await appBlockingController.refreshFeatureFlagsIfNeeded()
      await evaluateBlockingStates(for: [.minimumAppVersion])
    }
  }

  @MainActor
  private func evaluateBlockingStates(for checkedRules: Set<AppBlockingRule> = [.walletRevoked, .platformAuthentication, .minimumAppVersion]) async {
    let previousBlockingScreen = blockingScreen
    guard let blockingState = await appBlockingController.blockingState(for: checkedRules) else {
      handleNoBlockingState(previousBlockingScreen: previousBlockingScreen, checkedRules: checkedRules)
      return
    }

    switch blockingState {
    case .walletRevoked:
      showWalletRevokedBlockingScreen(
        shouldDeleteData: previousBlockingScreen != .walletRevoked
      )

    case .platformAuthentication:
      showPlatformAuthenticationBlockingScreen(
        shouldDeleteData: previousBlockingScreen != .platformAuthentication
      )

    case .minimumAppVersion:
      showMinimumAppVersionBlockingScreen(previousBlockingScreen: previousBlockingScreen)
    }
  }

  private func showWalletRevokedBlockingScreen(shouldDeleteData: Bool) {
    blurType = .background
    blockingScreen = .walletRevoked
    if shouldDeleteData {
      Task {
        await deleteAllData()
      }
    }
  }

  private func showPlatformAuthenticationBlockingScreen(shouldDeleteData: Bool) {
    blurType = .background
    blockingScreen = .platformAuthentication
    if shouldDeleteData {
      Task {
        await deleteAllData()
      }
    }
  }

  private func showMinimumAppVersionBlockingScreen(previousBlockingScreen: AppBlockingState?) {
    if previousBlockingScreen == .platformAuthentication {
      restoreAppFlowAfterPlatformAuthenticationBlockingScreen()
    }
    blurType = .background
    blockingScreen = .minimumAppVersion
  }

  private func acknowledgeRevocationAndResetWallet() {
    Task {
      await deleteAllData()
      walletRevocationInteractor.resetAfterRevocation()
      await deepLinkController.setDeeplinkFlowFlag(false)
      await MainActor.run {
        clearBlockingScreen()
        routerHost.resetNavigation(to: .featureStartupModule(.startup))
      }
    }
  }

  private func restoreAppFlowAfterPlatformAuthenticationBlockingScreen() {
    Task {
      await deleteAllData()
      await deepLinkController.setDeeplinkFlowFlag(false)
      await MainActor.run {
        routerHost.resetNavigation(to: .featureStartupModule(.startup))
      }
    }
  }

  private func handleNoBlockingState(previousBlockingScreen: AppBlockingState?, checkedRules: Set<AppBlockingRule>) {
    if previousBlockingScreen == .walletRevoked {
      if checkedRules.contains(.walletRevoked) {
        clearBlockingScreen()
      }
      return
    }
    if previousBlockingScreen == .platformAuthentication && checkedRules.contains(.platformAuthentication) {
      restoreAppFlowAfterPlatformAuthenticationBlockingScreen()
      clearBlockingScreen()
      return
    }

    if previousBlockingScreen == .minimumAppVersion && checkedRules.contains(.minimumAppVersion) {
      clearBlockingScreen()
      return
    }

    if checkedRules.contains(.platformAuthentication) {
      clearBlockingScreen()
    }
  }

  private func clearBlockingScreen() {
    blurType = .none
    blockingScreen = nil
  }

  @ViewBuilder
  private func renderBlockingView(for blockingScreen: AppBlockingState) -> some View {
    switch blockingScreen {
    case .walletRevoked:
      AppBlockingView(
        title: LocalizableStringKey.globalErrorWalletRevoked.toString,
        description: LocalizableStringKey.globalErrorWalletRevokedBody.toString,
        buttonTitle: LocalizableStringKey.globalErrorWalletRevokedPrimButton.toString,
        action: acknowledgeRevocationAndResetWallet
      )
    case .platformAuthentication:
      AppBlockingView(
        title: LocalizableStringKey.securityCheckAlertTile.toString,
        description: LocalizableStringKey.securityCheckAlertDescription.toString,
        buttonTitle: LocalizableStringKey.securityCheckButtonTitle.toString,
        action: openSettings
      )
    case .minimumAppVersion:
      // TODO: add proper localizations
      let isGerman = Locale.preferredLanguages.first?.hasPrefix("de") == true
      AppBlockingView(
        title: isGerman ? "Update erforderlich" : "Update required",
        description: isGerman
          ? "Bitte aktualisiere die App, um fortzufahren."
          : "A newer version of the app is required before you can continue. Please update the app, then open it again.",
        buttonTitle: isGerman ? "App aktualisieren" : "Update app",
        action: openAppUpdate
      )
    }
  }

  private func openAppUpdate() {
    guard let url = appBlockingController.appUpdateURL else {
      return
    }
    UIApplication.shared.open(url)
  }

  private func openSettings() {
    guard let settingsURL = URL(string: Constants.appPreferences) else {
      return UIApplication.shared.openAppSettings()
    }
    UIApplication.shared.open(settingsURL, options: [:]) {
      if !$0 {
        UIApplication.shared.openAppSettings()
      }
    }
  }
}

extension Application {
  enum BlurType {
    case inactive
    case background
    case none
  }
}

extension Notification.Name {
  static let showAppSecurityError = Notification.Name("showAppSecurityError")
}
