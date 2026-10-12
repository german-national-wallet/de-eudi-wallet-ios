//
//  SetupSuccessViewModel.swift
//  feature-startup
//

import Foundation
import logic_ui

final class SetupSuccessViewModel<Router: RouterHost>: ViewModel<Router, SetupSuccessState> {

  private let interactor: StartupInteractor
  private let continueRoute: AppRoute
  private var hasCompleted = false

  init(router: Router, config: any UIConfigType, interactor: StartupInteractor) {
    guard let config = config as? SetupSuccessUiConfig else {
      fatalError("Config error :: config must be of type SetupSuccessUiConfig")
    }
    self.interactor = interactor
    self.continueRoute = config.continueRoute
    super.init(router: router, initialState: SetupSuccessState())
  }

  func onAnimationFinished() {
    guard !hasCompleted else { return }
    hasCompleted = true
    interactor.markAppSetupCompleted()
    router.push(with: continueRoute)
  }
}
