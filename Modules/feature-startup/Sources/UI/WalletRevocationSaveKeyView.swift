//
//  WalletRevocationSaveKeyView.swift
//  feature-startup
//

import SwiftUI
import logic_ui
import logic_resources
import feature_common

struct WalletRevocationSaveKeyView<Router: RouterHost>: View {

  @ObservedObject private var viewModel: WalletRevocationSaveKeyViewModel<Router>

  init(with viewModel: WalletRevocationSaveKeyViewModel<Router>) {
    self.viewModel = viewModel
  }

  var body: some View {
    VStack(spacing: 0) {
      HeaderContentView(onBack: viewModel.backButtonTapped)

      ScrollView {
        VStack(alignment: .leading, spacing: DSStyle.Spacers.SPACING_LARGE) {

          Text(.appOnboardingWalletRevocationSaveKeyTitle)
            .font(DSTypography.Title.large)
            .fontWeight(DSStyle.FontWeight.medium_500)
            .foregroundStyle(DSColor.onSurface)

          VStack(alignment: .leading, spacing: DSStyle.Spacers.SPACING_MEDIUM_SMALL) {
            Text(.appOnboardingWalletRevocationSaveKeyHeadline1)
              .font(DSTypography.Body.large)
              .foregroundStyle(DSColor.onSurface)

            RevocationCodeView(
              code: viewModel.rawRevocationCode,
              copyTitle: .appOnboardingWalletRevocationSaveKeyCopyButton,
              copiedTitle: .appOnboardingWalletRevocationSaveKeyCopiedButton,
              isCopied: viewModel.viewState.isCodeCopied,
              codeAccessibilityId: "revocationCodeText",
              copyButtonAccessibilityId: "revocationCodeCopyButton",
              onCopy: viewModel.copyCode
            )
          }

          shareButton
        }
        .padding(.horizontal, DSStyle.Spacers.SPACING_MEDIUM)
        .padding(.top, DSStyle.Spacers.SPACING_LARGE)
      }

      bottomBar
    }
    .ignoresSafeArea(edges: .bottom)
    .background(DSColor.background)
  }

  private var shareButton: some View {
    ShareLink(item: viewModel.rawRevocationCode) {
      HStack(spacing: DSStyle.Spacers.SPACING_SMALL) {
        Theme.shared.image.shareIcon
          .resizable()
          .aspectRatio(contentMode: .fit)
          .frame(width: 24, height: 24)
        Text(LocalizableStringKey.appOnboardingWalletRevocationSaveKeyShareButton.toLocalizedStringKey)
          .font(DSTypography.Body.large)
      }
      .foregroundStyle(DSColor.onSurface)
      .frame(maxWidth: .infinity)
      .padding(.vertical, DSStyle.Spacers.SPACING_MEDIUM)
      .overlay(
        RoundedRectangle(cornerRadius: 28)
          .stroke(DSColor.outlineVariant, lineWidth: 1)
      )
    }
    .accessibilityIdentifier("revocationCodeShareButton")
  }

  private var bottomBar: some View {
    VStack(alignment: .leading, spacing: DSStyle.Spacers.SPACING_MEDIUM) {
      OnboardingConsentCheckbox(
        isOn: viewModel.viewState.isSavedElsewhere,
        label: .appOnboardingWalletRevocationSaveKeyCheckboxLabel,
        checkboxAccessibilityIdentifier: "revocationSavedElsewhereCheckbox"
      ) {
        viewModel.setSavedElsewhere(!viewModel.viewState.isSavedElsewhere)
      }

      DSPrimaryButton(
        title: LocalizableStringKey.appOnboardingWalletRevocationSaveKeyPrimButton.toString
      ) {
        viewModel.onPrimaryButtonTapped()
      }
      .frame(maxWidth: .infinity)
      .disabled(!viewModel.viewState.isSavedElsewhere)
      .keyboardShortcut(.defaultAction)
      .accessibilityIdentifier("revocationSaveKeyPrimaryButton")
    }
    .padding(.horizontal, DSStyle.Spacers.SPACING_MEDIUM)
    .padding(.top, DSStyle.Spacers.SPACING_MEDIUM)
    .padding(.bottom, DSStyle.Spacers.SPACING_LARGE)
    .background(DSColor.background.ignoresSafeArea(edges: .bottom))
  }
}
