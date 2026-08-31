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
    Task {
      do {
        self.setState({$0.copy(isLoading: true)})
        try await parInteractor.removePendingDocs(of: viewState.requestURI)
        let pendingDoc = try await parInteractor.issuePAR()
        guard let parURI = pendingDoc.authorizePresentationUrl else { return }
        self.setState({$0.copy(requestURI: parURI)})
        self.startAusweisReadFlow()
        self.setState({$0.copy(isLoading: false)})
      } catch {
        self.isErrorPopupVisible = true
        errorPopupViewModel.configure(
          backendError: (error as? BackendError) ?? .unknown,
          analyticsTraceId: analyticsController.currentTraceID ?? ""
        ) {
          self.isErrorPopupVisible = false
          self.router.pop()
        }
        self.setState({$0.copy(isLoading: false)})
      }
    }
  }
  
  func canEnteredCorrectly() {}
  
  func didSuccess(result: String) {
    Task {
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
        } catch {
          self.setState({$0.copy(isLoading: false)})
          logger?.e(error.logDescriptor)
        }
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
    self.router.popTo(with: .featureIssuanceCardModule(.issuanceAddDocument(config: NoConfig())))
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
      onClose: self.closeButtonTapped,
      onHelp: walletPinSetupHelpTapped
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
      showsHelpButton: true,
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
    doNavigation(navigationType: .push(getInvalidPinRoute()))
  }
  
  private func getInvalidPinRoute() -> AppRoute {
    let pinView = AppRoute.featureIssuanceModule(.pinView(config: NoConfig(), onPinEntered: PinCallbackWrapper(onEntered: { _ in }), issuanceVerificationInteractor: issuanceVarificationInteractor))
    
    let errorConfig = UIConfig.InvalidPin(title: .invalidQuickPin, navigationSuccessType: .popTo(pinView), navigationCancelType: .popTo(.featureIssuanceModule(.issuanceAddDocument(config: NoConfig()))), primaryButtonTitle: .tryAgain)
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
