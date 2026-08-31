//
//  InvalidPinRetryMessageViewModel.swift
//  feature-common
//

import logic_ui
import logic_resources
import logic_api
import feature_common

@Copyable
public struct InvalidPinRetryMessageViewState: ViewState {
  let config: UIConfig.InvalidPinRetryMessageConfig
}

final class InvalidPinRetryMessageViewModel<Router: RouterHost>: ViewModel<Router, InvalidPinRetryMessageViewState> {
  @Published var countdownText: String = ""
  @Published var showInfoSheet: Bool = false
  @Published var showForgotPinPopup: Bool = false
  @Published var showCounterView: Bool = true
  @Published var showWarningMessageView: Bool = true
  @Published var showBlockedUserButtons: Bool = false

  private var timer: Timer?
  private var targetDate: Date?
  var warningImage: Image = Theme.shared.image.errorIndicatorIcon
  var warningMessage: String?
  var topSpacerHeightFactor = 5.0

  var confirmationPopupViewModel: ConfirmationPopupViewModel!
  var pidRevokeInteractor: PIDRevokeInteractor
  private let prefsController: PrefsController
  private let deepLinkController: DeepLinkController
  
  public init(
    router: Router,
    config: any UIConfigType,
    pidRevokeInteractor: PIDRevokeInteractor,
    prefsController: PrefsController,
    deepLinkController: DeepLinkController
  ) {
    guard let config = config as? UIConfig.InvalidPinRetryMessageConfig else {
      fatalError("Config error :: config must be of type UIConfig.InstructionsViewConfig")
    }
    self.pidRevokeInteractor = pidRevokeInteractor
    self.prefsController = prefsController
    self.deepLinkController = deepLinkController
    
    super.init(
      router: router,
      initialState: .init(
        config: config
      )
    )
    setupWarningIcon()
    setupConfirmationPopup()
    startTimer()
    setupWarningMessageView()
    setupButtons()
  }

  private func setupConfirmationPopup() {
    confirmationPopupViewModel = ConfirmationPopupViewModel()
    confirmationPopupViewModel.configure(
      title: LocalizableStringKey.pidPresentationRetryCounterResetOverlayTitle.toString,
      detail: LocalizableStringKey.pidPresentationRetryCounterResetOverlayParagraph.toString,
      titleIcon: Theme.shared.image.warningIndicator,
      confirmButtonBackgroundColor: DSColor.error,
      primaryButtontitle: LocalizableStringKey.pidPresentationRetryCounterResetOverlayButton.toString,
      secondaryButtontitle: LocalizableStringKey.back.toString,
      primaryAction: {
        Task {
          await self.resetWallet()
        }
      },
      secondaryAction: {
        self.showForgotPinPopup = false
      }
   )
  }

  private func setupWarningIcon() {
    guard let response = viewState.config.invalidPasswordResponse else {
      return
    }
    if response.isBlocked {
      warningImage = Theme.shared.image.redWarningIndicator
      warningMessage = LocalizableStringKey.walletPinBlockedMessage.toString
      showCounterView = false
    } else {
      warningImage = Theme.shared.image.orangeRetryError
      if response.tryCounter == 1 {
        warningMessage = LocalizableStringKey.walletPinLastTryLeft.toString
      }
    }
  }

  private func setupWarningMessageView() {
    if let response = viewState.config.invalidPasswordResponse,
       let tryCounter = response.tryCounter {
      if tryCounter < 2 {
        showWarningMessageView = true
      }
    }
  }

  private func setupButtons() {
    if let response = viewState.config.invalidPasswordResponse, response.isBlocked {
      showBlockedUserButtons = true
    } else {
      showBlockedUserButtons = false
    }
  }

  func resetWallet() async {
    do {
      try await pidRevokeInteractor.deletePIDFromWallet()
    } catch {
      // Reset did not complete; do not advance to startup with a half-torn-down wallet.
      return
    }
    await deepLinkController.setDeeplinkFlowFlag(false)
    router.popTo(with: .featureStartupModule(.startup))
  }

  func sendUserToDashboard() {
    router.popTo(with: .featureStartupModule(.startup))
  }

  private func startTimer() {
    timer?.invalidate()

    timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
        self?.updateCountdown()
    }
  }

  private func updateCountdown() {
    guard let targetDate = viewState.config.invalidPasswordResponse?.tryAllowedAfter?.convertStringTimestampToDate() else { return }

    let now = Date()
    let remaining = targetDate.timeIntervalSince(now)

    if remaining <= 0 {
      timer?.invalidate()
      countdownText = "00:00:00"
      
      if let remoteSessionCoordinator = viewState.config.remoteSessionCoordinator {
        prefsController.remove(forKey: .invalidPinResponse)
        router.push(
          with: .featurePresentationModule(
            .presentationRPInfo(
              presentationCoordinator: remoteSessionCoordinator,
              originator: .featureDashboardModule(.dashboard)
            )
          )
        )
      } else {
        router.popTo(with: .featurePresentationModule(.showPinView(config: NoConfig())))
      }
    } else {
        countdownText = formatTime(from: remaining)
    }
  }

  private func formatTime(from interval: TimeInterval) -> String {
    let seconds = Int(interval)
    let hours = seconds / 3600
    let minutes = (seconds % 3600) / 60
    let secs = seconds % 60

    return String(format: "%02d:%02d:%02d", hours, minutes, secs)
  }

  func getTimeLeftToRetry() -> String {
    if let response = viewState.config.invalidPasswordResponse,
       let tryAllowedAfter = response.tryAllowedAfter,
        let result = response.timestamp.timeDifference(to: tryAllowedAfter) {
      return result
    }
    return ""
  }

  deinit {
    timer?.invalidate()
  }
  
}
