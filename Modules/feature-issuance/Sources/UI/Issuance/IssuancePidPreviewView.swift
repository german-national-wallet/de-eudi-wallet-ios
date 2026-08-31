//
//  IssuancePidPreviewView.swift
//  feature-issuance
//

import SwiftUI
import logic_ui
import logic_resources
import feature_common

/// Confirms the credential that is about to be added, after the card has been read
/// and before the wallet code is set. Reached from `IssuanceCardView` on a successful scan.
struct IssuancePidPreviewView<Router: RouterHost>: View {
  @ObservedObject private var viewModel: IssuancePidPreviewViewModel<Router>

  init(with viewModel: IssuancePidPreviewViewModel<Router>) {
    self.viewModel = viewModel
  }

  var body: some View {
    ContentScreenView(padding: .zero) {
      HeaderContentView(
        onClose: viewModel.closeButtonTapped,
        onHelp: viewModel.helpTapped,
        progress: (current: 4, total: 4)
      )

      ScrollView {
        VStack(alignment: .leading, spacing: DSStyle.Spacers.SPACING_LARGE_MEDIUM) {
          DSTitleLabel(.pidIDPreviewTitle)
            .accessibilityIdentifier("issuancePidPreviewTitle")

          ZStack {
            RoundedRectangle(cornerRadius: 16)
              .foregroundStyle(DSColor.surfaceContainer)
              .frame(height: 240)
              .frame(maxWidth: .infinity)
              .accessibilityHidden(true)

            ThemeManager.shared.image.workInProgessIcon
          }

          issuerView
        }
        .padding(.horizontal, DSStyle.Spacers.SPACING_MEDIUM)
        .padding(.top, DSStyle.Spacers.SPACING_SMALL)
        .padding(.bottom, DSStyle.Spacers.SPACING_LARGE)
      }
      .scrollIndicators(.hidden)

      bottomActions
    }
    .centerDialog(
      isPresented: $viewModel.isRejectDialogOpen,
      icon: Theme.shared.image.infoCircle,
      title: .issuanceConsentRejectInfoTitle,
      subtitle: .issuanceConsentRejectInfoParagraph,
      buttons: [
        .init(
          title: .issuanceConsentRejectInfoPrimaryButtonTitle,
          role: .destructive,
          action: viewModel.rejectConfirmed
        ),
        .init(
          title: .reportProblem,
          role: .secondary,
          trailingIcon: Theme.shared.image.externalLink,
          action: viewModel.reportProblem
        ),
        .init(
          title: .globalCloseButton,
          role: .secondary,
          action: {}
        )
      ]
    )
  }

  private var issuerView: some View {
    VStack(alignment: .leading, spacing: DSStyle.Spacers.SPACING_SMALL) {
      DSTitleLabel(
        .pidIDPreviewIssuerLabel,
        font: DSTypography.Label.large,
        color: DSColor.onBackgroundVariant
      )

      Button(action: viewModel.showIssuerDetails) {
        HStack(spacing: DSStyle.Spacers.SPACING_SMALL) {
          Theme.shared.image.buildingBlocks
            .resizable()
            .scaledToFit()
            .frame(
              width: DSStyle.Sizes.Icons.large,
              height: DSStyle.Sizes.Icons.large
            )

          Text(.pidIDPreviewIssuerName)
            .font(DSTypography.Body.large)
            .foregroundColor(DSColor.onBackground)
            .multilineTextAlignment(.leading)

          Spacer()

          Theme.shared.image.arrowForward
            .resizable()
            .scaledToFit()
            .frame(
              width: DSStyle.Sizes.Icons.medium,
              height: DSStyle.Sizes.Icons.medium
            )
            .foregroundColor(DSColor.onBackground)
            .accessibilityHidden(true)
        }
        .contentShape(Rectangle())
      }
      .buttonStyle(.plain)
      .accessibilityIdentifier("issuancePidPreviewIssuerButton")
    }
  }

  private var bottomActions: some View {
    HStack(spacing: DSStyle.Spacers.SPACING_MEDIUM) {
      DSSecondaryButton(
        title: LocalizableStringKey.reject.toString,
        action: viewModel.rejectButtonTapped
      )
      .accessibilityIdentifier("issuancePidPreviewRejectButton")

      DSPrimaryButton(
        title: LocalizableStringKey.globalNext.toString,
        trailingIcon: Theme.shared.image.arrowForward,
        action: viewModel.continueTapped
      )
      .accessibilityIdentifier("issuancePidPreviewContinueButton")
    }
    .padding(.horizontal, DSStyle.Spacers.SPACING_MEDIUM)
    .padding(.top, DSStyle.Spacers.SPACING_SMALL)
    .padding(.bottom, DSStyle.Spacers.SPACING_LARGE)
  }
}
