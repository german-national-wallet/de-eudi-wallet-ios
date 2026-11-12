//
//  PINViewModel+Extension.swift
//  feature-common
//
@_exported import logic_ui
@_exported import logic_resources
import logic_api
import logic_core

extension PINViewModel: IssuanceVerificationInteractorDelegate {
  public func onBadState(error: String) {
    // TODO: To be implemented
  }

  public func tcTokenExpired() {}

  public func canEnteredCorrectly() {
    onCanCorrect()
  }

  public func onChangePinCompleted(success: Bool) {
    if success {
      let config = UIConfig.Success(
        title: UIConfig.Success.Title(value: .cardPinSetSuccesfully),
        buttons: [],
        visualKind: .defaultIcon,
        nextRoute: .popTo(
          .featureIssuanceModule(
            .issuanceAddDocument(config: NoConfig())
          )))
      DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
        self.router.push(with: .featureIssuanceCardModule(.issuanceSuccessView(config: config)))
      }
    } else {
      router.popTo(with: .featureIssuanceModule(.issuanceAddDocument(config: NoConfig())))
    }
  }

  public func didSuccess(result: String) {
    onPinEntered?.onEntered(result)
  }

  public func didRecognizeCard() {}

  public func didNotRecognizeCard() {}

  public func requestPin() {
    onPinEntered?.onEntered("success")
    router.popTo(with: .featureIssuanceModule(.issuanceCard(config: NoConfig(), requestURI: "", eidPin: "", delegate: self)))
  }

  public func stopIssuanceFlow(with error: Error?) {
    logger?.e("stopIssuanceFlow error: \(String(describing: error))")
  }

  public func didRequestCAN() {}

  public func invalidCANEntered(error: Error?, cardStatusInfo: CardStatusInfo?) {
    if error != nil {
      isInvalidPin = true
      errorMessage = LocalizableStringKey.issuanceErrorWrongCan.toString
    }
  }

  public func invalidPinErrorReceived(error: Error?, cardStatusInfo: CardStatusInfo?) {
    logger?.e("PINViewModel invalidPinErrorReceived")
    isInvalidPin = true
  }

  func getErrorRoute(isGenericError: Bool = false) -> AppRoute {
    let title: LocalizableStringKey = isGenericError ? .genericErrorTitle : .invalidQuickPin
    let caption: LocalizableStringKey? = isGenericError ? .genericErrorDesc : nil

    switch viewState.config.pinScreenType {
    case .issueEidPinFlow:
      let errorConfig = UIConfig.InvalidPin(title: title, caption: caption, navigationSuccessType: .pop, navigationCancelType: .popTo(.featureIssuanceModule(.issuanceAddDocument(config: NoConfig()))), primaryButtonTitle: .tryAgain)
      return AppRoute.featureCommonModule(.errorView(config: errorConfig))

    default:
      let errorConfig = UIConfig.InvalidPin(title: title, caption: caption, navigationSuccessType: .pop, navigationCancelType: .popTo(.featureDashboardModule(.dashboard)), primaryButtonTitle: .tryAgain)
      return AppRoute.featureCommonModule(.errorView(config: errorConfig))
    }
  }

  public func setNewPin() {}

  // MARK: - PIN flows helper functions

  func eidCanFlow() {
    issuanceVarificationInteractor?.setCAN(pinString)
  }
  func eidPinAfterCanFlow() {
    issuanceVarificationInteractor?.setPin(pinString)
  }
  func verifyWalletPinFlow() {
    if pin.count == viewState.config.quickPinSize {
      // Capture the entered PIN synchronously: the view clears `pin` right after onSendData(),
      // so reading `pinString` inside the Task below would race with that clear.
      let enteredPin = pinString
      Task {
        await verifyWalletPin(enteredPin)
        pin.removeAll()
      }
    }
  }

  private func verifyWalletPin(_ enteredPin: String) async {
    do {
      setState { $0.copy(isLoading: true) }
      try await pinSessionInteractor.set(pin: enteredPin)
      setState { $0.copy(isLoading: false) }
      doNavigation(navigationType: viewState.config.navigationSuccessType)
    } catch where connectivityMonitor.isNoInternet(error) {
      setState { $0.copy(isLoading: false) }
      presentNoInternetDialog { [weak self] in
        await self?.verifyWalletPin(enteredPin)
      }
    } catch let error where TransportFailure.find(in: error) != nil {
      setState { $0.copy(isLoading: false) }
      presentTransportFailureDialog(for: error)
    } catch {
      setState { $0.copy(isLoading: false) }
      logger?.e("setPin failed (1) \(error.logDescriptor) code=\((error as? BackendError)?.errorCode ?? "")")

      if (error as? BackendError)?.errorCode == RWSCAServerErrorCode.accountLocked {
        router.push(
          with: .featurePresentationModule(
            .pinRetryCounterView(
              config: UIConfig.InvalidPinRetryMessageConfig(
                mainTitle: .walletPinForgotten,
                retryMessage: .walletPinBlockedMessage,
                primaryButtonTitle: .pidPresentationRetryCounterRouteToOverview
              )
            )
          )
        )
      } else if error.isIOSAttestationFailure {
        showInlinePinError(LocalizableStringKey.genericErrorDesc.toString)
      } else if error is SecureEnclaveControllerError {
        showInlinePinError(LocalizableStringKey.genericErrorDesc.toString)
      } else {
        showInlinePinError(LocalizableStringKey.walletPinWrongEntry.toString)
      }
    }
  }
  
  func issueEidPinFlow() {
    if pin.count == viewState.config.quickPinSize {
      // Capture the entered PIN synchronously: the view clears `pin` right after onSendData(),
      // so reading `pinString` after the await below would yield an empty string.
      let enteredPin = pinString
      Task {
        await startEidPinIssuance(with: enteredPin)
      }
    }
  }

  private func startEidPinIssuance(with enteredPin: String) async {
    do {
      setState { $0.copy(isLoading: true) }

      let pendingDoc = try await parInteractor.fetchPushAuthorisationRequest()

      guard let parURI = pendingDoc?.authorizePresentationUrl else {
        throw PARGenerationError.wiaParCreationFailed
      }
      router.push(
        with: .featureIssuanceCardModule(
          .issuanceCard(
            config: IssuanceFlowUiConfig(
              flow: .noDocument,
            ),
            requestURI: parURI, eidPin: enteredPin, delegate: self
          )
        )
      )
      setState { $0.copy(isLoading: false) }
    } catch where connectivityMonitor.isNoInternet(error) {
      setState { $0.copy(isLoading: false) }
      presentNoInternetDialog { [weak self] in
        await self?.startEidPinIssuance(with: enteredPin)
      }
    } catch let error where TransportFailure.find(in: error) != nil {
      setState { $0.copy(isLoading: false) }
      presentTransportFailureDialog(for: error)
    } catch {
      logger?.e("setPin failed (2): \(error.logDescriptor)")
      setState { $0.copy(isLoading: false) }
      showInlinePinError(LocalizableStringKey.genericErrorDesc.toString)
    }
  }

  func transportPinFlow() {
    let enteredPin = pinString
    Task {
      await startTransportPinIssuance(with: enteredPin)
    }
  }

  private func startTransportPinIssuance(with enteredPin: String) async {
    do {
      setState { $0.copy(isLoading: true) }
      let pendingDoc = try await parInteractor.fetchPushAuthorisationRequest()
      guard let parURI = pendingDoc?.authorizePresentationUrl else {
        throw PARGenerationError.wiaParCreationFailed
      }
      router.push(
        with: .featureIssuanceCardModule(
          .issuanceCard(
            config: IssuanceFlowUiConfig(
              flow: .noDocument
            ), requestURI: parURI, eidPin: enteredPin, eidPinFlow: .setEidPin, delegate: self
          )
        )
      )
      setState { $0.copy(isLoading: false) }
    } catch where connectivityMonitor.isNoInternet(error) {
      setState { $0.copy(isLoading: false) }
      presentNoInternetDialog { [weak self] in
        await self?.startTransportPinIssuance(with: enteredPin)
      }
    } catch let error where TransportFailure.find(in: error) != nil {
      setState { $0.copy(isLoading: false) }
      presentTransportFailureDialog(for: error)
    } catch {
      logger?.e("transport PIN PAR failed: \(error.logDescriptor)")
      setState { $0.copy(isLoading: false) }
      showInlinePinError(LocalizableStringKey.genericErrorDesc.toString)
    }
  }
  func transportPinRetryFlow() {
    onPinEntered?.onEntered(pinString)
  }
  func eidPinRetryFlow() {
    onPinEntered?.onEntered(pinString)
  }
  func setupNewEidPinFlow() {
    router.push(with:
        .featureIssuanceCardModule(
          .pinView(
            config: UIConfig.Biometry(
              navigationTitle: .setNewEidPinTwo,
              caption: nil,
              primaryButtonTitle: .eidSetupCardPinReenterPrimButton,
              quickPinOnlyCaption: .space,
              navigationSuccessType: .pop,
              navigationErrorScreen: nil,
              navigationBackType: .pop,
              isPreAuthorization: false,
              shouldInitializeBiometricOnCreate: true,
              invalidPinTitle: .confirmationPinMismatch,
              pinScreenType: .confirmNewEIDPinFlow,
              imageIcon: Theme.shared.image.personalausweisLogo,
              imageSize: CGSize(width: 105.0089, height: 144.0464),
              quickPinSize: 6,
              pinForConfirmationFlow: pinString
            ),
            onPinEntered: nil,
            issuanceVerificationInteractor: issuanceVarificationInteractor
          )
        )
    )

  }
  func confirmNewEIDPinFlow() {
    if viewState.config.pinForConfirmationFlow == pinString {
      self.issuanceVarificationInteractor?.assignNewPin(pinString)
      self.router.popTo(with: .featureIssuanceModule(.issuanceCard(config: NoConfig(), requestURI: "", eidPin: "", delegate: self)))
    } else {
      showInlinePinError(viewState.config.invalidPinTitle.toString)
      logger?.e("The two pins doesnt match")
    }

  }
  func setupWalletPinFlow() {
    guard let authResponseDTO = viewState.config.finishAuthorizationResponseDTO else {
      logger?.e("PINViewModel:: onSendData not complete")
      return
    }
    let config = UIConfig.Biometry(
      navigationTitle: .walletPinSetupConfirmTitle,
      primaryButtonTitle: .pidIssuanceWalletPinReenterPrimButton,
      quickPinOnlyCaption: .space,
      navigationSuccessType: .pop,
      navigationErrorScreen: nil,
      navigationBackType: .pop,
      isPreAuthorization: false,
      shouldInitializeBiometricOnCreate: true,
      invalidPinTitle: .setupWalletPinIncorrectRetypeEntry,
      pinScreenType: .confirmNewWalletPinFlow,
      progressSteps: .init(current: 4, total: 4),
      imageIcon: Theme.shared.image.setupWalletPin,
      imageSize: CGSize(width: 60, height: 96),
      quickPinSize: 6,
      pinForConfirmationFlow: pinString,
      finishAuthorizationResponseDTO: authResponseDTO
    )
    router.push(with: .featureIssuanceCardModule(.pinView(config: config)))

  }

  func confirmNewWalletPinFlow() async {
    // Capture the entered PIN synchronously: the view clears `pin` right after onSendData(),
    // so the value must be snapshotted before any await.
    let enteredPin = pinString
    guard viewState.config.pinForConfirmationFlow == enteredPin else {
      showInlinePinError(viewState.config.invalidPinTitle.toString)
      logger?.e("The two pins don't match")
      return
    }
    guard let authResponseDTO = viewState.config.finishAuthorizationResponseDTO else {
      logger?.e("PINViewModel:: confirmNewWalletPinFlow: missing authResponseDTO")
      return
    }
    await setWalletPin(enteredPin, authResponseDTO: authResponseDTO)
  }

  private func setWalletPin(_ enteredPin: String, authResponseDTO: FinishAuthorizationResponse) async {
    setState { $0.copy(isLoading: true) }
    do {
      try await pinSessionInteractor.set(pin: enteredPin)
      setState { $0.copy(isLoading: false) }
      router.push(
        with: .featureIssuanceModule(
          .issuanceLoadingView(
            config: UIConfig.IssuanceLoadingUiConfig(
              finishAuthorizationResponse: authResponseDTO
            )
          )
        )
      )
    } catch where connectivityMonitor.isNoInternet(error) {
      setState { $0.copy(isLoading: false) }
      presentNoInternetDialog { [weak self] in
        await self?.setWalletPin(enteredPin, authResponseDTO: authResponseDTO)
      }
    } catch let error where TransportFailure.find(in: error) != nil {
      setState { $0.copy(isLoading: false) }
      presentTransportFailureDialog(for: error)
    } catch {
      logger?.e("PINViewModel:: failed to set pin: \(error)")
      setState { $0.copy(isLoading: false) }
      if error.isIOSAttestationFailure {
        showInlinePinError(LocalizableStringKey.genericErrorDesc.toString)
      } else if error is SecureEnclaveControllerError {
        showInlinePinError(LocalizableStringKey.genericErrorDesc.toString)
      } else {
        showInlinePinError(LocalizableStringKey.walletPinWrongEntry.toString)
      }
    }
  }

  private func presentNoInternetDialog(retry: @escaping () async -> Void) {
    noInternetDialog.present(
      retry: { Task { await retry() } },
      cancel: { [weak self] in self?.router.pop() }
    )
  }
  private func presentTransportFailureDialog(for error: Error) {
    guard let failure = TransportFailure.find(in: error) else { return }
    logger?.e("PINViewModel:: transport failure: \(failure)")
    isErrorPopupVisible = true

    guard failure.kind != .rateLimited else {
      errorPopupViewModel.configure(
        transportFailure: failure,
        dismiss: { [weak self] in
          self?.isErrorPopupVisible = false
          self?.canFocus = true
        }
      )
      return
    }

    if viewState.config.pinScreenType == .verifyWalletPinFlow {
      configurePresentationTimeout()
    } else {
      errorPopupViewModel.configureIssuanceRestart(
        startAgain: { [weak self] in
          self?.isErrorPopupVisible = false
          self?.router.restartIssuance()
        },
        cancel: { [weak self] in
          self?.isErrorPopupVisible = false
          self?.handleCloseButton()
        }
      )
    }
  }

  private func configurePresentationTimeout() {
    let cancel: () -> Void = { [weak self] in
      self?.isErrorPopupVisible = false
      self?.handleCloseButton()
    }
    let serviceProviderURL = presentationOriginStore.getServiceProviderURL()
    let backToServiceProvider: (() -> Void)? = serviceProviderURL.map { url in
      { [weak self] in
        self?.isErrorPopupVisible = false
        UIApplication.shared.open(url)
        self?.handleCloseButton()
      }
    }
    errorPopupViewModel.configure(
      title: LocalizableStringKey.pidPresentationTimeoutRpTitle.toString,
      detail: LocalizableStringKey.pidPresentationTimeoutRpParagraph.toString,
      titleIcon: Theme.shared.image.warning,
      primaryButtontitle: backToServiceProvider != nil
        ? LocalizableStringKey.pidPresentationTimeoutRpPrimButton.toString
        : LocalizableStringKey.pidPresentationTimeoutRpSecButton.toString,
      primaryButtonTrailingIcon: backToServiceProvider != nil ? Theme.shared.image.externalLink : nil,
      secondaryButtontitle: backToServiceProvider != nil
        ? LocalizableStringKey.pidPresentationTimeoutRpSecButton.toString
        : nil,
      primaryAction: backToServiceProvider ?? cancel,
      secondaryAction: backToServiceProvider != nil ? cancel : nil
    )
  }

  private func showInlinePinError(_ message: String) {
    errorMessage = message
    isInvalidPin = true
  }
}

private extension Error {
  var isIOSAttestationFailure: Bool {
    (self as? BackendError)?.errorCode == MDVMServerErrorCode.iosAttestationFailure
  }
}
