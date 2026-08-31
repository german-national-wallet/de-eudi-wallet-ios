//
//  SuccessViewModel.swift
//  feature-issuance
//

import logic_ui
import feature_common

struct GenericSuccessState: ViewState {
  let config: UIConfig.Success
}

final class SuccessViewModel<Router: RouterHost>: ViewModel<Router, GenericSuccessState> {
  let callback: (() -> Void)?
  private let deepLinkController: DeepLinkController

  init(
    config: any UIConfigType,
    callback: (() -> Void)?,
    deepLinkController: DeepLinkController,
    router: Router
  ) {
    guard let config = config as? UIConfig.Success else {
      fatalError("SuccessViewModel:: Invalid configuraton")
    }
    self.callback = callback
    self.deepLinkController = deepLinkController
    super.init(router: router, initialState: .init(config: config))
  }
  
  private func doNavigation(navigationType: UIConfig.ThreeWayNavigationType) {
    switch navigationType {
    case .popTo(let route):
      router.popTo(with: route)
    case .push(let route):
      router.push(with: route)
    case .pop:
      router.pop()
    }
  }
  
  func navigateTo() {
    DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
      Task { await self?.deepLinkController.setDeeplinkFlowFlag(false) }
      guard let nextRoute = self?.viewState.config.nextRoute else {
        self?.router.popTo(with: .featureStartupModule(.startup))
        return
      }
      self?.doNavigation(navigationType: nextRoute)
    }
  }
  
  func primaryButtonPressed() {
    if let callback {
      callback()
    }
  }
  func secondaryButtonPressed() {}
  
}
