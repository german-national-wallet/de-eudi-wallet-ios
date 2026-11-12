//
//  IssuanceCardViewModel+Extension.swift
//  feature-issuance
//
import logic_ui
import logic_resources
import feature_common
import logic_business
import JOSESwift
import MdocDataModel18013
import logic_api
import logic_core

extension IssuanceCardViewModel: IssuanceVerificationInteractorDelegate {
  func onBadState(error: String) {
  }
  
  func tcTokenExpired() {
    // Reached from the AusweisApp SDK callback chain, which is not main-actor isolated.
    Task { @MainActor [weak self] in
      guard let self else { return }
      self.setState({$0.copy(isLoading: false)})
      self.isErrorPopupVisible = true
      self.errorPopupViewModel.configureIssuanceRestart(
        startAgain: { [weak self] in
          self?.isErrorPopupVisible = false
          self?.restartIssuanceAfterExpiredPAR()
        },
        cancel: { [weak self] in
          self?.isErrorPopupVisible = false
          self?.stopIssuanceFlow(with: nil)
        }
      )
    }
  }

  @discardableResult
  func restartIssuanceAfterExpiredPAR() -> Task<Void, Never> {
    Task { [weak self] in
      guard let self else { return }
      self.setState({$0.copy(isLoading: true)})
      // Every exit path, including thrown errors, must drop the spinner.
      defer { self.setState({$0.copy(isLoading: false)}) }
      do {
        try await parInteractor.removePendingDocs(of: viewState.requestURI)
        let pendingDoc = try await parInteractor.issuePAR()
        guard let parURI = pendingDoc.authorizePresentationUrl else {
          throw PARGenerationError.wiaParCreationFailed
        }
        self.setState({$0.copy(requestURI: parURI)})
        self.startAusweisReadFlow()
      } catch where connectivityMonitor.isNoInternet(error) {
        noInternetDialog.present(
          retry: { [weak self] in self?.restartIssuanceAfterExpiredPAR() },
          cancel: { [weak self] in self?.router.pop() }
        )
      } catch {
        self.isErrorPopupVisible = true
        if let failure = TransportFailure.find(in: error) {
          errorPopupViewModel.configure(
            transportFailure: failure,
            dismiss: { [weak self] in
              self?.isErrorPopupVisible = false
              self?.router.pop()
            },
            close: { [weak self] in self?.isErrorPopupVisible = false }
          )
        } else {
          errorPopupViewModel.configure(
            backendError: (error as? BackendError) ?? .unknown,
            analyticsTraceId: analyticsController.currentTraceID ?? ""
          ) { [weak self] in
            self?.isErrorPopupVisible = false
            self?.router.pop()
          }
        }
      }
    }
  }
  
  func canEnteredCorrectly() {}
  
  func didSuccess(result: String) {
    Task {
      await finishAuthorization(with: result)
    }
  }

  private func finishAuthorization(with result: String) async {
    do {
      finishAuthorizationResponseDTO = try await interactor.executeFinishAuthorizationRequest(result)
      guard finishAuthorizationResponseDTO != nil else { return }
      issuanceVarificationInteractor.stop()
      self.setState({$0.copy(isLoading: false)})
      let config = UIConfig.IssuancePidPreviewViewConfig(
        primaryRoute: .featureIssuanceModule(
          .walletPinSetupInstructionView(
            config: makeInstructionsConfig()
          )
        )
      )
      router.push(with: .featureIssuanceCardModule(.issuancePidPreviewView(config: config)))
    } catch where connectivityMonitor.isNoInternet(error) {
      self.setState({$0.copy(isLoading: false)})
      noInternetDialog.present(
        retry: { [weak self] in
          Task { await self?.finishAuthorization(with: result) }
        },
        cancel: { [weak self] in self?.stopIssuanceFlow(with: error) }
      )
    } catch {
      self.setState({$0.copy(isLoading: false)})
      logger?.e(error.logDescriptor)
    }
  }
  
  func didRecognizeCard() {
    logger?.d("didRecognizeCard")
  }
  
  func didNotRecognizeCard() {
    logger?.d("didNotRecognizeCard")
  }
  
  func requestPin() {
    issuanceVarificationInteractor.setPin(enteredPin)
  }
  
  func stopIssuanceFlow(with error: Error?) {
    self.setState {
      $0.copy(isLoading: false)
    }
    abandonIssuance()
    // Add-document is not on the stack when the PID is re-added from the overview, so a bare
    // popTo(.issuanceAddDocument) would silently do nothing there.
    self.router.cancelToStart()
  }
  
  func didRequestCAN() {
    logger?.d("didRequestCAN")
  }
  
  func invalidCANEntered(error: Error?, cardStatusInfo: CardStatusInfo?) {
    if error == nil {
      doNavigation(navigationType: .push(getCANViewRoute()))
    }
  }
  
  private func makeInstructionsConfig() -> UIConfig.InstructionsViewConfig {
    return UIConfig.InstructionsViewConfig(
      mainTitle: .walletPinSetupTitle,
      message: .walletPinSetupWarning,
      banner: .walletPinSetupBanner,
      image: Theme.shared.image.pinIllusItem,
      illustrationWidthFactor: 0.75,
      primaryButtonTitle: .walletPinSetupPrimaryButtonTitle,
      introStyle: .stepped(currentStep: 4, totalSteps: 4),
      primaryRoute: .featureIssuanceModule(.pinView(config: makeBiometryConfigForSetWalletPin(), issuanceVerificationInteractor: nil)),
      onClose: { [weak self] in self?.router.cancelToStart() }
    )
  }
  
  private func makeBiometryConfigForSetWalletPin() -> UIConfig.Biometry {
    return UIConfig.Biometry(
      navigationTitle: .setWalletPinTitle,
      primaryButtonTitle: .pidIssuanceWalletPinSetupPrimButton,
      quickPinOnlyCaption: .space,
      navigationSuccessType: .pop,
      navigationErrorScreen: nil,
      navigationBackType: .pop,
      isPreAuthorization: false,
      shouldInitializeBiometricOnCreate: true,
      invalidPinTitle: .issuanceCanEntryTitle,
      pinScreenType: .setupWalletPinflow,
      progressSteps: .init(current: 4, total: 4),
      imageIcon: Theme.shared.image.setupWalletPin,
      imageSize: CGSize(width: 80, height: 80),
      quickPinSize: 6,
      finishAuthorizationResponseDTO: finishAuthorizationResponseDTO
    )
  }
  
  private func getCANViewRoute() -> AppRoute {
    let pinEntryView = AppRoute.featureIssuanceModule(
      .pinView(config: UIConfig.Biometry(
        navigationTitle: .issuanceCanEntryTitle,
        caption: .canInfoTitle,
        primaryButtonTitle: .pidIssuanceCanEntryPrimButton,
        quickPinOnlyCaption: .space,
        navigationSuccessType: .pop,
        navigationErrorScreen: .push(getErrorRoute()),
        navigationBackType: .pop,
        isPreAuthorization: false,
        shouldInitializeBiometricOnCreate: true,
        invalidPinTitle: .issuanceErrorWrongCan,
        pinScreenType: .eidCanFlow,
        imageIcon: Theme.shared.image.ausweisCanHighlighted,
        imageSize: CGSize(width: 80, height: 80)
      ),
               onPinEntered: PinCallbackWrapper(onEntered: { can in
                 Task { @MainActor in
                   if can == "success" {
                     self.router.pop(animated: true)
                   } else {
                     self.didSuccess(result: can)
                   }
                   self.issuanceVarificationInteractor.setDelegate(self)
                 }
               }),
               issuanceVerificationInteractor: issuanceVarificationInteractor
      )
   )
    
    let errorConfig = UIConfig.InvalidPin(
      title: .cardPinEnteredWrongTwice,
      caption: .cardPinEnteredWrongDescription,
      navigationSuccessType: .push(pinEntryView),
      navigationCancelType: .popTo(.featureIssuanceModule(.issuanceAddDocument(config: NoConfig()))),
      primaryButtonTitle: .canEingeben,
      secondaryButtonTitle: .canInfoTitle,
      pinScreenType: .eidCanFlow
    )
    return AppRoute.featureCommonModule(.errorView(config: errorConfig))
  }
  
  private func getErrorRoute() -> AppRoute {
    let errorConfig = UIConfig.InvalidPin(title: .invalidQuickPin, navigationSuccessType: .pop, navigationCancelType: .popTo(.featureIssuanceModule(.issuanceAddDocument(config: NoConfig()))), primaryButtonTitle: .tryAgain)
    return AppRoute.featureCommonModule(.errorView(config: errorConfig))
  }
  
  func invalidPinErrorReceived(error: (any Error)?, cardStatusInfo: CardStatusInfo?) {
    switch viewState.eidFlow {
    case .setEidPin:
      doNavigation(navigationType: .push(getTransportPinRetryRoute()))
    case .authentication, .confirmNewPin:
      doNavigation(navigationType: .push(getInvalidPinRoute()))
    }
  }

  func getTransportPinRetryRoute() -> AppRoute {
    AppRoute.featureIssuanceModule(
      .pinView(
        config: UIConfig.Biometry(
          navigationTitle: .transportPinViewTitle,
          caption: .setupPinTransportViewSecondaryButtonTitle,
          quickPinOnlyCaption: .space,
          navigationSuccessType: .pop,
          navigationErrorScreen: nil,
          navigationBackType: .pop,
          isPreAuthorization: true,
          shouldInitializeBiometricOnCreate: true,
          invalidPinTitle: .transportPinWrongEntry,
          initialErrorMessage: .transportPinWrongEntry,
          pinScreenType: .transportPinRetryFlow,
          imageIcon: Theme.shared.image.transportPinLetter,
          imageSize: CGSize(width: 150, height: 200),
          quickPinSize: 5
        ),
        onPinEntered: PinCallbackWrapper(onEntered: { [weak self] pin in
          Task { @MainActor in
            guard let self else { return }
            self.issuanceVarificationInteractor.setDelegate(self)
            self.setState { $0.copy(isLoading: true) }
            self.issuanceVarificationInteractor.setPin(pin)
            self.router.pop()
          }
        }),
        issuanceVerificationInteractor: nil
      )
    )
  }
  
  func getEidPinRetryRoute() -> AppRoute {
    AppRoute.featureIssuanceModule(
      .pinView(
        config: UIConfig.Biometry(
          navigationTitle: .issuanceEidPinEntryTitle,
          caption: .pidCardPinEntrySecButton,
          quickPinOnlyCaption: .space,
          navigationSuccessType: .pop,
          navigationBackType: .pop,
          isPreAuthorization: true,
          shouldInitializeBiometricOnCreate: true,
          invalidPinTitle: .issuanceErrorWrongCan,
          pinScreenType: .eidPinRetryFlow,
          progressSteps: .init(current: 2, total: 4),
          imageIcon: nil
        ),
        onPinEntered: PinCallbackWrapper(onEntered: { [weak self] pin in
          Task { @MainActor in
            guard let self else { return }
            self.enteredPin = pin
            self.startAusweisReadFlow()
            self.router.popTo(with: .featureIssuanceModule(.issuanceCard(config: NoConfig(), requestURI: "", eidPin: "", delegate: self)))
          }
        }),
        issuanceVerificationInteractor: issuanceVarificationInteractor
      )
    )
  }

  private func getInvalidPinRoute() -> AppRoute {
    let errorConfig = UIConfig.InvalidPin(title: .invalidQuickPin, navigationSuccessType: .push(getEidPinRetryRoute()), navigationCancelType: .popTo(.featureIssuanceModule(.issuanceAddDocument(config: NoConfig()))), primaryButtonTitle: .tryAgain)
    return AppRoute.featureCommonModule(.errorView(config: errorConfig))
  }
  
  private func doNavigation(navigationType: UIConfig.ThreeWayNavigationType) {
    switch navigationType {
    case .popTo(let route):
      router.popTo(with: route)
    case .push(let route):
      router.push(with: route)
    case .pop:
      router.pop()
    }
  }
  
  public func setNewPin() {
    router.push(with:
        .featureIssuanceCardModule(
            .setNewEidInstructionsPinView(
                config: NoConfig(),
                issuanceVerificationInteractor: issuanceVarificationInteractor,
                pinCallbackWrapper: PinCallbackWrapper(onEntered: { newPin in
                  Task { @MainActor in
                     self.issuanceVarificationInteractor.assignNewPin(newPin)
                     self.router.popTo(with: .featureIssuanceModule(.issuanceCard(config: NoConfig(), requestURI: "", eidPin: "", delegate: self)))
                    }
                }),
                pinScreenType: .setupNewEidPinFlow
            )
        )
    )
  }
  
  func onChangePinCompleted(success: Bool) {
  }
}
