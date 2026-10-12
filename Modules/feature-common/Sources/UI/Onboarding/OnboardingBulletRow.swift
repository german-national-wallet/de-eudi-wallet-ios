//
//  OnboardingBulletRow.swift
//  feature-common
//

import SwiftUI
import logic_ui
import logic_resources

public struct OnboardingBulletRow: View {

  private let icon: Image
  private let iconColor: Color
  private let iconSize: CGFloat = 18
  private let text: LocalizableStringKey
  private let textColor: Color

  public init(
    icon: Image,
    iconColor: Color = DSColor.onBackgroundVariant,
    text: LocalizableStringKey,
    textColor: Color = DSColor.onBackgroundVariant
  ) {
    self.icon = icon
    self.iconColor = iconColor
    self.text = text
    self.textColor = textColor
  }

  public var body: some View {
    HStack(alignment: .top, spacing: DSStyle.Spacers.SPACING_SMALL) {
      icon
        .renderingMode(.template)
        .resizable()
        .scaledToFit()
        .frame(width: iconSize, height: iconSize)
        .foregroundStyle(iconColor)
        .frame(width: DSStyle.Sizes.Icons.large, height: DSStyle.Sizes.Icons.large)
        .accessibilityHidden(true)
      Text(text)
        .font(DSTypography.Body.large)
        .foregroundStyle(textColor)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    .padding(.vertical, DSStyle.Spacers.SPACING_EXTRA_SMALL)
    .accessibilityElement(children: .combine)
  }
}
