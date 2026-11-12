//
//  DSBannerView.swift
//  logic-ui
//
//  Created by Pankaj Sachdeva on 09.10.26.
//

import SwiftUI
import logic_resources

public struct DSBannerView: View {

  public enum Style {
    case info
    case warning
  }

  private enum Constants {
    static let iconSize: CGFloat = 18
    static let accentWidth: CGFloat = 4
    static let accentInset: CGFloat = 3
  }

  private let style: Style
  private let headline: LocalizableStringKey?
  private let message: LocalizableStringKey
  private let messageLineLimit: Int?

  public init(
    style: Style,
    headline: LocalizableStringKey? = nil,
    message: LocalizableStringKey,
    messageLineLimit: Int? = nil
  ) {
    self.style = style
    self.headline = headline
    self.message = message
    self.messageLineLimit = messageLineLimit
  }

  public var body: some View {
    HStack(alignment: .top, spacing: DSStyle.Spacers.SPACING_SMALL) {
      icon
        .renderingMode(.template)
        .resizable()
        .scaledToFit()
        .frame(width: Constants.iconSize, height: Constants.iconSize)
        .foregroundStyle(DSColor.onSurfaceVariant)
        .frame(width: DSStyle.Sizes.Icons.large, height: DSStyle.Sizes.Icons.large)
        .accessibilityHidden(true)
      VStack(alignment: .leading, spacing: DSStyle.Spacers.SPACING_SMALL) {
        if let headline {
          Text(headline)
            .font(DSTypography.Body.large)
            .fontWeight(DSStyle.FontWeight.medium_500)
            .foregroundStyle(DSColor.onBackground)
        }
        Text(message)
          .font(DSTypography.Body.large)
          .foregroundStyle(DSColor.onSurface)
          .lineLimit(messageLineLimit)
      }
      .frame(maxWidth: .infinity, alignment: .leading)
    }
    .padding(DSStyle.Spacers.SPACING_MEDIUM)
    .background(
      RoundedRectangle(cornerRadius: DSStyle.Sizes.CornerRadius.medium)
        .fill(containerColor)
    )
    .overlay(alignment: .leading) {
      AccentShape()
        .fill(accentColor)
        .frame(width: Constants.accentWidth)
        .padding(.vertical, Constants.accentInset)
        .accessibilityHidden(true)
    }
    .accessibilityElement(children: .combine)
  }

  private var icon: Image {
    switch style {
    case .info: Theme.shared.image.activityInformation
    case .warning: Theme.shared.image.activityWarning
    }
  }

  private var containerColor: Color {
    switch style {
    case .info: DSColor.surfaceContainer
    case .warning: DSColor.warningContainer
    }
  }

  private var accentColor: Color {
    switch style {
    case .info: DSColor.onBackground
    case .warning: DSColor.warningContainerAccent
    }
  }
}

private struct AccentShape: Shape {

  private let taper: CGFloat = 9

  func path(in rect: CGRect) -> Path {
    var path = Path()
    path.move(to: CGPoint(x: rect.minX, y: rect.minY + taper))
    path.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.minY), control: CGPoint(x: rect.minX, y: rect.minY + 2))
    path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
    path.addQuadCurve(to: CGPoint(x: rect.minX, y: rect.maxY - taper), control: CGPoint(x: rect.minX, y: rect.maxY - 2))
    path.closeSubpath()
    return path
  }
}
