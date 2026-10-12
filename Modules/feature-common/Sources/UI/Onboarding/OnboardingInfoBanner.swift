//
//  OnboardingInfoBanner.swift
//  feature-common
//

import SwiftUI
import logic_ui
import logic_resources

public struct OnboardingInfoBanner: View {

  private let text: LocalizableStringKey

  private let iconSize: CGFloat = 18

  public init(text: LocalizableStringKey) {
    self.text = text
  }

  public var body: some View {
    HStack(alignment: .top, spacing: DSStyle.Spacers.SPACING_SMALL) {
      Theme.shared.image.warningOutline
        .renderingMode(.template)
        .resizable()
        .scaledToFit()
        .frame(width: iconSize, height: iconSize)
        .foregroundStyle(DSColor.onSurfaceVariant)
        .frame(width: DSStyle.Sizes.Icons.large, height: DSStyle.Sizes.Icons.large)
        .accessibilityHidden(true)
      Text(text)
        .font(DSTypography.Body.large)
        .foregroundStyle(DSColor.onSurface)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    .padding(DSStyle.Spacers.SPACING_MEDIUM)
    .background(
      RoundedRectangle(cornerRadius: DSStyle.Sizes.CornerRadius.medium)
        .fill(DSColor.surfaceContainer)
    )
    .accessibilityElement(children: .combine)
  }
}
