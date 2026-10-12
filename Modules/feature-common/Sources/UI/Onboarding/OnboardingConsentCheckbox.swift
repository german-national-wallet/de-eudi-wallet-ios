//
//  OnboardingConsentCheckbox.swift
//  feature-common
//

import SwiftUI
import logic_ui
import logic_resources

public struct OnboardingConsentCheckbox: View {

  private let isOn: Bool
  private let label: LocalizableStringKey
  private let checkboxAccessibilityIdentifier: String?
  private let onToggle: () -> Void
  private let onLinkTapped: ((URL) -> Void)?

  private let checkboxSize: CGFloat = 48

  public init(
    isOn: Bool,
    label: LocalizableStringKey,
    checkboxAccessibilityIdentifier: String? = nil,
    onToggle: @escaping () -> Void,
    onLinkTapped: ((URL) -> Void)? = nil
  ) {
    self.isOn = isOn
    self.label = label
    self.checkboxAccessibilityIdentifier = checkboxAccessibilityIdentifier
    self.onToggle = onToggle
    self.onLinkTapped = onLinkTapped
  }

  public var body: some View {
    HStack(alignment: .center, spacing: DSStyle.Spacers.SPACING_SMALL) {
      Button(action: onToggle) {
        (isOn ? Theme.shared.image.checkboxSelected : Theme.shared.image.checkboxUnselected)
          .resizable()
          .aspectRatio(contentMode: .fit)
          .frame(width: checkboxSize, height: checkboxSize)
          .contentShape(Rectangle())
      }
      .buttonStyle(PlainButtonStyle())
      .accessibilityLabel(Text(verbatim: String(styledLabel.characters)))
      .accessibilityAddTraits(isOn ? [.isSelected] : [])
      .if(checkboxAccessibilityIdentifier != nil) { view in
        view.accessibilityIdentifier(checkboxAccessibilityIdentifier!)
      }

      Text(styledLabel)
        .font(DSTypography.Body.large)
        .foregroundStyle(DSColor.onBackgroundVariant)
        .tint(DSColor.onBackgroundVariant)
        .multilineTextAlignment(.leading)
        .frame(maxWidth: .infinity, alignment: .leading)
        .environment(\.openURL, OpenURLAction { url in
          onLinkTapped?(url)
          return .handled
        })
    }
  }

  private var styledLabel: AttributedString {
    var attributed = label.toAttributedString
    for run in attributed.runs where run.link != nil {
      attributed[run.range].underlineStyle = .single
      attributed[run.range].foregroundColor = DSColor.onBackgroundVariant
    }
    return attributed
  }
}
