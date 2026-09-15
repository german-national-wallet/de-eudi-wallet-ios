//
//  PIDCredentialCardView.swift
//  logic-ui
//

import SwiftUI
import logic_resources

public struct PIDCredentialCardView: View {

  public enum Style {
    case final
    case placeholder
  }

  private enum Layout {
    static let headerTextSpacing: CGFloat = 2
    static let headerToImageSpacing: CGFloat = 13
    static let eagleBadgeWidth: CGFloat = 91
    static let eagleBadgeHeight: CGFloat = 70
    static let eagleBadgeTopOffset: CGFloat = -1
    static let eagleSize: CGFloat = 68
    static let backgroundImageAspectRatio: CGFloat = 328 / 141
    static let placeholderMinHeight: CGFloat = 208
    static let placeholderContentInset: CGFloat = 23
  }

  private let credentialTitle: String
  private let issuer: String
  private let style: Style

  public init(
    credentialTitle: String,
    issuer: String = "",
    style: Style = .final
  ) {
    self.credentialTitle = credentialTitle
    self.issuer = issuer
    self.style = style
  }

  public var body: some View {
    switch style {
    case .final:
      finalCard
    case .placeholder:
      placeholderCard
    }
  }

  private var finalCard: some View {
    VStack(alignment: .leading, spacing: Layout.headerToImageSpacing) {
      header(
        titleFont: DSTypography.Body.large,
        issuerColor: DSColor.onSurfaceVariant,
        spacing: Layout.headerTextSpacing
      )
      .padding(.top, DSStyle.Spacers.SPACING_MEDIUM)
      .padding(.leading, DSStyle.Spacers.SPACING_MEDIUM)
      .padding(.trailing, Layout.eagleBadgeWidth)

      backgroundImage
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(DSColor.surface)
    .overlay(alignment: .topTrailing) {
      eagleBadge
    }
    .clipShape(RoundedRectangle(cornerRadius: DSStyle.Sizes.CornerRadius.mediumLarge))
    .overlay(
      RoundedRectangle(cornerRadius: DSStyle.Sizes.CornerRadius.mediumLarge)
        .stroke(DSColor.outlineVariant, lineWidth: 1)
    )
    .dsShadow(DSShadow.card)
  }

  private var placeholderCard: some View {
    header(
      titleFont: DSTypography.Label.large,
      issuerColor: DSColor.onSurface,
      spacing: DSStyle.Spacers.SPACING_SMALL
    )
    .padding(Layout.placeholderContentInset)
    .frame(maxWidth: .infinity, minHeight: Layout.placeholderMinHeight, alignment: .topLeading)
    .background(DSColor.surfaceContainer)
    .clipShape(RoundedRectangle(cornerRadius: DSStyle.Sizes.CornerRadius.xLarge1))
    .overlay(
      RoundedRectangle(cornerRadius: DSStyle.Sizes.CornerRadius.xLarge1)
        .stroke(DSColor.outlineVariant, lineWidth: 1)
    )
    .dsShadow(DSShadow.card)
  }

  private func header(titleFont: Font, issuerColor: Color, spacing: CGFloat) -> some View {
    VStack(alignment: .leading, spacing: spacing) {
      Text(credentialTitle)
        .font(titleFont)
        .foregroundColor(DSColor.onSurface)
        .accessibilityIdentifier("credentialTitleView")

      if !issuer.isEmpty {
        Text(issuer)
          .font(DSTypography.Label.medium)
          .foregroundColor(issuerColor)
          .accessibilityIdentifier("credentialIssuerView")
      }
    }
  }

  private var eagleBadge: some View {
    Theme.shared.image.pidCardEagleImage
      .resizable()
      .scaledToFit()
      .frame(width: Layout.eagleSize, height: Layout.eagleSize)
      .frame(width: Layout.eagleBadgeWidth, height: Layout.eagleBadgeHeight)
      .offset(y: Layout.eagleBadgeTopOffset)
      .accessibilityHidden(true)
  }

  private var backgroundImage: some View {
    Color.clear
      .aspectRatio(Layout.backgroundImageAspectRatio, contentMode: .fit)
      .frame(maxWidth: .infinity)
      .overlay {
        Theme.shared.image.pidCardBackgroundImage
          .resizable()
          .scaledToFill()
      }
      .clipped()
      .accessibilityHidden(true)
  }
}
