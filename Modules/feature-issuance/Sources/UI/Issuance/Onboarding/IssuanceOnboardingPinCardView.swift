//
//  IssuanceOnboardingPinCardView.swift
//  feature-issuance
//

import SwiftUI
import logic_ui
import logic_resources
import logic_core
import feature_common

struct IssuanceOnboardingPinCardView<Router: RouterHost>: View {
  let router: Router
  let issuanceInteractor: IssuanceVerificationInteractor?
  var onBack: () -> Void = {}
  var onClose: () -> Void = {}
  var onCardPinKnownTapped: () -> Void = {}
  var onSetPinWithLetterTapped: () -> Void = {}
  var onNoPinLetterOrForgottenTapped: () -> Void = {}

  @State private var isPinInfoSheetPresented = false
  @State private var isCancelDialogPresented = false

  var body: some View {
    ContentScreenView(padding: .zero) {
      HeaderContentView(
        onBack: onBack,
        onClose: { isCancelDialogPresented = true },
        onHelp: { isPinInfoSheetPresented = true }
      )

      ScrollView {
        VStack(spacing: DSStyle.Spacers.SPACING_EXTRA_LARGE) {
          DSTitleLabel(.issuanceOnboardingPinInfoViewTitle)
            .frame(maxWidth: .infinity, alignment: .leading)

          Theme.shared.image.pinCodeAsset
        }
        .padding(.horizontal, DSStyle.Spacers.SPACING_MEDIUM)
        .padding(.top, DSStyle.Spacers.SPACING_LARGE)
      }

      VStack(spacing: DSStyle.Spacers.SPACING_SMALL) {
        Button(
          action: { isPinInfoSheetPresented = true },
          label: {
            HStack(spacing: DSStyle.Spacers.SPACING_SMALL) {
              Theme.shared.image.help
                .resizable()
                .scaledToFit()
                .frame(
                  width: DSStyle.Sizes.Icons.small,
                  height: DSStyle.Sizes.Icons.small
                )
                .foregroundColor(DSColor.onSecondaryContainer)

              Text(.issuanceOnboardingPinInfoViewHelpButtonTitle)
                .font(DSTypography.Label.large)
                .fontWeight(DSStyle.FontWeight.medium_500)
                .foregroundColor(DSColor.onSecondaryContainer)
            }
          }
        )
        .padding(.vertical, DSStyle.Spacers.SPACING_MEDIUM_SMALL)

        OnboardingOptionCardView(
          title: .issuanceOnboardingPinInfoViewPrimaryButtonTitle,
          accessibilityId: "onboardingPinKnownOption",
          action: onCardPinKnownTapped
        )
        OnboardingOptionCardView(
          title: .issuanceOnboardingPinInfoViewSecondaryButtonTitle,
          accessibilityId: "onboardingPinLetterOption",
          action: onSetPinWithLetterTapped
        )
        OnboardingOptionCardView(
          title: .issuanceOnboardingPinInfoViewTertiaryButtonTitle,
          accessibilityId: "onboardingPinForgottenOption",
          action: onNoPinLetterOrForgottenTapped
        )
      }
      .padding(.horizontal, DSStyle.Spacers.SPACING_MEDIUM)
      .padding(.top, DSStyle.Spacers.SPACING_SMALL)
      .padding(.bottom, DSStyle.Spacers.SPACING_LARGE)
    }
    .sheet(isPresented: $isPinInfoSheetPresented) {
      CardPinLetterInfoSheetView(
        onSetCardPin: setCardPin,
        onClose: { isPinInfoSheetPresented = false }
      )
      .presentationDetents([.fraction(0.9)])
    }
    .cancelConfirmationDialog(
      isPresented: $isCancelDialogPresented,
      onConfirm: onClose
    )

    .background(EnableSwipeBackGesture())
  }

  /// Dismisses the sheet before pushing, otherwise the push is swallowed while
  /// the sheet is still on screen.
  private func setCardPin() {
    isPinInfoSheetPresented = false
    guard let issuanceInteractor else { return }
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
      router.push(with: .featureIssuanceModule(
        .setEidTransportPinInstructionsView(
          config: NoConfig(),
          issuanceVerificationInteractor: issuanceInteractor
        )
      ))
    }
  }
}
