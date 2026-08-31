//
//  PIDCredentialCardView.swift
//  feature-dashboard
//

import SwiftUI
import logic_resources
import logic_ui

// Complete card view for the Dashboard PID credential.
public struct PIDCredentialCardView: View {
  private var viewHeight: CGFloat = 120
  private var credentialTitle = String()
  private var additionalDescription = String()
  private var backgroundColor = DSColor.colorPID

  public init(
    viewHeight: CGFloat,
    credentialTitle: String,
    additionalDescription: String = "",
    backgroundColor: Color = DSColor.colorPID
  ) {
    self.viewHeight = viewHeight
    self.credentialTitle = credentialTitle
    self.additionalDescription = additionalDescription
    self.backgroundColor = backgroundColor
  }

  public var body: some View {
    RoundedRectangle(cornerRadius: DSStyle.Sizes.CornerRadius.medium)
      .fill(backgroundColor)
      .border(DSColor.outlineVariant, width: 1)
      .frame(height: viewHeight)
      .overlay(
        ZStack(alignment: .trailing) {
          Theme.shared.image.deEagleWingCroppedImage
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .trailing)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
      )
      .overlay(alignment: .topLeading) {
        VStack(alignment: .leading, spacing: DSStyle.Spacers.SPACING_SMALL) {
          Text(credentialTitle)
            .font(DSTypography.Title.medium)
            .foregroundColor(DSColor.onColorPID)
            .accessibilityIdentifier("credentialTitleView")

          Text(additionalDescription)
            .font(DSTypography.Body.medium)
            .foregroundColor(DSColor.onColorPID)

          Spacer()

          HStack {
            Spacer()

            Theme.shared.image.infoCircleImage
              .resizable()
              .frame(width: DSStyle.Spacers.SPACING_LARGE_MEDIUM, height: DSStyle.Spacers.SPACING_LARGE_MEDIUM)
              .padding(DSStyle.Spacers.SPACING_SMALL)
              .accessibilityIdentifier("digitalPIDTitleInfoButton")
          }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
      }
      .clipShape(RoundedRectangle(cornerRadius: DSStyle.Spacers.SPACING_MEDIUM_SMALL))
      .overlay(
        RoundedRectangle(cornerRadius: DSStyle.Spacers.SPACING_MEDIUM_SMALL)
          .stroke(DSColor.outlineVariant, lineWidth: 1)
      )
      .clipped()
  }
}
