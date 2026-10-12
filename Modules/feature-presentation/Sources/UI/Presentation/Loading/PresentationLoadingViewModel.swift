/*
 * Copyright (c) 2023 European Commission
 *
 * Licensed under the EUPL, Version 1.2 or - as soon they will be approved by the European
 * Commission - subsequent versions of the EUPL (the "Licence"); You may not use this work
 * except in compliance with the Licence.
 *
 * You may obtain a copy of the Licence at:
 * https://joinup.ec.europa.eu/software/page/eupl
 *
 * Unless required by applicable law or agreed to in writing, software distributed under
 * the Licence is distributed on an "AS IS" basis, WITHOUT WARRANTIES OR CONDITIONS OF
 * ANY KIND, either express or implied. See the Licence for the specific language
 * governing permissions and limitations under the Licence.
 */

import feature_common
import logic_core
import logic_analytics
import logic_ui
import logic_api

final class PresentationLoadingViewModel<Router: RouterHost, RequestItem: Sendable>: BaseLoadingViewModel<Router, RequestItem> {

  private let interactor: PresentationInteractor
  private var pidRevokeInteractor: PIDRevokeInteractor
  private let deepLinkController: DeepLinkController
  private var publisherTask: Task<Void, Error>?
  private let prefsController: PrefsController
  private let analyticsController: AnalyticsController
  private let pinSessionInteractor: PinSessionInteractor
  private let errorHandler: PresentationErrorHandler
  private let logger: Logging?
  
  var confirmationPopupViewModel: ConfirmationPopupViewModel!
  private let items: [RequestDataUiModel]?
  private var hasPresentedError = false
  @Published var showWebView = false
  @Published var errorDialog: PresentationErrorDialogConfig?
  @Published var showPIDResetConfirmationPopup: Bool = false

  var url: URL?

  init(
    router: Router,
    interactor: PresentationInteractor,
    pidRevokeInteractor: PIDRevokeInteractor,
    deepLinkController: DeepLinkController,
    relyingParty: String,
    relyingPartyIsTrusted: Bool,
    originator: AppRoute,
    requestItems: [ListItemSection<RequestItem>],
    prefsController: PrefsController,
    analyticsController: AnalyticsController,
    pinSessionInteractor: PinSessionInteractor,
    errorHandler: PresentationErrorHandler,
    items: [RequestDataUiModel]?,
    logger: Logging?
  ) {
    self.interactor = interactor
    self.pidRevokeInteractor = pidRevokeInteractor
    self.deepLinkController = deepLinkController
    self.prefsController = prefsController
    self.analyticsController = analyticsController
    self.pinSessionInteractor = pinSessionInteractor
    self.errorHandler = errorHandler
    self.items = items
    self.logger = logger

    super.init(
      router: router,
      originator: originator,
      requestItems: requestItems,
      relyingParty: relyingParty,
      relyingPartyIsTrusted: relyingPartyIsTrusted,
      cancellationTimeout: 5
    )
    setupConfirmationPopup()
  }

  func subscribeToCoordinatorPublisher() async {
    switch self.interactor.getSessionStatePublisher() {
    case .success(let publisher):
      for try await state in publisher {
        switch state {
        case .error(let error):
          self.presentError(error)
        case .responseSent(let url):
          self.interactor.stopPresentation()
          if self.navigateToDynamicIssuanceOriginator(with: url) {
            return
          }
          let route = getOnSuccessRoute(with: url)
          if AppEnvironment.isUITesting {
            self.url = url
            self.showWebView = true
            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(10)) {
              self.onNavigate(type: .push(route))
            }
          } else {
            self.onNavigate(type: .push(route))
          }
        default:
          ()
        }
      }
    case .failure(let error):
      self.presentError(error)
    }
  }

  override func getTitle() -> LocalizableStringKey {
    .requestDataTitle([getRelyingParty()])
  }

  override func getCaption() -> LocalizableStringKey {
    .requestsTheFollowing
  }

  private func getOnSuccessRoute(with url: URL?) -> AppRoute {

    self.publisherTask?.cancel()

    var navigationType: UIConfig.DeepLinkNavigationType {
      guard let url else {
        return .pop(screen: getOriginator())
      }
      guard !isDynamicIssuance() else {
        interactor.storeDynamicIssuancePendingUrl(with: url)
        return .pop(screen: getOriginator())
      }
      if !AppEnvironment.isUITesting {
        UIApplication.shared.open(url)
      }
      return .deepLink(
        link: url,
        popToScreen: .featureDashboardModule(.dashboard)
      )
    }

    return .featurePresentationModule(
      .presentationSuccess(
        config: DocumentSuccessUIConfig(
          successNavigation: navigationType,
          relyingParty: getRelyingParty(),
          relyingPartyIsTrusted: isRelyingPartyIstrusted()
        ),
        getRequestItems()
      )
    )
  }

  private func navigateToDynamicIssuanceOriginator(with url: URL?) -> Bool {
    guard isDynamicIssuance() else {
      return false
    }
    if let url {
      interactor.storeDynamicIssuancePendingUrl(with: url)
    }
    publisherTask?.cancel()
    router.popTo(with: getOriginator())
    return true
  }

  private func isDynamicIssuance() -> Bool {
    guard
      getOriginator() == AppRoute.featureIssuanceModule(.credentialOfferRequest(config: NoConfig()))
        || getOriginator() == AppRoute.featureIssuanceModule(.issuanceAddDocument(config: NoConfig()))
        || getOriginator() == AppRoute.featureIssuanceModule(.issuanceCode(config: NoConfig()))
        || getOriginator() == AppRoute.featureIssuanceModule(.documentLoaderView(config: NoConfig()))
    else {
      return false
    }
    return true
  }

  override func getOnPopRoute() -> AppRoute? {
    self.publisherTask?.cancel()
    return switch interactor.getCoordinator() {
    case .success(let remoteSessionCoordinator):
        .featurePresentationModule(
          .presentationRequest(
            presentationCoordinator: remoteSessionCoordinator,
            originator: getOriginator()
          )
        )
    case .failure: nil
    }
  }

  override func doWork() async {
    if let items = items {
      await interactor.onResponsePrepare(requestItems: items)
    }
    startPublisherTask()

    let result = await Task.detached { () -> RemoteSentResponsePartialState in
      return await self.interactor.onSendResponse()
    }.value

    switch result {
    case .sent:
      clearPinSessionIfNeeded()
      analyticsController.endTrace(
        finalAttributes: [AnalyticsConstants.TraceAttribute.status: AnalyticsConstants.TraceStatus.success],
        errorDescription: nil
      )
      logger?.d("presentation is successful")
    case .failure(let error):
      publisherTask?.cancel()
      clearPinSessionIfNeeded()
      if let presentationError = error as? PresentationError {
        switch presentationError {
        case .invalidPassword(let response):
          logger?.d("invalidPassword")
          if let encoded = try? JSONEncoder().encode(response) {
            prefsController.setValue(encoded, forKey: .invalidPinResponse)
          }
          if response.isBlocked || response.tryAllowedAfter?.isInFuture() == true {
            router.push(with: .featurePresentationModule(.pinRetryCounterView(config: getInvalidPinRetryMessageConfig(response: response))))
          } else {
            router.pop()
          }
        }
      } else {
        presentError(error)
      }
    }
  }

  private func getInvalidPinRetryMessageConfig(response: InvalidPasswordResponse) -> UIConfig.InvalidPinRetryMessageConfig {
    UIConfig.InvalidPinRetryMessageConfig(
      mainTitle: .walletPinMultipleWrongEntry,
      retryMessage: .walletPinTryAgainIn,
      primaryButtonTitle: .walletPinForgotten,
      invalidPasswordResponse: response
    )
  }

  func onErrorDialogAction(_ action: PresentationErrorDialogConfig.Action) {
    errorDialog = nil
    switch action {
    case .popTo(let route):
      router.popTo(with: route)
    case .addDigitalIDAgain:
      showPIDResetConfirmationPopup = true
    case .dismiss:
      break
    }
  }

  private func presentError(_ error: Error) {
    guard !hasPresentedError else { return }
    hasPresentedError = true
    switch errorHandler.handle(error, originator: getOriginator()) {
    case .notice(let config):
      router.push(with: .featurePresentationModule(.presentationErrorNotice(config: config)))
    case .dialog(let config):
      errorDialog = config
    }
  }

  private func startPublisherTask() {
    if publisherTask == nil || publisherTask?.isCancelled == true {
      publisherTask = Task {
        await self.subscribeToCoordinatorPublisher()
      }
      Task {
        try? await self.publisherTask?.value
      }
    }
  }

  private func clearPinSessionIfNeeded() {
    let documentIDs = getRequestItems().map(\.id)
    guard interactor.isPIDPresentation(documentIDs: documentIDs) else {
      return
    }
    pinSessionInteractor.clear()
  }

  private func setupConfirmationPopup() {
    confirmationPopupViewModel = ConfirmationPopupViewModel()
    confirmationPopupViewModel.configure(
      title: LocalizableStringKey.pidPresentationRetryCounterResetOverlayTitle.toString,
      detail: LocalizableStringKey.pidPresentationRetryCounterResetOverlayParagraph.toString,
      titleIcon: Theme.shared.image.warningIndicator,
      confirmButtonBackgroundColor: DSColor.error,
      primaryButtontitle: LocalizableStringKey.pidPresentationRetryCounterResetOverlayButton.toString,
      secondaryButtontitle: LocalizableStringKey.pidPresentationDialogRpRejectionSecButton2.toString,
      primaryAction: {
        Task {
          await self.resetWallet()
        }
      },
      secondaryAction: { [weak self] in
        self?.cancelToDashboard()
      }
    )
  }

  func resetWallet() async {
    do {
      try await pidRevokeInteractor.deletePIDFromWallet()
    } catch {
      return
    }
    await deepLinkController.setDeeplinkFlowFlag(false)
    cancelToDashboard()
  }
}
