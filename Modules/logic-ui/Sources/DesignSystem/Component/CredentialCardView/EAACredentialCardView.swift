//
//  EAACredentialCardView.swift
//  logic-ui
//

import SwiftUI
import logic_resources

public struct EAACredentialCardView: View {

  private enum Layout {
    /// The logo fills the brand panel, so this only sets how narrow that panel may become.
    static let logoMaxWidth: CGFloat = 80
    static let logoSidePadding: CGFloat = DSStyle.Spacers.SPACING_MEDIUM_SMALL
    static let brandPanelWidthRatio: CGFloat = 0.30
    static let brandPanelMinWidth: CGFloat = logoMaxWidth + logoSidePadding * 2
  }

  private var viewHeight: CGFloat = 60
  private var credentialTitle = String()
  private var issuer = String()
  private var backgroundColor = DSColor.colorPID
  private var backgroundImageURL = String()
  private var onViewData: (() -> Void)?
  private var logoURL: String?
  
  public init(
    viewHeight: CGFloat,
    credentialTitle: String,
    issuer: String = "",
    logoURL: String? = nil,
    backgroundColor: Color = DSColor.colorPID,
    backgroundImageURL: String = "",
    onViewData: (() -> Void)? = nil
  ) {
    self.viewHeight = viewHeight
    self.credentialTitle = credentialTitle
    self.issuer = issuer
    self.logoURL = logoURL
    self.backgroundColor = backgroundColor
    self.backgroundImageURL = backgroundImageURL
    self.onViewData = onViewData
  }

  /// The whole card acts as a button when an `onViewData` action is given, so that tapping
  /// anywhere on it triggers the action and it is exposed as a button to assistive technology.
  /// Without an action the card stays a plain view, leaving callers free to attach their own
  /// gesture.
  @ViewBuilder
  public var body: some View {
    if let onViewData {
      Button(action: onViewData) {
        card
      }
      .buttonStyle(.plain)
      .accessibilityIdentifier("eaaCredentialCardButton")
    } else {
      card
    }
  }

  private var card: some View {
    GeometryReader { geometry in
      let brandPanelWidth = max(
        geometry.size.width * Layout.brandPanelWidthRatio,
        Layout.brandPanelMinWidth
      )

      ZStack(alignment: .topLeading) {
        credentialInfo
          .frame(
            maxWidth: geometry.size.width - brandPanelWidth,
            maxHeight: .infinity,
            alignment: .topLeading
          )

        brandPanel(width: brandPanelWidth)
          .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
      }
    }
    .frame(height: viewHeight)
    .background(DSColor.surface)
    .clipShape(RoundedRectangle(cornerRadius: DSStyle.Sizes.CornerRadius.medium))
    .overlay(
      RoundedRectangle(cornerRadius: DSStyle.Sizes.CornerRadius.medium)
        .stroke(DSColor.outlineVariant, lineWidth: 1)
    )
    .clipped()
    .dsShadow(DSShadow.card)
  }

  // MARK: - Left: credential name + issuer

  private var credentialInfo: some View {
    VStack(alignment: .leading, spacing: DSStyle.Spacers.SPACING_EXTRA_SMALL) {
      Text(credentialTitle)
        .font(DSTypography.Body.large)
        .foregroundColor(DSColor.onSurface)
        .accessibilityIdentifier("eaaCredentialTitleView")

      if !issuer.isEmpty {
        Text(issuer)
          .font(DSTypography.Label.medium)
          .foregroundColor(DSColor.onSurfaceVariant)
          .accessibilityIdentifier("eaaCredentialIssuerView")
      }
    }
    .padding(DSStyle.Spacers.SPACING_MEDIUM)
  }

  // MARK: - Right: issuer brand region + logo

  private func brandPanel(width: CGFloat) -> some View {
    brandBackground
      .frame(width: width)
      .frame(maxHeight: .infinity)
      .clipped()
      .overlay {
        if let logoURL = logoURL, !logoURL.isEmpty {
          logo
        }
      }
  }

  @ViewBuilder
  private var brandBackground: some View {
      backgroundColor
  }

  private var logo: some View {
    AsyncImage(
      url: URL(string: logoURL ?? ""),
      transaction: Transaction(animation: .easeInOut(duration: 0.25))
    ) { phase in
      if case .success(let image) = phase {
        image
          .resizable()
          .scaledToFill()
      } else {
        Color.clear
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .clipped()
    .accessibilityIdentifier("eaaCredentialLogoView")
  }
}
