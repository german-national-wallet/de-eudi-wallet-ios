//
//  WalletRevocationSaveKeyViewModel.swift
//  feature-startup
//

import Foundation
import UIKit
import logic_ui

struct WalletRevocationSaveKeyUiConfig: UIConfigType {
  let revocationCode: String
  let continueRoute: AppRoute

  var log: String {
    "WalletRevocationSaveKeyUiConfig continueRoute: \(continueRoute.info.key)"
  }

  init(revocationCode: String, continueRoute: AppRoute) {
    self.revocationCode = revocationCode
    self.continueRoute = continueRoute
  }
}

@Copyable
struct WalletRevocationSaveKeyState: ViewState {
  let isSavedElsewhere: Bool
  let isCodeCopied: Bool
}

final class WalletRevocationSaveKeyViewModel<Router: RouterHost>: ViewModel<Router, WalletRevocationSaveKeyState> {

  private let revocationCode: String
  private let continueRoute: AppRoute
  private let interactor: StartupInteractor

  init(router: Router, config: any UIConfigType, interactor: StartupInteractor) {
    guard let config = config as? WalletRevocationSaveKeyUiConfig else {
      fatalError("Config error :: config must be of type WalletRevocationSaveKeyUiConfig")
    }
    self.revocationCode = config.revocationCode
    self.continueRoute = config.continueRoute
    self.interactor = interactor
    super.init(
      router: router,
      initialState: .init(isSavedElsewhere: false, isCodeCopied: false)
    )
  }

  /// Raw code, used for copy / share.
  var rawRevocationCode: String {
    revocationCode
  }

  /// Code split into groups of four characters for readable display.
  var formattedRevocationCode: String {
    let characters = Array(revocationCode)
    return stride(from: 0, to: characters.count, by: 4)
      .map { String(characters[$0..<min($0 + 4, characters.count)]) }
      .joined(separator: " ")
  }

  func setSavedElsewhere(_ isSaved: Bool) {
    setState { $0.copy(isSavedElsewhere: isSaved) }
  }

  func copyCode() {
    UIPasteboard.general.string = revocationCode
    setState { $0.copy(isCodeCopied: true) }

    // Reset the copied state after 2 seconds.
    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
      self?.setState { $0.copy(isCodeCopied: false) }
    }
  }

  func onPrimaryButtonTapped() {
    guard viewState.isSavedElsewhere else { return }
    interactor.markRevocationCodeSeen()
    router.push(with: continueRoute)
  }
}
