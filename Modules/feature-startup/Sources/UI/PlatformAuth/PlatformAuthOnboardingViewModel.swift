//
//  PlatformAuthOnboardingViewModel.swift
//  feature-startup
//

import Foundation
import logic_ui

final class PlatformAuthOnboardingViewModel<Router: RouterHost>: ViewModel<Router, PlatformAuthOnboardingState> {

  private let interactor: StartupInteractor
  private let continueRoute: AppRoute

  init(router: Router, config: any UIConfigType, interactor: StartupInteractor) {
    guard let config = config as? PlatformAuthOnboardingUiConfig else {
      fatalError("Config error :: config must be of type PlatformAuthOnboardingUiConfig")
    }
    self.interactor = interactor
    self.continueRoute = config.continueRoute
    super.init(
      router: router,
      initialState: .init(
        isChecking: true,
        isPlatformAuthEnabled: false,
        isImportantSheetPresented: false
      )
    )
  }

  func checkPlatformAuthentication() async {
    let isEnabled = await interactor.isPlatformAuthenticationEnabled()
    setState { $0.copy(isChecking: false, isPlatformAuthEnabled: isEnabled) }
  }

  func onPrimaryButtonTapped() {
    guard !viewState.isChecking else { return }
    setState { $0.copy(isImportantSheetPresented: true) }
  }

  func setImportantSheetPresented(_ isPresented: Bool) {
    setState { $0.copy(isImportantSheetPresented: isPresented) }
  }

  func onImportantSheetConfirmed() {
    setState { $0.copy(isImportantSheetPresented: false) }
    interactor.markPlatformAuthIntroSeen()
    router.push(with: continueRoute)
  }

  func onBackTapped() {
    router.pop()
  }
}
