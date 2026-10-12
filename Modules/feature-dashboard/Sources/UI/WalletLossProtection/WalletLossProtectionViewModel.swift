//
//  WalletLossProtectionViewModel.swift
//  feature-dashboard
//
//  Created by Ameen Qadri on 29.09.26.
//

import Foundation
import UIKit
import logic_ui

@Copyable
struct WalletLossProtectionState: ViewState {
  let revocationCode: String?
  let isCodeCopied: Bool
}

final class WalletLossProtectionViewModel<Router: RouterHost>: ViewModel<Router, WalletLossProtectionState> {

  private let copiedStateDuration: TimeInterval = 2.0

  init(router: Router, interactor: SettingsTabInteractor) {
    super.init(
      router: router,
      initialState: .init(
        revocationCode: interactor.retrieveRevocationCode(),
        isCodeCopied: false
      )
    )
  }

  func copyCode() {
    guard let revocationCode = viewState.revocationCode else { return }
    UIPasteboard.general.string = revocationCode
    setState { $0.copy(isCodeCopied: true) }

    DispatchQueue.main.asyncAfter(deadline: .now() + copiedStateDuration) { [weak self] in
      self?.setState { $0.copy(isCodeCopied: false) }
    }
  }
}
