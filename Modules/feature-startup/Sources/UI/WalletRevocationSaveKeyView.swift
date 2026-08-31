//
//  WalletRevocationSaveKeyView.swift
//  feature-startup
//

import SwiftUI
import logic_ui
import logic_resources

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

            codeBox
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

  private var codeBox: some View {
    HStack(spacing: 0) {
      Text(viewModel.formattedRevocationCode)
        .font(.system(.body, design: .monospaced))
        .foregroundStyle(DSColor.onSurface)
        .fixedSize(horizontal: false, vertical: true)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(DSStyle.Spacers.SPACING_MEDIUM)
        .accessibilityIdentifier("revocationCodeText")

      Divider()

      Button(action: viewModel.copyCode) {
        VStack(spacing: DSStyle.Spacers.SPACING_SMALL) {
          Theme.shared.image.copyIcon
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 20, height: 20)
          Text(
            viewModel.viewState.isCodeCopied
            ? LocalizableStringKey.appOnboardingWalletRevocationSaveKeyCopiedButton.toLocalizedStringKey
            : LocalizableStringKey.appOnboardingWalletRevocationSaveKeyCopyButton.toLocalizedStringKey
          )
          .font(DSTypography.Body.medium)
        }
        .foregroundStyle(DSColor.onSurface)
        .padding(.horizontal, DSStyle.Spacers.SPACING_MEDIUM)
      }
      .buttonStyle(PlainButtonStyle())
      .animation(.easeInOut(duration: 0.3), value: viewModel.viewState.isCodeCopied)
      .accessibilityIdentifier("revocationCodeCopyButton")
    }
    .frame(maxWidth: .infinity)
    .overlay(
      RoundedRectangle(cornerRadius: 12)
        .stroke(DSColor.outlineVariant, lineWidth: 1)
    )
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
      HStack(spacing: DSStyle.Spacers.SPACING_MEDIUM) {
        Button {
          viewModel.setSavedElsewhere(!viewModel.viewState.isSavedElsewhere)
        } label: {
          (viewModel.viewState.isSavedElsewhere
            ? Theme.shared.image.checkboxSelected
            : Theme.shared.image.checkboxUnselected)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 50, height: 50)
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityIdentifier("revocationSavedElsewhereCheckbox")

        Text(.appOnboardingWalletRevocationSaveKeyCheckboxLabel)
          .font(DSTypography.Body.large)
          .foregroundStyle(DSColor.onSurface)
          .frame(maxWidth: .infinity, alignment: .leading)
      }

      DSPrimaryButton(
        title: LocalizableStringKey.appOnboardingWalletRevocationSaveKeyPrimButton.toString
      ) {
        viewModel.onPrimaryButtonTapped()
      }
      .frame(maxWidth: .infinity)
      .disabled(!viewModel.viewState.isSavedElsewhere)
      .opacity(viewModel.viewState.isSavedElsewhere ? 1.0 : 0.5)
      .accessibilityIdentifier("revocationSaveKeyPrimaryButton")
    }
    .padding(.horizontal, DSStyle.Spacers.SPACING_MEDIUM)
    .padding(.top, DSStyle.Spacers.SPACING_MEDIUM)
    .padding(.bottom, DSStyle.Spacers.SPACING_LARGE)
    .background(DSColor.background.ignoresSafeArea(edges: .bottom))
  }
}
