//
//  PlatformAuthenticationBlockingView.swift
//  feature-common
//

import SwiftUI
import logic_ui
import logic_resources

public struct PlatformAuthenticationBlockingView: View {

  private let action: () -> Void

  public init(action: @escaping () -> Void) {
    self.action = action
  }

  public var body: some View {
    VStack(spacing: 0) {
      ScrollView {
        VStack(alignment: .leading, spacing: DSStyle.Spacers.SPACING_MEDIUM) {
          OnboardingIllustrationView(asset: .displayLockedFailure, stretchesBackground: true)

          Text(.appOnboardingPaSetErrorTitle)
            .font(DSTypography.Title.large)
            .foregroundStyle(DSColor.onBackground)
            .accessibilityAddTraits(.isHeader)
            .accessibilityIdentifier("paBlockingTitle")

          Text(.appOnboardingPaSetErrorParagraph)
            .font(DSTypography.Body.large)
            .foregroundStyle(DSColor.onBackgroundVariant)

          OnboardingInfoBanner(text: .appOnboardingPaSetErrorParagraphIos)
        }
        .padding(.horizontal, DSStyle.Spacers.SPACING_MEDIUM)
        .padding(.top, DSStyle.Spacers.SPACING_EXTRA_LARGE)
      }

      DSPrimaryButton(
        title: LocalizableStringKey.appOnboardingPaSetErrorPrimButton.toString,
        trailingIcon: Theme.shared.image.arrowForward,
        action: action
      )
      .keyboardShortcut(.defaultAction)
      .accessibilityIdentifier("paBlockingPrimaryButton")
      .padding(.horizontal, DSStyle.Spacers.SPACING_MEDIUM)
      .padding(.top, DSStyle.Spacers.SPACING_SMALL)
      .padding(.bottom, DSStyle.Spacers.SPACING_LARGE)
    }
    .background(DSColor.background)
  }
}
