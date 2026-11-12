//
//  PresentationRequestBaseViewModel.swift
//  feature-presentation
//

import Foundation
import feature_common
import logic_analytics
import logic_core
import logic_ui

class PresentationRequestBaseViewModel<Router: RouterHost>: BaseRequestViewModel<Router> {

  @Published var errorDialog: PresentationErrorDialogConfig?
  @Published var isNoInternetDialogPresented = false
  private var noInternetRetry: PresentationErrorDialogConfig.RetryAction?

  let interactor: PresentationInteractor
  let pinSessionInteractor: PinSessionInteractor?
  let analyticsController: AnalyticsController
  let errorHandler: PresentationErrorHandler

  init(
    router: Router,
    interactor: PresentationInteractor,
    pinSessionInteractor: PinSessionInteractor?,
    analyticsController: AnalyticsController,
    errorHandler: PresentationErrorHandler,
    originator: AppRoute
  ) {
    self.interactor = interactor
    self.pinSessionInteractor = pinSessionInteractor
    self.analyticsController = analyticsController
    self.errorHandler = errorHandler
    super.init(router: router, originator: originator)
  }

  func getPinRoute() -> AppRoute? {
    nil
  }

  override func onShare() {
    Task {
      let items = self.viewState.items
      let documentIDs = items.map(\.section.id)
      let isPIDRequest = interactor.isPIDPresentation(documentIDs: documentIDs)

      let result = await Task.detached { () -> Result<RequestItemConvertible, Error> in
        return await self.interactor.onResponsePrepare(requestItems: items)
      }.value

      switch result {
      case .success:
        if let route = isPIDRequest ? self.getPinRoute() : self.getSuccessRoute() {
          self.router.push(with: route)
        } else {
          self.router.popTo(
            with: self.getPopRoute() ?? .featureDashboardModule(.dashboard)
          )
        }
      case .failure(let error):
        if isPIDRequest {
          pinSessionInteractor?.clear()
        }
        self.presentError(
          self.errorHandler.handle(error, originator: self.getOriginator(), retryAction: .init { [weak self] in
            self?.onShare()
          })
        )
      }
    }
  }

  func onErrorDialogAction(_ action: PresentationErrorDialogConfig.Action) {
    errorDialog = nil
    switch action {
    case .popTo(let route):
      router.popTo(with: route)
    case .addDigitalIDAgain:
      router.popTo(with: getOriginator())
    case .dismiss:
      onErrorDialogDismiss()
    case .openExternal(let url):
      UIApplication.shared.open(url)
      router.popTo(with: getOriginator())
    }
  }

  func onErrorDialogDismiss() {}

  func onNoInternetRetry() {
    let retry = noInternetRetry
    noInternetRetry = nil
    retry?.action()
  }

  func onNoInternetCancel() {
    noInternetRetry = nil
    router.pop()
  }

  func presentError(_ presentation: PresentationErrorPresentation) {
    switch presentation {
    case .notice(let config):
      router.push(with: .featurePresentationModule(.presentationErrorNotice(config: config)))
    case .dialog(let config):
      errorDialog = config
    case .noInternet(let retry):
      noInternetRetry = retry
      isNoInternetDialogPresented = true
    }
  }
}
