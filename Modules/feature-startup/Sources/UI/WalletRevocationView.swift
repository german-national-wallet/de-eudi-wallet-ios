//
//  WalletRevocationView.swift
//  feature-startup
//

import SwiftUI
import logic_ui
import logic_resources
import feature_common

struct WalletRevocationView<Router: RouterHost>: View {

  @ObservedObject private var viewModel: WalletRevocationViewModel<Router>

  init(with viewModel: WalletRevocationViewModel<Router>) {
    self.viewModel = viewModel
  }

  var body: some View {
    VStack(spacing: 0) {
      HeaderContentView(onBack: viewModel.onBackTapped)

      ScrollView {
        VStack(alignment: .leading, spacing: DSStyle.Spacers.SPACING_MEDIUM) {
          OnboardingIllustrationView(video: .phoneLost)

          Text(.appOnboardingWalletRevocationIntroTitle)
            .font(DSTypography.Title.large)
            .foregroundStyle(DSColor.onBackground)
            .accessibilityAddTraits(.isHeader)
            .accessibilityIdentifier("revocationIntroTitle")

          VStack(alignment: .leading, spacing: DSStyle.Spacers.SPACING_EXTRA_SMALL) {
            OnboardingBulletRow(
              icon: Image(systemName: "key"),
              text: .appOnboardingWalletRevocationIntroList1
            )
            OnboardingBulletRow(
              icon: Image(systemName: "lock"),
              text: .appOnboardingWalletRevocationIntroList2
            )
          }
        }
        .padding(.horizontal, DSStyle.Spacers.SPACING_MEDIUM)
        .padding(.top, DSStyle.Spacers.SPACING_MEDIUM_LARGE)
      }

      DSPrimaryButton(
        title: LocalizableStringKey.appOnboardingWalletRevocationIntroPrimButton.toString,
        trailingIcon: Theme.shared.image.arrowForward
      ) {
        viewModel.onPrimaryButtonTapped()
      }
      .keyboardShortcut(.defaultAction)
      .accessibilityIdentifier("revocationIntroPrimaryButton")
      .padding(.horizontal, DSStyle.Spacers.SPACING_MEDIUM)
      .padding(.top, DSStyle.Spacers.SPACING_SMALL)
      .padding(.bottom, DSStyle.Spacers.SPACING_LARGE)
      .background(DSColor.background.ignoresSafeArea(edges: .bottom))
    }
    .background(DSColor.background)
  }
}
