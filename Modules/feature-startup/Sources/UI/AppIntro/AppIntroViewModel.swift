//
//  AppIntroViewModel.swift
//  feature-startup
//

import Foundation
import logic_ui
import logic_resources

struct AppIntroUiConfig: UIConfigType {
  let page: AppIntroPage
  let continueRoute: AppRoute

  var log: String {
    "AppIntroUiConfig page: \(page.number) continueRoute: \(continueRoute.info.key)"
  }

  init(page: AppIntroPage = .digitalWallet, continueRoute: AppRoute) {
    self.page = page
    self.continueRoute = continueRoute
  }
}

@Copyable
struct AppIntroState: ViewState {
  let page: AppIntroPage
  let isAnimationPaused: Bool
  let isAnimationToggleVisible: Bool
}

final class AppIntroViewModel<Router: RouterHost>: ViewModel<Router, AppIntroState> {

  private let pausableAnimationMinimumDuration: TimeInterval = 5
  private let interactor: StartupInteractor
  private let continueRoute: AppRoute
  private let animationDurationLoader: (VideoAsset) async -> TimeInterval?

  init(
    router: Router,
    config: any UIConfigType,
    interactor: StartupInteractor,
    animationDurationLoader: @escaping (VideoAsset) async -> TimeInterval? = { await $0.duration() }
  ) {
    guard let config = config as? AppIntroUiConfig else {
      fatalError("Config error :: config must be of type AppIntroUiConfig")
    }
    self.interactor = interactor
    self.continueRoute = config.continueRoute
    self.animationDurationLoader = animationDurationLoader
    super.init(
      router: router,
      initialState: AppIntroState(
        page: config.page,
        isAnimationPaused: false,
        isAnimationToggleVisible: false
      )
    )
  }

  func loadAnimationDuration() async {
    let duration = await animationDurationLoader(viewState.page.videoAsset) ?? 0
    let isVisible = duration >= pausableAnimationMinimumDuration
    setState { $0.copy(isAnimationToggleVisible: isVisible) }
  }

  func onPrimaryTapped() {
    if let next = viewState.page.next {
      router.push(
        with: .featureStartupModule(
          .appIntro(config: AppIntroUiConfig(page: next, continueRoute: continueRoute))
        )
      )
    } else {
      completeIntro()
    }
  }

  func onSkipTapped() {
    completeIntro()
  }

  func onBackTapped() {
    router.pop()
  }

  func toggleAnimation() {
    setState { $0.copy(isAnimationPaused: !$0.isAnimationPaused) }
  }

  func pauseAnimation() {
    guard !viewState.isAnimationPaused else { return }
    setState { $0.copy(isAnimationPaused: true) }
  }

  private func completeIntro() {
    interactor.markAppIntroSeen()
    router.push(with: continueRoute)
  }
}
