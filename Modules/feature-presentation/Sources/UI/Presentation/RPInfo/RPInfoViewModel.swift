//
//  RPInfoViewModel.swift
//  feature-presentation
//

@_exported import logic_ui
@_exported import logic_resources
import feature_common
import logic_analytics
import logic_core

final class RPInfoViewModel<Router: RouterHost>: BaseRequestViewModel<Router> {
  @Published var isRequestInfoModalShowing: Bool = false
  @Published var isVerifiedEntityModalShowing: Bool = false
  @Published var itemsChanged: Bool = false
  @Published var viewDetail = false
  @Published var errorDialog: PresentationErrorDialogConfig?
  @Published var isConfirmationPopupVisible = false
  @Published var reportURL: URL?
    
  private let interactor: PresentationInteractor
  private let analyticsController: AnalyticsController
  private let errorHandler: PresentationErrorHandler
  private let logger: Logging?

  public init(
    router: Router,
    interactor: PresentationInteractor,
    originator: AppRoute,
    analyticsController: AnalyticsController,
    errorHandler: PresentationErrorHandler,
    logger: Logging?
  ) {
    self.interactor = interactor
    self.analyticsController = analyticsController
    self.errorHandler = errorHandler
    self.logger = logger
    super.init(router: router, originator: originator)
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
    self.onStartLoading()
    analyticsController.startTrace(name: AnalyticsConstants.TraceName.presentation, initialAttributes: [:])
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

      self.onReceivedItems(
        with: authenticationRequest.requestDataCells,
        title: .requestDataTitle(
          [authenticationRequest.relyingParty]
        ),
        relyingParty: .custom(authenticationRequest.relyingParty),
        isTrusted: authenticationRequest.isTrusted,
      )
      setState {
        $0.copy(
          contentHeaderConfig: .init(
            appIconAndTextData: AppIconAndTextData(
              appIcon: ThemeManager.shared.image.logoEuDigitalIndentityWallet,
              appText: ThemeManager.shared.image.euditext
            ),
            description: .dataSharingTitle,
            mainText: getTitle(),
            relyingPartyData: RelyingPartyData(
              isVerified: viewState.isTrusted,
              name: getRelyingParty(),
              description: getCaption()
            )
          )
        )
      }
    case .failure(let error):
      presentError(errorHandler.handle(error, originator: getOriginator()))
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
    Task { await self.interactor.onRejectRequest() }
    router.pop()
  }

  func reportSuspicion() {
    guard let reportURL else { return }
    UIApplication.shared.open(reportURL)
  }

  func onViewDetails() {
    isRequestInfoModalShowing = true
  }

  func onErrorDialogAction(_ action: PresentationErrorDialogConfig.Action) {
    errorDialog = nil
    switch action {
    case .popTo(let route):
      router.popTo(with: route)
    case .addDigitalIDAgain:
      router.popTo(with: getOriginator())
    case .dismiss:
      isConfirmationPopupVisible = false
    }
  }

  private func presentError(_ presentation: PresentationErrorPresentation) {
    setState { $0.copy(initialized: true) }
    switch presentation {
    case .notice(let config):
      router.push(with: .featurePresentationModule(.presentationErrorNotice(config: config)))
    case .dialog(let config):
      errorDialog = config
    }
  }
}
