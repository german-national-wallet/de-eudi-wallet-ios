//
//  InvalidPINViewModel.swift
//  feature-common
//

import logic_ui
import logic_resources
import MdocDataModel18013
import logic_business
import logic_core

public struct InvalidPINViewState: ViewState {
  let config: UIConfig.InvalidPin
}

final class InvalidPINViewModel<Router: RouterHost>: ViewModel<Router, InvalidPINViewState> {
  @Published var showActionSheet: Bool = false
  
  public init(
    router: Router,
    config: any UIConfigType
  ) {
    guard let config = config as? UIConfig.InvalidPin else {
      fatalError("BiometryViewModel:: Invalid configuraton")
    }
    
    super.init(
      router: router,
      initialState: .init(config: config)
    )
  }
  
  public func onPrimaryActionButtonClicked() {
    doNavigation(navigationType: viewState.config.primaryActionNavigation)
  }
  
  public func onSecondaryActionButtonClicked() {
    showActionSheet = true
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
  
  public func onCancelButtonClicked() {
    if let onCancelCallback = viewState.config.navigationCancelType {
      doNavigation(navigationType: onCancelCallback)
    } else {
      router.popTo(with: .featureDashboardModule(.dashboard))
    }
  }
  
  public func openBurgeramtWebpage() {
    if let url = AppEnvironment.burgeramtServiceLink {
      UIApplication.shared.open(url)
    }
  }
}
