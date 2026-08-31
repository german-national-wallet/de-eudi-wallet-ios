//
//  IssuanceLoadingViewModel.swift
//  feature-issuance
//

import feature_common
import logic_core
import logic_api
import logic_analytics
import logic_business

@Copyable
public struct IssuanceLoadingViewState: ViewState {
  let config: UIConfig.IssuanceLoadingUiConfig
}

final class IssuanceLoadingViewModel<Router: RouterHost>: ViewModel<Router, IssuanceLoadingViewState> {
  private let secureEnclaveController: SecureEnclaveController
  private var addDocumentInteractor: AddDocumentInteractor
  private let analyticsController: AnalyticsController
  private let mdvmInteractor: MDVMInteractor
  private let rwscaInteractor: RWSCAInteractor
  private let pinSessionInteractor: PinSessionInteractor
  private let logger: Logging?

  @Published var isErrorPopupVisible = false

  let errorPopupViewModel = ConfirmationPopupViewModel()
  
  init(
    router: Router,
    config: any UIConfigType,
    secureEnclaveController: SecureEnclaveController,
    addDocumentInteractor: AddDocumentInteractor,
    analyticsController: AnalyticsController,
    mdvmInteractor: MDVMInteractor,
    rwscaInteractor: RWSCAInteractor,
    pinSessionInteractor: PinSessionInteractor,
    logger: Logging?
  ) {
    self.secureEnclaveController = secureEnclaveController
    self.addDocumentInteractor = addDocumentInteractor
    self.analyticsController = analyticsController
    self.mdvmInteractor = mdvmInteractor
    self.rwscaInteractor = rwscaInteractor
    self.pinSessionInteractor = pinSessionInteractor
    self.logger = logger

    guard let config = config as? UIConfig.IssuanceLoadingUiConfig else {
      fatalError("Invalid config type")
    }
    super.init(router: router, initialState: .init(config: config))
  }
  
  func configureErrorPopupViewModel(error: BackendError, fallbackTraceID: String = "") {
    errorPopupViewModel.configure(backendError: error, analyticsTraceId: fallbackTraceID) {
      self.isErrorPopupVisible = false
      self.closeButtonTapped()
    }
  }

  func issueCredentials() async {
    do {
      guard let privateKey = secureEnclaveController.createPrivateKey(with: .credentialPrivKey),
            secureEnclaveController.storePrivateKey(privateKey, with: .credentialPrivKey) else {
        pinSessionInteractor.clear()
        analyticsController.endTrace(
          finalAttributes: [:],
          errorDescription: "Failed to create or store the credential private key"
        )
        return
      }
      let credentialsIssued = try await addDocumentInteractor.getCredentials(
        docTypeIdentifier: [.mDocPid, .sdJwtPid],
        viewState.config.finishAuthorizationResponse,
        privateKey: privateKey,
      )
      pinSessionInteractor.clear()

      if credentialsIssued {
        analyticsController.endTrace(finalAttributes: [:], errorDescription: nil)
        let config = UIConfig.Success(title: UIConfig.Success.Title(value: .pidIssuanceWalletPinReenterSucces), buttons: [], visualKind: .defaultIcon)
        self.router.push(with: .featureIssuanceCardModule(.issuanceSuccessView(config: config)))
      } else {
        logger?.e("Wallet registration failed: no credentials were issued")
        analyticsController.endTrace(
          finalAttributes: [:],
          errorDescription: "No credentials were issued"
        )
      }
    } catch let error as RWSCARepositoryError {
      logger?.e("Wallet registration failed (RWSCARepositoryError): \(error)")
      pinSessionInteractor.clear()

      var errorAttributes: [String: String] = [:]
      if case let .serverError(code, _, trace) = error {
        errorAttributes[AnalyticsConstants.TraceAttribute.errorCode] = code
        if !trace.isEmpty { errorAttributes[AnalyticsConstants.TraceAttribute.serverTraceID] = trace }
      }
      let analyticsTraceID = analyticsController.endTrace(
        finalAttributes: errorAttributes,
        errorDescription: String(describing: error)
      ) ?? ""
      isErrorPopupVisible = true
      configureErrorPopupViewModel(error: error, fallbackTraceID: analyticsTraceID)
    } catch let error {
      logger?.e("Wallet registration failed (unexpected): \(error)")
      pinSessionInteractor.clear()
      let analyticsTraceID = analyticsController.endTrace(
        finalAttributes: [:],
        errorDescription: String(describing: error)
      ) ?? ""
      isErrorPopupVisible = true
      configureErrorPopupViewModel(error: .unknown, fallbackTraceID: analyticsTraceID)
    }
  }
}
