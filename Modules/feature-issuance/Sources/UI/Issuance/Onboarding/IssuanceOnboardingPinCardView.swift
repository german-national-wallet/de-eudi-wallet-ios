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

  @State private var isPinInfoSheetPresented = false

  var body: some View {
    ContentScreenView(padding: .zero) {
      HeaderContentView(
        onBack: onBack,
        onClose: onClose,
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
          action: { isPinInfoSheetPresented = true }
        )
      }
      .padding(.horizontal, DSStyle.Spacers.SPACING_MEDIUM)
      .padding(.top, DSStyle.Spacers.SPACING_SMALL)
      .padding(.bottom, DSStyle.Spacers.SPACING_LARGE)
    }
    .sheet(isPresented: $isPinInfoSheetPresented) {
      PINIssuanceInfoView(
        onFindNearbyBurgerAmt: openBurgeramtWebpage,
        router: router,
        isSheetPresented: $isPinInfoSheetPresented,
        issuanceInteractor: issuanceInteractor
      )
      .background(DSColor.background)
      .clipShape(RoundedCorner(radius: 20, corners: [.topLeft, .topRight]))
      .ignoresSafeArea()
      .presentationDetents([.fraction(0.7)])
    }
  }

  private func openBurgeramtWebpage() {
    if let url = AppEnvironment.burgeramtServiceLink {
      UIApplication.shared.open(url)
    }
  }
}
