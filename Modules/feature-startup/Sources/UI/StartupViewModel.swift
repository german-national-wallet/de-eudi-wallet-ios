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
import logic_business
import logic_api
import logic_core
import logic_resources
import feature_issuance
import wallet_backend
import push_notification_service

@Copyable
struct StartupState: ViewState {
  let splashDuration: TimeInterval
  let isAnimating: Bool
  let setupError: Error?
}

final class StartupViewModel<Router: RouterHost>: ViewModel<Router, StartupState> {

  private let interactor: StartupInteractor
  private let walletRegistrationInteractor: WalletRegistrationInteractor
  private let pnsAccountInteractor: PNSAccountInteractor
  private let walletRevocationInteractor: WalletRevocationInteractor
  private let deepLinkController: DeepLinkController
  private let logger: Logging?

  @Published var isErrorPopupVisible = false
  var errorPopupViewModel = ConfirmationPopupViewModel()

  init(
    router: Router,
    interactor: StartupInteractor,
    walletRegistrationInteractor: WalletRegistrationInteractor,
    pnsAccountInteractor: PNSAccountInteractor,
    walletRevocationInteractor: WalletRevocationInteractor,
    deepLinkController: DeepLinkController,
    logger: Logging?,
    splashDuration: TimeInterval = 1.5
  ) {
    self.interactor = interactor
    self.walletRegistrationInteractor = walletRegistrationInteractor
    self.pnsAccountInteractor = pnsAccountInteractor
    self.walletRevocationInteractor = walletRevocationInteractor
    self.deepLinkController = deepLinkController
    self.logger = logger
    CustomFonts().loadFonts()

    super.init(
      router: router,
      initialState: .init(
        splashDuration: splashDuration,
        isAnimating: false,
        setupError: nil
      )
    )
  }

  func startAnimatingSplash() {
    setState { $0.copy(isAnimating: true) }
  }

  func initialize() async -> AppRoute {
    await interactor.initializeAppFlow(with: viewState.splashDuration)
  }

  func registerWallet() async {
    defer { setState { $0.copy(isAnimating: false) } }
    guard !walletRevocationInteractor.isWalletRevoked else {
      logger?.d("wallet is revoked, skipping registration")
      return
    }
    do {
      let route = await initialize()

      _ = try await walletRegistrationInteractor.registerWalletInstance()

      /// Runs on both the wallet activation and every subsequent start-up, since this is the same
      /// code path. Detached and non-throwing on purpose: the PNS account is opt-in and
      /// best-effort, so it must never delay the start-up navigation or surface an error to the user.
      Task { [pnsAccountInteractor] in
        await pnsAccountInteractor.syncAccountIfNeeded()
      }

      let destination = revocationDestination(continueRoute: route)

      if await !deepLinkController.isDeeplinkFlowActive() {
        router.push(with: destination)
      } else if router.isScreenForeground(with: .featureStartupModule(.startup)),
                deepLinkController.getPendingDeepLinkAction() == nil {
        await deepLinkController.setDeeplinkFlowFlag(false)
        router.push(with: destination)
      }

    } catch let error as BackendError {
      logger?.e("wallet registration failed: \(error) code=\(error.errorCode) traceId=\(error.traceId) detail=\(error.serverDescription)")
      guard !walletRevocationInteractor.isWalletRevoked else {
        return
      }
      isErrorPopupVisible = true
      configureErrorPopupViewModel(error: error)
    } catch {
      logger?.e("wallet registration failed: \(error.localizedDescription)")
      isErrorPopupVisible = true
      configureErrorPopupViewModel(error: .unknown)
    }
  }

  private func revocationDestination(continueRoute: AppRoute) -> AppRoute {
    guard !interactor.hasSeenRevocationCode(),
          let revocationCode = interactor.storedRevocationCode() else {
      return continueRoute
    }

    let saveKeyRoute: AppRoute = .featureStartupModule(
      .revocationSaveKey(
        config: WalletRevocationSaveKeyUiConfig(
          revocationCode: revocationCode,
          continueRoute: continueRoute
        )
      )
    )

    return .featureStartupModule(
      .revocationOnboarding(config: WalletRevocationUiConfig(continueRoute: saveKeyRoute))
    )
  }

  func configureErrorPopupViewModel(error: BackendError) {
    errorPopupViewModel.configure(backendError: error) {
      self.isErrorPopupVisible = false
      self.closeButtonTapped()
    }
  }
}
