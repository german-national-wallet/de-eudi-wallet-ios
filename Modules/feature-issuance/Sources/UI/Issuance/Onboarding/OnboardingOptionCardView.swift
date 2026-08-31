//
//  OnboardingOptionCardView.swift
//  feature-issuance
//

import SwiftUI
import logic_ui
import logic_resources

struct OnboardingOptionCardView: View {
  let title: LocalizableStringKey
  var accessibilityId: String?
  let action: () -> Void

  /// Renders inline markdown (e.g. `**bold**`) from the localized value; a plain
  /// string comes through unchanged, so translations without markers stay valid.
  private var styledTitle: AttributedString {
    let raw = title.toString
    return (try? AttributedString(
      markdown: raw,
      options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)
    )) ?? AttributedString(raw)
  }

  var body: some View {
    Button(action: action) {
      HStack(spacing: DSStyle.Spacers.SPACING_MEDIUM) {
        Text(styledTitle)
          .font(DSTypography.Label.large)
          .foregroundColor(DSColor.onSecondaryContainer)
          .multilineTextAlignment(.leading)
          .frame(maxWidth: .infinity, alignment: .leading)

        Theme.shared.image.arrowForward
          .resizable()
          .scaledToFit()
          .frame(width: DSStyle.Sizes.Icons.large, height: DSStyle.Sizes.Icons.large)
          .foregroundColor(DSColor.onSecondaryContainer)
      }
      .padding(.horizontal, DSStyle.Spacers.SPACING_MEDIUM)
      .padding(.vertical, DSStyle.Spacers.SPACING_SMALL)
      .frame(height: 78)
      .contentShape(Rectangle())
    }
    .overlay(
      RoundedRectangle(cornerRadius: DSStyle.Sizes.CornerRadius.medium)
        .stroke(DSColor.outline, lineWidth: 1)
    )
    .if(accessibilityId != nil) { view in
      view.accessibilityIdentifier(accessibilityId!)
    }
  }
}
