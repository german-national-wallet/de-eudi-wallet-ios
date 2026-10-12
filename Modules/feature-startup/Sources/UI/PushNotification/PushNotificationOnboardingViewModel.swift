//
//  PushNotificationOnboardingViewModel.swift
//  feature-startup
//

import Foundation
import logic_ui

final class PushNotificationOnboardingViewModel<Router: RouterHost>: ViewModel<Router, PushNotificationOnboardingState> {

  private let interactor: StartupInteractor
  private let continueRoute: AppRoute

  init(router: Router, config: any UIConfigType, interactor: StartupInteractor) {
    guard let config = config as? PushNotificationOnboardingUiConfig else {
      fatalError("Config error :: config must be of type PushNotificationOnboardingUiConfig")
    }
    self.interactor = interactor
    self.continueRoute = config.continueRoute
    super.init(
      router: router,
      initialState: .init(isRequestingAuthorization: false)
    )
  }

  func onEnableNotificationsTapped() async {
    guard !viewState.isRequestingAuthorization else { return }
    setState { $0.copy(isRequestingAuthorization: true) }
    _ = await interactor.requestPushAuthorization()
    setState { $0.copy(isRequestingAuthorization: false) }
    complete()
  }

  func onLaterTapped() {
    guard !viewState.isRequestingAuthorization else { return }
    complete()
  }

  func onBackTapped() {
    router.pop()
  }

  private func complete() {
    interactor.markPushIntroSeen()
    router.push(with: continueRoute)
  }
}
