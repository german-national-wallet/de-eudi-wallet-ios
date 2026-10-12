//
//  WalletLossProtectionView.swift
//  feature-dashboard
//
//  Created by Ameen Qadri on 29.09.26.
//

import SwiftUI
import logic_ui
import logic_resources

private enum Constants {
  static let bannerIconSize: CGFloat = 18
  static let bannerIconSlotSize: CGFloat = 28
  static let shareIconSize: CGFloat = 18
  static let buttonHeight: CGFloat = 48
  static let borderWidth: CGFloat = 1
}

struct WalletLossProtectionView<Router: RouterHost>: View {

  @ObservedObject private var viewModel: WalletLossProtectionViewModel<Router>

  init(with viewModel: WalletLossProtectionViewModel<Router>) {
    self.viewModel = viewModel
  }

  var body: some View {
    ContentScreenView(padding: .zero) {
      HeaderContentView(onBack: viewModel.backButtonTapped)

      ScrollView {
        VStack(alignment: .leading, spacing: DSStyle.Spacers.SPACING_LARGE_MEDIUM) {
          VStack(alignment: .leading, spacing: DSStyle.Spacers.SPACING_MEDIUM) {
            Text(.settingsRevocationKeyTitle)
              .font(DSTypography.Title.large)
              .fontWeight(DSStyle.FontWeight.medium_500)
              .foregroundStyle(DSColor.onBackground)
              .accessibilityAddTraits(.isHeader)
              .accessibilityIdentifier("walletLossProtectionTitle")

            Text(.settingsRevocationSetupParagraph)
              .font(DSTypography.Body.large)
              .foregroundStyle(DSColor.onBackgroundVariant)
          }

          banner

          if let revocationCode = viewModel.viewState.revocationCode {
            VStack(alignment: .leading, spacing: DSStyle.Spacers.SPACING_MEDIUM) {
              VStack(alignment: .leading, spacing: DSStyle.Spacers.SPACING_SMALL) {
                Text(.settingsRevocationKeyHeadlineKey)
                  .font(DSTypography.Label.large)
                  .foregroundStyle(DSColor.onBackground)

                RevocationCodeView(
                  code: revocationCode,
                  copyTitle: .settingsRevocationKeyCopyButton,
                  copiedTitle: .settingsRevocationKeyCopiedButton,
                  isCopied: viewModel.viewState.isCodeCopied,
                  codeAccessibilityId: "walletLossProtectionCodeText",
                  copyButtonAccessibilityId: "walletLossProtectionCopyButton",
                  onCopy: viewModel.copyCode
                )
              }

              shareButton(revocationCode: revocationCode)
            }
          }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, DSStyle.Spacers.SPACING_MEDIUM)
        .padding(.top, DSStyle.Spacers.SPACING_MEDIUM_LARGE)
        .padding(.bottom, DSStyle.Spacers.SPACING_LARGE)
      }
    }
  }

  private var banner: some View {
    HStack(alignment: .top, spacing: DSStyle.Spacers.SPACING_SMALL) {
      Theme.shared.image.infoCircleImage
        .renderingMode(.template)
        .resizable()
        .scaledToFit()
        .frame(width: Constants.bannerIconSize, height: Constants.bannerIconSize)
        .frame(width: Constants.bannerIconSlotSize, height: Constants.bannerIconSlotSize)
        .foregroundStyle(DSColor.onSurface)
        .accessibilityHidden(true)

      Text(.settingsRevocationKeyBanner)
        .font(DSTypography.Body.large)
        .foregroundStyle(DSColor.onSurface)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    .padding(DSStyle.Spacers.SPACING_MEDIUM)
    .background(DSColor.surfaceContainer)
    .clipShape(RoundedRectangle(cornerRadius: DSStyle.Sizes.CornerRadius.medium))
  }

  private func shareButton(revocationCode: String) -> some View {
    ShareLink(item: revocationCode) {
      HStack(spacing: DSStyle.Spacers.SPACING_SMALL) {
        Theme.shared.image.shareIcon
          .renderingMode(.template)
          .resizable()
          .scaledToFit()
          .frame(width: Constants.shareIconSize, height: Constants.shareIconSize)
          .accessibilityHidden(true)

        Text(.menuRevocationKeyShareButton)
          .font(DSTypography.Label.large)
      }
      .foregroundStyle(DSColor.onSecondaryContainer)
      .frame(maxWidth: .infinity, minHeight: Constants.buttonHeight)
      .overlay(
        Capsule()
          .stroke(DSColor.outline, lineWidth: Constants.borderWidth)
      )
      .contentShape(Capsule())
    }
    .accessibilityIdentifier("walletLossProtectionShareButton")
  }
}
