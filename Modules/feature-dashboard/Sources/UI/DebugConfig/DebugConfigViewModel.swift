//
//  DebugConfigViewModel.swift
//  feature-dashboard
//

import logic_business
import logic_ui

@Copyable
struct DebugConfigViewState: ViewState {
  let defaults: DebugConfigDefaults
  let pendingAction: DebugConfigAction?
  let isConfirmationVisible: Bool
}

enum DebugConfigAction: Sendable {
  case update
  case reset
}

final class DebugConfigViewModel<Router: RouterHost>: ViewModel<Router, DebugConfigViewState> {

  @Published var walletHostURL: String
  @Published var walletAPIKey: String
  @Published var otlpHostURL: String
  @Published var otlpAuthToken: String
  @Published var pidProviderURL: String

  private let interactor: DebugConfigInteractor

  init(
    router: Router,
    interactor: DebugConfigInteractor
  ) {
    self.interactor = interactor

    let overrides = interactor.overrides
    self.walletHostURL = overrides.walletHostURL ?? ""
    self.walletAPIKey = overrides.walletAPIKey ?? ""
    self.otlpHostURL = overrides.otlpHostURL ?? ""
    self.otlpAuthToken = overrides.otlpAuthToken ?? ""
    self.pidProviderURL = overrides.pidProviderURL ?? ""

    super.init(
      router: router,
      initialState: .init(
        defaults: interactor.defaults,
        pendingAction: nil,
        isConfirmationVisible: false
      )
    )
  }

  func onUpdate() {
    setState {
      $0.copy(
        pendingAction: .update,
        isConfirmationVisible: true
      )
    }
  }

  func onReset() {
    walletHostURL = ""
    walletAPIKey = ""
    otlpHostURL = ""
    otlpAuthToken = ""
    pidProviderURL = ""
    guard interactor.overrides.hasOverrides else {
      return
    }
    setState {
      $0.copy(
        pendingAction: .reset,
        isConfirmationVisible: true
      )
    }
  }

  func cancelPendingAction() {
    setState {
      $0.copy(isConfirmationVisible: false)
    }
  }

  func confirmPendingAction(wipeData: Bool) {
    guard let pendingAction = viewState.pendingAction else {
      return
    }
    Task {
      switch pendingAction {
      case .update:
        await interactor.apply(
          .init(
            walletHostURL: walletHostURL,
            walletAPIKey: walletAPIKey,
            otlpHostURL: otlpHostURL,
            otlpAuthToken: otlpAuthToken,
            pidProviderURL: pidProviderURL
          ),
          wipingData: wipeData
        )
      case .reset:
        await interactor.reset(wipingData: wipeData)
      }
    }
  }

  func onPop() {
    router.pop()
  }
}
