//
//  PrivacyPolicyOnboardingViewModel.swift
//  feature-startup
//

import Foundation
import logic_ui
import logic_core

final class PrivacyPolicyOnboardingViewModel<Router: RouterHost>: ViewModel<Router, PrivacyPolicyOnboardingState> {

  private let interactor: StartupInteractor
  private let continueRoute: AppRoute

  let privacyPolicyURL: URL?

  init(
    router: Router,
    config: any UIConfigType,
    interactor: StartupInteractor,
    privacyPolicyURL: URL? = AppEnvironment.privacyPolicyLink
  ) {
    guard let config = config as? PrivacyPolicyOnboardingUiConfig else {
      fatalError("Config error :: config must be of type PrivacyPolicyOnboardingUiConfig")
    }
    self.interactor = interactor
    self.continueRoute = config.continueRoute
    self.privacyPolicyURL = privacyPolicyURL
    super.init(
      router: router,
      initialState: .init(hasAgreed: false, isPolicyPresented: false, presentedURL: nil)
    )
  }

  func toggleAgreement() {
    setState { $0.copy(hasAgreed: !$0.hasAgreed) }
  }

  func onReadPolicyTapped() {
    guard let privacyPolicyURL else { return }
    setState { $0.copy(isPolicyPresented: true, presentedURL: privacyPolicyURL) }
  }

  func onLinkTapped(_ url: URL) {
    guard let webURL = Self.webURL(from: url) else { return }
    setState { $0.copy(isPolicyPresented: true, presentedURL: webURL) }
  }

  static func webURL(from url: URL) -> URL? {
    if let scheme = url.scheme, scheme.hasPrefix("http") {
      return url
    }
    return URL(string: "https://" + url.absoluteString)
  }

  func setPolicyPresented(_ isPresented: Bool) {
    setState { $0.copy(isPolicyPresented: isPresented) }
  }

  func onPrimaryButtonTapped() {
    guard viewState.hasAgreed else { return }
    interactor.markPrivacyPolicyAccepted()
    router.push(with: continueRoute)
  }

  func onBackTapped() {
    router.pop()
  }
}
