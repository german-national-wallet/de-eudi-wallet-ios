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
  private let connectivityMonitor: NetworkConnectivityMonitor
  private let logger: Logging?

  @Published var isErrorPopupVisible = false
  @Published var isIssued = false
  @Published var noInternetDialog = NoInternetDialogState()

  private var hasLeftSuccessState = false

  private let successStateTimeout: Duration = .seconds(5)

  private var successStateWatchdog: Task<Void, Never>?

  deinit {
    successStateWatchdog?.cancel()
  }

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
    connectivityMonitor: NetworkConnectivityMonitor,
    logger: Logging?
  ) {
    self.secureEnclaveController = secureEnclaveController
    self.addDocumentInteractor = addDocumentInteractor
    self.analyticsController = analyticsController
    self.mdvmInteractor = mdvmInteractor
    self.rwscaInteractor = rwscaInteractor
    self.pinSessionInteractor = pinSessionInteractor
    self.connectivityMonitor = connectivityMonitor
    self.logger = logger

    guard let config = config as? UIConfig.IssuanceLoadingUiConfig else {
      fatalError("Invalid config type")
    }
    super.init(router: router, initialState: .init(config: config))
  }

  func successAnimationFinished() {
    guard !hasLeftSuccessState else { return }
    hasLeftSuccessState = true
    successStateWatchdog?.cancel()
    router.popTo(with: .featureStartupModule(.startup))
  }

  private func startSuccessStateWatchdog() {
    successStateWatchdog = Task { [weak self, successStateTimeout] in
      try? await Task.sleep(for: successStateTimeout)
      guard !Task.isCancelled, let self, !self.hasLeftSuccessState else { return }
      self.logger?.d("IssuanceLoadingViewModel:: success animation never reported completion, continuing")
      self.successAnimationFinished()
    }
  }

  func configureErrorPopupViewModel(error: BackendError, fallbackTraceID: String = "") {
    errorPopupViewModel.configure(backendError: error, analyticsTraceId: fallbackTraceID) {
      self.isErrorPopupVisible = false
      self.cancelToDashboard()
    }
  }

  func configureErrorPopupViewModel(transportFailure: TransportFailure) {
    // No retry here <- the PIN session is gone
    errorPopupViewModel.configure(transportFailure: transportFailure) { [weak self] in
      self?.isErrorPopupVisible = false
      self?.cancelToDashboard()
    }
  }

  func configureIssuanceRestartPopupViewModel() {
    errorPopupViewModel.configureIssuanceRestart(
      startAgain: { [weak self] in
        self?.isErrorPopupVisible = false
        self?.router.restartIssuance()
      },
      cancel: { [weak self] in
        self?.isErrorPopupVisible = false
        self?.cancelToDashboard()
      }
    )
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
        self.isIssued = true
        self.startSuccessStateWatchdog()
      } else {
        logger?.e("Wallet registration failed: no credentials were issued")
        analyticsController.endTrace(
          finalAttributes: [:],
          errorDescription: "No credentials were issued"
        )
      }
    } catch where connectivityMonitor.isNoInternet(error) {
      logger?.e("Wallet registration failed: no internet")
      noInternetDialog.present(
        retry: { [weak self] in
          Task { await self?.issueCredentials() }
        },
        cancel: { [weak self] in
          self?.pinSessionInteractor.clear()
          self?.router.pop()
        }
      )
    } catch let error where TransportFailure.find(in: error) != nil {
      guard let failure = TransportFailure.find(in: error) else { return }
      logger?.e("Wallet registration failed (transport): \(failure)")
      pinSessionInteractor.clear()
      var errorAttributes: [String: String] = [:]
      if let statusCode = failure.statusCode {
        errorAttributes[AnalyticsConstants.TraceAttribute.errorCode] = String(statusCode)
      }
      analyticsController.endTrace(
        finalAttributes: errorAttributes,
        errorDescription: String(describing: failure)
      )
      isErrorPopupVisible = true
      configureErrorPopupViewModel(transportFailure: failure)
    } catch let error where error.isGrantRejection {
      logger?.e("Wallet registration failed: authorization grant rejected, PAR expired")
      pinSessionInteractor.clear()
      _ = analyticsController.endTrace(finalAttributes: [:], errorDescription: "PAR expired")
      isErrorPopupVisible = true
      configureIssuanceRestartPopupViewModel()
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
