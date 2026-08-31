//
//  WalletRevocationView.swift
//  feature-startup
//

import SwiftUI
import logic_ui
import logic_resources

struct WalletRevocationView<Router: RouterHost>: View {

  @ObservedObject private var viewModel: WalletRevocationViewModel<Router>

  init(with viewModel: WalletRevocationViewModel<Router>) {
    self.viewModel = viewModel
  }

  var body: some View {
    ContentScreenView(
      canScroll: true,
      allowBackGesture: false
    ) {
      VStack(alignment: .leading, spacing: DSStyle.Spacers.SPACING_LARGE) {
        ZStack {
          RoundedRectangle(cornerRadius: 16)
            .foregroundStyle(DSColor.surfaceContainer)
            .frame(height: 260)
            .frame(maxWidth: .infinity)
            .accessibilityHidden(true)
          
          ThemeManager.shared.image.workInProgessLockIcon
          
        }
        Text(.appOnboardingWalletRevocationIntroTitle)
          .font(DSTypography.Title.large)
          .fontWeight(DSStyle.FontWeight.medium_500)
          .foregroundStyle(DSColor.onSurface)

        VStack(alignment: .leading, spacing: DSStyle.Spacers.SPACING_MEDIUM) {
          bulletRow(icon: "key", text: .appOnboardingWalletRevocationIntroPara1)
          bulletRow(icon: "lock", text: .appOnboardingWalletRevocationIntroPara2)
        }

        Spacer(minLength: DSStyle.Spacers.SPACING_LARGE)

        DSPrimaryButton(
          title: LocalizableStringKey.appOnboardingWalletRevocationIntroPrimButton.toString
        ) {
          viewModel.onPrimaryButtonTapped()
        }
        .frame(maxWidth: .infinity)
        .accessibilityIdentifier("revocationIntroPrimaryButton")
      }
      .padding()
      .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
  }

  private func bulletRow(icon: String, text: LocalizableStringKey) -> some View {
    HStack(alignment: .top, spacing: DSStyle.Spacers.SPACING_MEDIUM) {
      Image(systemName: icon)
        .font(.system(size: 20))
        .foregroundStyle(DSColor.onSurface)
      Text(text)
        .font(DSTypography.Body.large)
        .foregroundStyle(DSColor.onSurfaceVariant)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
  }
}
