//
//  PresentationErrorNoticeViewModel.swift
//  feature-presentation
//

import Foundation
import logic_ui
import logic_resources

@Copyable
struct PresentationErrorNoticeViewState: ViewState {
  let config: PresentationErrorNoticeConfig
}

final class PresentationErrorNoticeViewModel<Router: RouterHost>: ViewModel<Router, PresentationErrorNoticeViewState> {

  init(router: Router, config: any UIConfigType) {
    guard let config = config as? PresentationErrorNoticeConfig else {
      fatalError("Config error :: config must be of type PresentationErrorNoticeConfig")
    }
    super.init(router: router, initialState: .init(config: config))
  }

  func perform(_ action: PresentationErrorNoticeConfig.Action) {
    switch action {
    case .popTo(let route):
      router.popTo(with: route)
    case .reportSuspicion(let supervisoryAuthorityURL):
      guard let supervisoryAuthorityURL, UIApplication.shared.canOpenURL(supervisoryAuthorityURL) else {
        return
      }
      UIApplication.shared.open(supervisoryAuthorityURL)
    case .dismiss:
      router.popTo(with: viewState.config.originator)
    }
  }
}
