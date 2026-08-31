//
//  IssuanceCardViewModel.swift
//  feature-issuance
//

import logic_ui
import logic_resources
import feature_common
import logic_business
import JOSESwift
import MdocDataModel18013
import logic_api
import logic_analytics

@Copyable
struct IssuanceCardViewState: ViewState {
  let error: ContentErrorView.Config?
  let config: IssuanceFlowUiConfig
  var isLoading: Bool
  let eidPin: String
  let navigationTitle: LocalizableStringKey
  let eidFlow: EidFlowType
  let requestURI: String
  
  var isFlowCancellable: Bool {
    return config.isExtraDocumentFlow
  }
}

final class IssuanceCardViewModel<Router: RouterHost>: ViewModel<Router, IssuanceCardViewState> {
  private let secureEnclaveController: SecureEnclaveController
  private let quickPinInteractor: QuickPinInteractor
  private let delegate: IssuanceVerificationInteractorDelegate
  let analyticsController: AnalyticsController
  let logger: Logging?

  var errorPopupViewModel = ConfirmationPopupViewModel()
  var issuanceVarificationInteractor: IssuanceVerificationInteractor
  var interactor: IssuanceCardInteractor
  var parInteractor: PARInteractor
  var promptData = PromptData(
    title: "Lets get you started",
    description: "Press the NFC button to start"
  )
  
  @Published var enteredPin = String()
  @Published var enteredCan = String()
  @Published var showHelpAndTipsActionSheet: Bool = false
  @Published var isErrorPopupVisible = false
  
  var finishAuthorizationResponseDTO: FinishAuthorizationResponse?
  var credentialsFound = false
  var requestStartTime: Date?
  
  init(
    router: Router,
    interactor: IssuanceCardInteractor,
    parInteractor: PARInteractor,
    issuanceVarificationInteractor: IssuanceVerificationInteractor,
    secureEnclaveController: SecureEnclaveController,
    quickPinInteractor: QuickPinInteractor,
    analyticsController: AnalyticsController,
    config: any UIConfigType,
    requestURI: String,
    eidPin: String,
    eidFlow: EidFlowType = .authentication,
    delegate: IssuanceVerificationInteractorDelegate,
    logger: Logging?
  ) {
    guard
      let config = config as? IssuanceFlowUiConfig
    else {
      fatalError("OfferCodeViewModel:: Invalid configuration")
    }
    self.parInteractor = parInteractor
    self.interactor = interactor
    self.issuanceVarificationInteractor = issuanceVarificationInteractor
    self.secureEnclaveController = secureEnclaveController
    self.quickPinInteractor = quickPinInteractor
    self.delegate = delegate
    self.analyticsController = analyticsController
    self.logger = logger

    super.init(
      router: router,
      initialState: .init(
        error: nil,
        config: config,
        isLoading: false,
        eidPin: eidPin,
        navigationTitle: .issuanceScanningTitle,
        eidFlow: eidFlow,
        requestURI: requestURI
      )
    )
    enteredPin = eidPin
    issuanceVarificationInteractor.setDelegate(self)
  }
  
  func startAusweisReadFlow() {
    switch viewState.eidFlow {
      case .authentication:
        setState({$0.copy(isLoading: true)})
        startEidScanning()
      case .setEidPin:
        setState({$0.copy(isLoading: true)})
        startSetupEidFlow()
      case .confirmNewPin:
        break
    }
  }
  
  func startSetupEidFlow() {
    guard let requestURL = URL(string: viewState.requestURI) else {
      return
    }
    issuanceVarificationInteractor.setDelegate(self)
    issuanceVarificationInteractor.startChangePinFlow(tokenURL: requestURL, transportPin: enteredPin)
  }
  
  func viewHelpAndTips() {
    showHelpAndTipsActionSheet = true
  }

  func walletPinSetupHelpTapped() {
    // TODO: - Provide action here
  }
  
  func startEidScanning() {
    
    guard let requestURL = URL(string: viewState.requestURI) else {
      return
    }
    
    guard let finishAuthorizationResponseDTO else {
      issuanceVarificationInteractor.setDelegate(self)
      issuanceVarificationInteractor.start(tokenURL: requestURL, pin: enteredPin)
      return
    }
  }
  
  func onCANSubmission() {
    if !enteredCan.isEmpty {
      issuanceVarificationInteractor.setCAN(enteredCan)
    }
  }
  
  func onCancelPinSubmission() {
    closeButtonTapped()
  }
  
  func contactCustomerCareTapped() {
    if let url = URL(string: "tel://\(LocalizableStringKey.scanningCustomerServicePhoneNumber.toString)"),
       UIApplication.shared.canOpenURL(url) {
        UIApplication.shared.open(url)
    }
  }
}
