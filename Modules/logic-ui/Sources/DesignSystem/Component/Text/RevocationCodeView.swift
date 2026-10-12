//
//  RevocationCodeView.swift
//  logic-ui
//
//  Created by Ameen Qadri on 29.09.26.
//

import SwiftUI
import logic_resources

public struct RevocationCodeView: View {

  private enum Constants {
    static let groupLength = 4
    static let copyIconSize: CGFloat = 20
    static let copyButtonWidth: CGFloat = 68
    static let borderWidth: CGFloat = 1
  }

  private let code: String
  private let copyTitle: LocalizableStringKey
  private let copiedTitle: LocalizableStringKey
  private let isCopied: Bool
  private let codeAccessibilityId: String
  private let copyButtonAccessibilityId: String
  private let onCopy: () -> Void

  public init(
    code: String,
    copyTitle: LocalizableStringKey,
    copiedTitle: LocalizableStringKey,
    isCopied: Bool,
    codeAccessibilityId: String,
    copyButtonAccessibilityId: String,
    onCopy: @escaping () -> Void
  ) {
    self.code = code
    self.copyTitle = copyTitle
    self.copiedTitle = copiedTitle
    self.isCopied = isCopied
    self.codeAccessibilityId = codeAccessibilityId
    self.copyButtonAccessibilityId = copyButtonAccessibilityId
    self.onCopy = onCopy
  }

  public var body: some View {
    HStack(spacing: .zero) {
      Text(verbatim: formattedCode)
        .font(.system(.body, design: .monospaced))
        .foregroundStyle(DSColor.onBackgroundVariant)
        .fixedSize(horizontal: false, vertical: true)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(DSStyle.Spacers.SPACING_MEDIUM_SMALL)
        .accessibilityIdentifier(codeAccessibilityId)

      Rectangle()
        .fill(DSColor.outlineVariant)
        .frame(width: Constants.borderWidth)
        .padding(.vertical, DSStyle.Spacers.SPACING_MEDIUM_SMALL)

      copyButton
        .padding(.horizontal, DSStyle.Spacers.SPACING_MEDIUM_SMALL)
    }
    .frame(maxWidth: .infinity)
    .overlay(
      RoundedRectangle(cornerRadius: DSStyle.Sizes.CornerRadius.medium)
        .stroke(DSColor.outlineVariant, lineWidth: Constants.borderWidth)
    )
  }

  private var copyButton: some View {
    Button(action: onCopy) {
      VStack(spacing: DSStyle.Spacers.SPACING_EXTRA_SMALL) {
        Theme.shared.image.copyIcon
          .renderingMode(.template)
          .resizable()
          .scaledToFit()
          .frame(width: Constants.copyIconSize, height: Constants.copyIconSize)
          .iconButtonSlot()
          .accessibilityHidden(true)

        Text(isCopied ? copiedTitle : copyTitle)
          .font(DSTypography.Label.medium)
          .multilineTextAlignment(.center)
          .lineLimit(1)
          .minimumScaleFactor(0.8)
          .frame(width: Constants.copyButtonWidth)
      }
      .foregroundStyle(DSColor.onBackgroundVariant)
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .animation(.easeInOut, value: isCopied)
    .accessibilityIdentifier(copyButtonAccessibilityId)
  }

  private var formattedCode: String {
    let characters = Array(code)
    return stride(from: 0, to: characters.count, by: Constants.groupLength)
      .map { String(characters[$0..<min($0 + Constants.groupLength, characters.count)]) }
      .joined(separator: " ")
  }
}

#Preview {
  RevocationCodeView(
    code: "rev1dl5rvzak5x726vhtdgyfra797n4xuzraw3pst927ytdpe5s7g2us8xraur",
    copyTitle: .settingsRevocationKeyCopyButton,
    copiedTitle: .settingsRevocationKeyCopiedButton,
    isCopied: false,
    codeAccessibilityId: "revocationCodeText",
    copyButtonAccessibilityId: "revocationCodeCopyButton",
    onCopy: {}
  )
  .padding()
}
