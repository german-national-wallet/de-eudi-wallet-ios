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
import logic_api
import logic_analytics

final class PresentationLoadingViewModel<Router: RouterHost, RequestItem: Sendable>: BaseLoadingViewModel<Router, RequestItem> {

  private let interactor: PresentationInteractor
  private var publisherTask: Task<Void, Error>?
  private let prefsController: PrefsController
  private let analyticsController: AnalyticsController
  private let pinSessionInteractor: PinSessionInteractor
  private let logger: Logging?

  private let items: [RequestDataUiModel]?
  @Published var showWebView = false
  @Published var isErrorPopupVisible = false
  var url: URL?
  var errorPopupViewModel = ConfirmationPopupViewModel()
  
  init(
    router: Router,
    interactor: PresentationInteractor,
    relyingParty: String,
    relyingPartyIsTrusted: Bool,
    originator: AppRoute,
    requestItems: [ListItemSection<RequestItem>],
    prefsController: PrefsController,
    analyticsController: AnalyticsController,
    pinSessionInteractor: PinSessionInteractor,
    items: [RequestDataUiModel]?,
    logger: Logging?
  ) {
    self.interactor = interactor
    self.prefsController = prefsController
    self.analyticsController = analyticsController
    self.pinSessionInteractor = pinSessionInteractor
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
  }

  func subscribeToCoordinatorPublisher() async {
    switch self.interactor.getSessionStatePublisher() {
    case .success(let publisher):
      for try await state in publisher {
        switch state {
        case .error(let error):
          self.onError(with: error)
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
      self.onError(with: error)
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

      let analyticsTraceID = analyticsController.endTrace(
        finalAttributes: [AnalyticsConstants.TraceAttribute.status: AnalyticsConstants.TraceStatus.failure],
        errorDescription: String(describing: error)
      ) ?? ""
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
      }
      if let presentationError = error as? PresentationSessionError {
        switch presentationError {
        case .invalidState:
          logger?.e("invalidState:: presentation session expired")
        default:
          logger?.e("PresentationSessionError")
        }
      } else if let backendError = error as? BackendError {
        logger?.e("presentation failed: code=\(backendError.errorCode) traceId=\(backendError.traceId) detail=\(backendError.serverDescription)")
        errorPopupViewModel.configure(backendError: backendError, analyticsTraceId: analyticsTraceID) {
          self.router.pop()
        }
        isErrorPopupVisible = true
      } else {
        logger?.d("error:: (\(error.localizedDescription))")
        errorPopupViewModel.configureDefaultError(traceId: analyticsTraceID) {
          self.router.pop()
        }
        isErrorPopupVisible = true
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
}
