//
//  PushNotificationOnboardingView.swift
//  feature-startup
//

import SwiftUI
import logic_ui
import logic_resources
import feature_common

struct PushNotificationOnboardingView<Router: RouterHost>: View {

  @ObservedObject private var viewModel: PushNotificationOnboardingViewModel<Router>

  init(with viewModel: PushNotificationOnboardingViewModel<Router>) {
    self.viewModel = viewModel
  }

  var body: some View {
    VStack(spacing: 0) {
      HeaderContentView(onBack: viewModel.onBackTapped)

      ScrollView {
        VStack(alignment: .leading, spacing: DSStyle.Spacers.SPACING_MEDIUM) {
          OnboardingIllustrationView(image: Theme.shared.image.pushNotificationConsent)

          Text(.appOnboardingPushIntroTitle)
            .font(DSTypography.Title.large)
            .foregroundStyle(DSColor.onBackground)
            .accessibilityAddTraits(.isHeader)
            .accessibilityIdentifier("pushTitle")

          VStack(alignment: .leading, spacing: DSStyle.Spacers.SPACING_EXTRA_SMALL) {
            OnboardingBulletRow(
              icon: Theme.shared.image.sync,
              text: .appOnboardingPushIntroList1
            )
            OnboardingBulletRow(
              icon: Theme.shared.image.bell,
              text: .appOnboardingPushIntroList2
            )
          }

          Text(.appOnboardingPushIntroParagraph)
            .font(DSTypography.Body.large)
            .foregroundStyle(DSColor.onBackgroundVariant)
        }
        .padding(.horizontal, DSStyle.Spacers.SPACING_MEDIUM)
        .padding(.top, DSStyle.Spacers.SPACING_MEDIUM_LARGE)
      }

      bottomBar
    }
    .background(DSColor.background)
  }

  private var bottomBar: some View {
    VStack(spacing: DSStyle.Spacers.SPACING_SMALL) {
      DSPrimaryButton(
        title: LocalizableStringKey.appOnboardingPushIntroPrimButton.toString
      ) {
        Task { await viewModel.onEnableNotificationsTapped() }
      }
      .disabled(viewModel.viewState.isRequestingAuthorization)
      .keyboardShortcut(.defaultAction)
      .accessibilityIdentifier("pushPrimaryButton")

      DSSecondaryButton(
        title: LocalizableStringKey.appOnboardingPushIntroSecButton.toString
      ) {
        viewModel.onLaterTapped()
      }
      .disabled(viewModel.viewState.isRequestingAuthorization)
      .accessibilityIdentifier("pushSecondaryButton")
    }
    .padding(.horizontal, DSStyle.Spacers.SPACING_MEDIUM)
    .padding(.top, DSStyle.Spacers.SPACING_SMALL)
    .padding(.bottom, DSStyle.Spacers.SPACING_LARGE)
    .background(DSColor.background.ignoresSafeArea(edges: .bottom))
  }
}
