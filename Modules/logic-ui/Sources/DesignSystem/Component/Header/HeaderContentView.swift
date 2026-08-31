//
//  HeaderContentView.swift
//  logic-ui
//

import SwiftUI
import logic_resources

public struct HeaderContentView: View {
  let onBack: (() -> Void)?
  let onClose: (() -> Void)?
  let onHelp: (() -> Void)?
  let progress: (current: Int, total: Int)?

  public init(
    onBack: (() -> Void)? = nil,
    onClose: (() -> Void)? = nil,
    onHelp: (() -> Void)? = nil,
    progress: (current: Int, total: Int)? = nil
  ) {
    self.onBack = onBack
    self.onClose = onClose
    self.onHelp = onHelp
    self.progress = progress
  }

  public var body: some View {
    VStack(spacing: DSStyle.Spacers.SPACING_EXTRA_SMALL) {
      HStack(spacing: DSStyle.Spacers.SPACING_SMALL) {
        if let onBack = onBack {
          Button(action: { onBack() }, label: {
            Theme.shared.image.arrowBackIcon
          })
          .accessibilityLabel(Text(LocalizableStringKey.globalBackButtonA11y.toLocalizedStringKey))
          .accessibilityIdentifier("headerBackButton")
        }

        Spacer()

        if let onHelp = onHelp {
          Button(action: { onHelp() }, label: {
            Theme.shared.image.help
              .resizable()
              .scaledToFit()
              .frame(width: DSStyle.Sizes.Icons.medium, height: DSStyle.Sizes.Icons.medium)
              .foregroundColor(DSColor.onBackground)
          })
          .accessibilityLabel(Text(LocalizableStringKey.headerAccessibilityHelp.toLocalizedStringKey))
          .accessibilityIdentifier("headerHelpButton")
        }

        if let onClose = onClose {
          Button(action: { onClose() }, label: {
            Theme.shared.image.xmark
          })
          .accessibilityLabel(Text(LocalizableStringKey.globalCloseButtonA11y.toLocalizedStringKey))
          .accessibilityIdentifier("headerCloseButton")
        }
      }
      .frame(height: 32)

      if let progress = progress {
        HStack(spacing: DSStyle.Spacers.SPACING_SMALL) {
          ForEach(0..<max(progress.total, 1), id: \.self) { index in
            Capsule()
              .fill(index < progress.current ? DSColor.primary : DSColor.outlineVariant)
              .frame(height: DSStyle.Spacers.SPACING_EXTRA_SMALL)
              .frame(maxWidth: .infinity)
          }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
          Text(
            LocalizableStringKey.headerAccessibilityProgress(
              ["\(progress.current)", "\(max(progress.total, 1))"]
            ).toLocalizedStringKey
          )
        )
      }
    }
    .padding(.horizontal, DSStyle.Spacers.SPACING_MEDIUM)
    .padding(.top, DSStyle.Spacers.SPACING_MEDIUM)
  }
}
