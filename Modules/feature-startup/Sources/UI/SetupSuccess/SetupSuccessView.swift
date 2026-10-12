//
//  SetupSuccessView.swift
//  feature-startup
//

import SwiftUI
import logic_ui
import logic_resources
import logic_business

struct SetupSuccessView<Router: RouterHost>: View {

  @ObservedObject private var viewModel: SetupSuccessViewModel<Router>

  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  private let animationSize: CGFloat = 200
  private let titlePullUp: CGFloat = DSStyle.Spacers.SPACING_EXTRA_LARGE
  private let reducedMotionDisplayDuration: TimeInterval = 1.5

  init(with viewModel: SetupSuccessViewModel<Router>) {
    self.viewModel = viewModel
  }

  var body: some View {
    ContentScreenView(allowBackGesture: false) {
      VStack(spacing: DSStyle.Spacers.SPACING_MEDIUM) {
        Spacer()

        LottieAnimationView(
          asset: .successInline,
          size: animationSize,
          isPaused: reduceMotion,
          onFinished: viewModel.onAnimationFinished
        )

        Text(.appOnboardingSetupSuccessTitle)
          .font(DSTypography.Title.medium)
          .foregroundStyle(DSColor.onBackground)
          .multilineTextAlignment(.center)
          .offset(y: -titlePullUp)
          .accessibilityAddTraits(.isHeader)
          .accessibilityIdentifier("setupSuccessTitle")

        Spacer()
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    .onAppear {
      UIAccessibility.post(
        notification: .screenChanged,
        argument: LocalizableStringKey.appOnboardingSetupSuccessTitle.toString
      )
    }
    .task {
      guard reduceMotion else { return }
      try? await Task.sleep(nanoseconds: reducedMotionDisplayDuration.nanoseconds)
      viewModel.onAnimationFinished()
    }
  }
}
