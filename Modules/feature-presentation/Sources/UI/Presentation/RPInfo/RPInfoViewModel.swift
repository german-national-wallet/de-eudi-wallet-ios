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
  @Published var isConfirmationPopupVisible = false
  
  let confirmationPopupViewModel = ConfirmationPopupViewModel()
  
  private let interactor: PresentationInteractor
  private let analyticsController: AnalyticsController
  private let logger: Logging?

  public init(
    router: Router,
    interactor: PresentationInteractor,
    originator: AppRoute,
    analyticsController: AnalyticsController,
    logger: Logging?
  ) {
    self.interactor = interactor
    self.analyticsController = analyticsController
    self.logger = logger
    super.init(router: router, originator: originator)
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
      self.onReceivedItems(
        with: authenticationRequest.requestDataCells,
        title: .requestDataTitle(
          [authenticationRequest.relyingParty]
        ),
        relyingParty: .custom(authenticationRequest.relyingParty),
        isTrusted: authenticationRequest.isTrusted
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
      logger?.d("error: \(error.logDescriptor)")

      let analyticsTraceID = analyticsController.endTrace(
        finalAttributes: [AnalyticsConstants.TraceAttribute.status: AnalyticsConstants.TraceStatus.failure],
        errorDescription: String(describing: error)
      ) ?? ""
      switch (error as? EudiWalletKit.WalletError)?.code {
      case .credentialNotFound, .noDocumentsAvailable:
        router.push(
          with: .featurePresentationModule(
            .credentialNotFoundInstructionsView(
              config: UIConfig.InstructionsViewConfig(
                mainTitle: .pidPresentationCredentialNotFoundTitle,
                message: .pidPresentationCredentialNotFoundParagraph,
                image: Theme.shared.image.credentialNotFound, 
                illustrationWidthFactor: 0.5,
                primaryButtonTitle: .pidPresentationCredentialNotFoundPrimButton,
                primaryRoute: .featureDashboardModule(.dashboard)
              )
            )
          )
        )
      default:
        confirmationPopupViewModel.configure(
          title: LocalizableStringKey.pidPresentationMalformedPresentationTitle.toString,
          detail: LocalizableStringKey.pidPresentationMalformedPresentationParagraph.toString,
          traceId: analyticsTraceID,
          titleIcon: Theme.shared.image.errorIndicator,
          primaryButtontitle: LocalizableStringKey.pidPresentationMalformedPresentationPrimButton.toString,
          primaryAction: {
            self.router.pop()
          },
          secondaryAction: nil
        )
        isConfirmationPopupVisible.toggle()
      }
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
    confirmationPopupViewModel.configure(
      title: LocalizableStringKey.confirmItendificationRefusal.toString,
      detail: LocalizableStringKey.confirmItendificationRefusalMessage.toString,
      primaryButtontitle: LocalizableStringKey.back.toString,
      secondaryButtontitle: LocalizableStringKey.yesReject.toString,
        primaryAction: {
          self.isConfirmationPopupVisible = false
        },
        secondaryAction: {
          self.analyticsController.endTrace(
            finalAttributes: [AnalyticsConstants.TraceAttribute.status: AnalyticsConstants.TraceStatus.declined],
            errorDescription: nil
          )
          self.router.pop()
          self.isConfirmationPopupVisible = false
        }
    )
    isConfirmationPopupVisible = true
  }
  
  func onViewDetails() {
    isRequestInfoModalShowing = true
  }
  
}
