//
//  RPInfoViewModel.swift
//  feature-presentation
//

@_exported import logic_ui
@_exported import logic_resources
import feature_common
import logic_analytics
import logic_core

final class RPInfoViewModel<Router: RouterHost>: PresentationRequestBaseViewModel<Router> {
  @Published var isRequestInfoModalShowing: Bool = false
  @Published var isVerifiedEntityModalShowing: Bool = false
  @Published var itemsChanged: Bool = false
  @Published var viewDetail = false
  @Published var isConfirmationPopupVisible = false
  @Published var reportURL: URL?
  @Published var purpose: String?
    
  private let logger: Logging?
  private let openURL: @MainActor (URL) -> Void

  public init(
    router: Router,
    interactor: PresentationInteractor,
    originator: AppRoute,
    analyticsController: AnalyticsController,
    errorHandler: PresentationErrorHandler,
    logger: Logging?,
    openURL: @escaping @MainActor (URL) -> Void = { UIApplication.shared.open($0) }
  ) {
    self.logger = logger
    self.openURL = openURL
    super.init(
      router: router,
      interactor: interactor,
      pinSessionInteractor: nil,
      analyticsController: analyticsController,
      errorHandler: errorHandler,
      originator: originator
    )
  }

  private func onRejectedByPolicy(reason: PresentationRejectedUiConfig.Reason, reportURI: URL? = nil) async {
    await onRefusedByPolicy(reason: reason, reportURI: reportURI) { [interactor] in
      if reason == .overAsking {
        await interactor.declinePresentation()
      }
      interactor.stopPresentation()
    }
  }

  override func doWork() async {
    analyticsController.startTrace(name: AnalyticsConstants.TraceName.presentation, initialAttributes: [:])
    await fetchRequest()
  }

  private func fetchRequest() async {
    purpose = nil
    self.onStartLoading()
    let result = await Task.detached { () -> Result<OnlineAuthenticationRequestSuccessModel, Error> in
      return await self.interactor.onDeviceEngagement()
    }.value

    switch result {
    case .success(let authenticationRequest):
      logger?.d("Relying Party is \(authenticationRequest.isTrusted ? "trusted": "not trusted")")
      reportURL = authenticationRequest.supervisoryAuthorityURI

      if await refuseIfBlockedByRegistration(authenticationRequest, interactor: interactor) {
        logger?.d("presentation refused: request not covered by the relying party's registration certificate")
        return
      }
      purpose = authenticationRequest.purpose
      self.onReceivedItems(
        with: authenticationRequest.requestDataCells,
        title: .requestDataTitle(
          [authenticationRequest.relyingParty]
        ),
        relyingParty: .custom(authenticationRequest.relyingParty),
        isTrusted: authenticationRequest.isTrusted,
      )
      self.onPresentationDoWorkSuccess()
    case .failure(let error):
      presentError(errorHandler.handle(error, originator: getOriginator(), retryAction: .init { [weak self] in
        Task { await self?.fetchRequest() }
      }))
    }
  }

  override func onShare() {
  }

  func onContinue() {
    switch interactor.getCoordinator() {
    case .success(let remoteSessionCoordinator):
      router.push(
        with: .featurePresentationModule(
          .presentationConsent(
            presentationCoordinator: remoteSessionCoordinator,
            originator: getOriginator(),
            relyingParty: self.viewState.relyingParty.toString
          )
        )
      )
    case .failure(let error):
      logger?.e("unable to get coordinator \(error)")
    }

  }

  func onDecline() {
    isConfirmationPopupVisible = true
  }

  func confirmDecline() {
    analyticsController.endTrace(
      finalAttributes: [AnalyticsConstants.TraceAttribute.status: AnalyticsConstants.TraceStatus.declined],
      errorDescription: nil
    )
    Task {
      if let redirectURL = await self.interactor.onRejectRequest() {
        self.openURL(redirectURL)
      }
    }
    router.pop()
  }

  func reportSuspicion() {
    guard let reportURL else { return }
    UIApplication.shared.open(reportURL)
  }

  func onViewDetails() {
    isRequestInfoModalShowing = true
  }

  override func onErrorDialogDismiss() {
    isConfirmationPopupVisible = false
  }

  override func onNoInternetCancel() {
    interactor.stopPresentation()
    super.onNoInternetCancel()
  }

  override func presentError(_ presentation: PresentationErrorPresentation) {
    setState { $0.copy(initialized: true) }
    super.presentError(presentation)
  }
}
