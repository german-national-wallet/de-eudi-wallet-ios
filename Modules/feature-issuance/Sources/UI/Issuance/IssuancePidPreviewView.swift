//
//  IssuancePidPreviewView.swift
//  feature-issuance
//

import SwiftUI
import logic_ui
import logic_resources
import feature_common

struct IssuancePidPreviewView<Router: RouterHost>: View {
  @ObservedObject private var viewModel: IssuancePidPreviewViewModel<Router>

  @State private var isCancelDialogPresented = false

  init(with viewModel: IssuancePidPreviewViewModel<Router>) {
    self.viewModel = viewModel
  }

  var body: some View {
    ContentScreenView(padding: .zero) {
      HeaderContentView(
        onClose: { isCancelDialogPresented = true },
        onHelp: viewModel.helpTapped,
        progress: (current: 4, total: 4)
      )

      ScrollView {
        VStack(alignment: .leading, spacing: DSStyle.Spacers.SPACING_LARGE_MEDIUM) {
          DSTitleLabel(.pidIDPreviewTitle)
            .accessibilityIdentifier("issuancePidPreviewTitle")

          PIDCredentialCardView(
            credentialTitle: LocalizableStringKey.dashboardCardTitle.toString,
            issuer: LocalizableStringKey.dashboardCardIssuer.toString
          )

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
      icon: Theme.shared.image.infoCircleImage,
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
    // Confirming means the user abandoned issuance, so this runs the same
    // cancel-then-close as the reject dialog rather than only navigating away.
    .cancelConfirmationDialog(
      isPresented: $isCancelDialogPresented,
      onConfirm: viewModel.rejectConfirmed
    )

    .background(DisableSwipeBackGesture())
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
