//
//  PINViewModel.swift
//  feature-presentation
//
@_exported import logic_ui
@_exported import logic_resources
import logic_api
import logic_core

@Copyable
public struct PINViewState: ViewState {
  let config: UIConfig.Biometry
  var isLoading: Bool = false
}

public final class PINViewModel<Router: RouterHost>: ViewModel<Router, PINViewState> {
  @Published var isSheetPresented: Bool = false
  @Published var pin: [String] = []
  @Published var isInvalidPin = false
  @Published var errorMessage = String()
  @Published var canFocus = true
  
  public var onPinEntered: PinCallbackWrapper?
  var issuanceVarificationInteractor: IssuanceVerificationInteractor?
  var interactor: BiometryInteractor
  let parInteractor: PARInteractor
  let prefsController: PrefsController
  let secureEnclaveController: SecureEnclaveController
  let pinSessionInteractor: PinSessionInteractor
  let logger: Logging?

  public init(
    router: Router,
    interactor: BiometryInteractor,
    issuanceVarificationInteractor: IssuanceVerificationInteractor?,
    prefsController: PrefsController,
    secureEnclaveController: SecureEnclaveController,
    parInteractor: PARInteractor,
    config: any UIConfigType,
    throttlePinInput: Bool = true,
    onPinEntered: PinCallbackWrapper?,
    pinSessionInteractor: PinSessionInteractor,
    logger: Logging?
  ) {
    self.onPinEntered = onPinEntered
    self.interactor = interactor
    guard let config = config as? UIConfig.Biometry else {
      fatalError("BiometryViewModel:: Invalid configuraton")
    }
    self.interactor = interactor
    self.issuanceVarificationInteractor = issuanceVarificationInteractor
    self.prefsController = prefsController
    self.secureEnclaveController = secureEnclaveController
    self.parInteractor = parInteractor
    self.pinSessionInteractor = pinSessionInteractor
    self.logger = logger

    super.init(
      router: router,
      initialState: .init(
        config: config
      ))
    self.issuanceVarificationInteractor?.delegate = self
  }

  var pinString: String {
      pin.joined()
  }

  func handleInput(_ digit: String) {
    guard pin.count < viewState.config.quickPinSize, digit.rangeOfCharacter(from: .decimalDigits) != nil else { return }
      pin.append(digit)
  }

  func handleBackspace() {
      guard !pin.isEmpty else { return }
      pin.removeLast()
  }

  func onViewAppeared() {
    pin.removeAll()
    isInvalidPin = false
    canFocus = true
  }
  
  func doWork() async {
    guard let invalidPINResponse = prefsController.getObject(forKey: .invalidPinResponse, as: InvalidPasswordResponse.self) else {
      return
    }
    prefsController.remove(forKey: .invalidPinResponse)
    
    if invalidPINResponse.tryAllowedAfter?.isInFuture() != true {
      errorMessage = LocalizableStringKey.walletPinWrongEntry.toString
    }
  }
  
  func onSendData() async {
   errorMessage = ""
      switch viewState.config.pinScreenType {
      case .eidCanFlow: eidCanFlow()
      case .verifyWalletPinFlow: verifyWalletPinFlow()
      case .issueEidPinFlow: issueEidPinFlow()
      case .transportPinFlow: transportPinFlow()
      case .setupNewEidPinFlow: setupNewEidPinFlow()
      case .confirmNewEIDPinFlow: confirmNewEIDPinFlow()
      case .setupWalletPinflow: setupWalletPinFlow()
      case .confirmNewWalletPinFlow: await confirmNewWalletPinFlow()
      case .eidPinAfterCanFlow: eidPinAfterCanFlow()
      }
    setState { $0.copy(isLoading: false) }
  }

  public func toTheCan() {
    router.push(
      with: .featureIssuanceModule(
        .pinView(config: UIConfig.Biometry(
          navigationTitle: .issuanceCanEntryTitle,
          caption: .canInfoTitle,
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
                 onPinEntered: onPinEntered,
                 issuanceVerificationInteractor: issuanceVarificationInteractor
        )
     )
    )
  }
  
  func onCanCorrect() {
      let config = UIConfig.Success(
        title: UIConfig.Success.Title(value: .canCorrect),
        description: .canCorrectDescription,
        buttons: [],
        visualKind: .defaultIcon,
        nextRoute: .pop,
        viewType: .canCorrect
      )
    self.router.push(with:
        .featureIssuanceCardModule(
          .issuanceSuccessView(
            config: config,
            callback: { @MainActor in
              self.router.push(
                with: .featureIssuanceModule(
                  .pinView(
                    config: UIConfig.Biometry(
                      navigationTitle: .issuanceEidPinEntryTitle,
                      caption: nil,
                      primaryButtonTitle: .canCorrectPrimButton,
                      quickPinOnlyCaption: .space,
                      navigationSuccessType: .pop,
                      navigationErrorScreen: .push(self.getErrorRoute()),
                      navigationBackType: .pop,
                      isPreAuthorization: false,
                      shouldInitializeBiometricOnCreate: true,
                      invalidPinTitle: .invalidQuickPin,
                      pinScreenType: .eidPinAfterCanFlow,
                      imageIcon: Theme.shared.image.personalausweisLogo,
                      imageSize: CGSize(width: 105.0089, height: 144.0464),
                      quickPinSize: 6
                    ),
                    onPinEntered: self.onPinEntered,
                    issuanceVerificationInteractor: self.issuanceVarificationInteractor
                  )
                )
              )
            })))
  }

  public func doNavigation(navigationType: UIConfig.ThreeWayNavigationType) {
    switch navigationType {
    case .popTo(let route):
      router.popTo(with: route)
    case .push(let route):
      router.push(with: route)
    case .pop:
      router.pop()
    }
  }
  
  public func openBurgeramtWebpage() {
    if let url = AppEnvironment.burgeramtServiceLink {
      UIApplication.shared.open(url)
    }
  }
  
  public func handleCloseButton() {
    switch viewState.config.pinScreenType {
      case .issueEidPinFlow:
        router.popTo(with: .featureDashboardModule(.dashboard))
      
      default:
        self.closeButtonTapped()
    }
  }
}
