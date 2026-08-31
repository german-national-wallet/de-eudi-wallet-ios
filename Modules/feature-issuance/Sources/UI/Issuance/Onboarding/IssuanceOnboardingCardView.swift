//
//  IssuanceOnboardingCardView.swift
//  feature-issuance
//

import SwiftUI
import logic_ui
import logic_resources

struct IssuanceOnboardingCardView: View {
  var onBack: () -> Void = {}
  var onHelp: () -> Void = {}
  var onPrimaryOptionTapped: () -> Void = {}
  var onSecondaryOptionTapped: () -> Void = {}

  @State private var isEidFunctionInfoSheetPresented = false

  var body: some View {
    ContentScreenView(padding: .zero) {
      HeaderContentView(onBack: onBack, onHelp: onHelp)

      VStack(alignment: .leading, spacing: DSStyle.Spacers.SPACING_LARGE) {
        DSTitleLabel(.pidOnboardingCardsTitle)
          .frame(maxWidth: .infinity, alignment: .leading)
        VStack(alignment: .leading, spacing: DSStyle.Spacers.SPACING_LARGE_MEDIUM) {
          cardRow(
            image: Theme.shared.image.demoPids1,
            label: .pidOnboardingCardsList1
          )
          cardRow(
            image: Theme.shared.image.demoPids2,
            label: .pidOnboardingCardsList2
          )
        }
        .frame(maxWidth: .infinity, alignment: .center)
      }
      .padding(.horizontal, DSStyle.Spacers.SPACING_MEDIUM)
      .padding(.top, DSStyle.Spacers.SPACING_LARGE)

      Spacer()

      VStack(spacing: DSStyle.Spacers.SPACING_SMALL) {
        Button(
          action: { isEidFunctionInfoSheetPresented = true },
          label: {
            HStack(spacing: DSStyle.Spacers.SPACING_SMALL) {
              Theme.shared.image.eidLogo
                .resizable()
                .scaledToFit()
                .frame(width: 18, height: 18)

              Text(.pidOnboardingCardsTertButton)
                .font(DSTypography.Label.large)
                .fontWeight(DSStyle.FontWeight.medium_500)
                .foregroundColor(DSColor.onSecondaryContainer)
            }
          }
        )
        .frame(height: 48)

        OnboardingOptionCardView(
          title: .pidOnboardingCardsPrimButton,
          accessibilityId: "onboardingCardsPrimaryOption",
          action: onPrimaryOptionTapped
        )
        OnboardingOptionCardView(
          title: .pidOnboardingCardsSecButton,
          accessibilityId: "onboardingCardsSecondaryOption",
          action: onSecondaryOptionTapped
        )
      }
      .padding(.horizontal, DSStyle.Spacers.SPACING_MEDIUM)
      .padding(.top, DSStyle.Spacers.SPACING_SMALL)
      .padding(.bottom, DSStyle.Spacers.SPACING_LARGE)
    }
    .sheet(isPresented: $isEidFunctionInfoSheetPresented) {
      EidFunctionInfoSheetView(onClose: { isEidFunctionInfoSheetPresented = false })
        .presentationDetents([.fraction(0.75)])
    }
  }

  @ViewBuilder
  private func cardRow(image: Image, label: LocalizableStringKey) -> some View {
    HStack(spacing: DSStyle.Spacers.SPACING_MEDIUM) {
      image
        .clipShape(RoundedRectangle(cornerRadius: DSStyle.Sizes.CornerRadius.xSmall))
        .overlay(
          RoundedRectangle(cornerRadius: DSStyle.Sizes.CornerRadius.xSmall)
            .stroke(DSColor.outlineVariant, lineWidth: 1)
        )

      Text(label)
        .font(DSTypography.Body.large)
        .foregroundColor(DSColor.onSurface)
        .fixedSize(horizontal: false, vertical: true)
    }
  }
}

private struct EidFunctionInfoSheetView: View {
  let onClose: () -> Void

  var body: some View {
    VStack(spacing: DSStyle.Spacers.SPACING_LARGE_MEDIUM) {
      Theme.shared.image.eidLogo
        .resizable()
        .scaledToFit()
        .frame(width: DSStyle.Sizes.Icons.xxLarge, height: DSStyle.Sizes.Icons.xxLarge)
        .padding(.top, DSStyle.Spacers.SPACING_LARGE)

      Text(.pidEidFunctionInfoTitle)
        .font(DSTypography.Title.large)
        .foregroundColor(DSColor.onBackground)
        .multilineTextAlignment(.center)
        .fixedSize(horizontal: false, vertical: true)
        .accessibilityAddTraits(.isHeader)

      Group {
        Text(.pidEidFunctionInfoParagraph1)
        Text(.pidEidFunctionInfoParagraph2)
      }
      .font(DSTypography.Body.large)
      .foregroundColor(DSColor.onSurface)
      .multilineTextAlignment(.leading)
      .fixedSize(horizontal: false, vertical: true)
      .frame(maxWidth: .infinity, alignment: .leading)

      Spacer()

      DSSecondaryButton(
        title: LocalizableStringKey.globalCloseHintButton.toString,
        action: onClose
      )
    }
    .padding(DSStyle.Spacers.SPACING_MEDIUM)
    .background(DSColor.background)
  }
}

#Preview {
  IssuanceOnboardingCardView()
}
