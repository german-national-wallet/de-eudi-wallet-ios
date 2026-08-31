//
//  IntroComponents.swift
//  feature-common
//

import SwiftUI
import logic_ui

struct IntroWarningBanner: View {
  let text: String

  var body: some View {
    HStack(alignment: .top, spacing: DSStyle.Spacers.SPACING_SMALL) {
      Theme.shared.image.exclamationmarkCircle
        .resizable()
        .scaledToFit()
        .frame(width: DSIconSize.small, height: DSIconSize.small)
        .foregroundColor(DSColor.onSurface)

      Text(text)
        .font(DSTypography.Body.large)
        .foregroundColor(DSColor.onSurface)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    .padding(DSStyle.Spacers.SPACING_MEDIUM)
    .frame(maxWidth: .infinity)
    .background(DSColor.surfaceContainer)
    .clipShape(RoundedRectangle(cornerRadius: DSStyle.Sizes.CornerRadius.medium))
  }
}

// MARK: - Bottom action buttons (filled primary + outlined secondary, stacked)

struct IntroBottomActions: View {
  let primary: IntroConfig.Action?
  let secondary: IntroConfig.Action?

  var body: some View {
    if primary != nil || secondary != nil {
      VStack(spacing: DSStyle.Spacers.SPACING_SMALL) {
        if let primary {
          IntroPrimaryArrowButton(title: primary.title, action: primary.handler)
            .if(primary.accessibilityId != nil) { view in
              view.accessibilityIdentifier(primary.accessibilityId!)
            }
        }
        if let secondary {
          DSSecondaryButton(title: secondary.title, action: secondary.handler)
            .if(secondary.accessibilityId != nil) { view in
              view.accessibilityIdentifier(secondary.accessibilityId!)
            }
        }
      }
      .padding(.horizontal, DSStyle.Spacers.SPACING_MEDIUM)
      .padding(.top, DSStyle.Spacers.SPACING_SMALL)
      .padding(.bottom, DSStyle.Spacers.SPACING_LARGE)
      .background(DSColor.background)
    }
  }
}

/// Filled primary button matching `DSPrimaryButton` styling, with a trailing arrow icon.
struct IntroPrimaryArrowButton: View {
  @Environment(\.isEnabled) private var isEnabled

  let title: String
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      HStack(spacing: DSStyle.Spacers.SPACING_SMALL) {
        Text(title)
          .font(DSTypography.Label.large)
          .fontWeight(DSStyle.FontWeight.medium_500)
          .foregroundColor(isEnabled ? DSColor.onBackground : DSColor.onBackground.opacity(0.38))
          .multilineTextAlignment(.center)
          .lineLimit(DSStyle.LineLimits.two)
          .minimumScaleFactor(0.8)
          .fixedSize(horizontal: false, vertical: true)

        Theme.shared.image.arrowForward
          .resizable()
          .scaledToFit()
          .frame(width: DSIconSize.small, height: DSIconSize.small)
          .foregroundColor(isEnabled ? DSColor.onBackground : DSColor.onBackground.opacity(0.38))
      }
    }
    .buttonStyle(
      DSButton.FilledPressedButtonStyle(
        outlineColor: DSColor.primaryOutline,
        pressedBackgroundColor: DSColor.primaryContainer.opacity(0.36),
        defaultBackgroundColor: DSColor.primaryContainer,
        borderWidth: 1
      )
    )
  }
}

// MARK: - Illustrations
//
// These use the closest existing `ImageManager` assets. The final Figma
// illustrations aren't exported yet (Variant2 is marked "ILLUSTRATION WIP"),
// so if dedicated assets are added later, just point these at the new
// `Theme.shared.image.<name>`.

/// Work-in-progress illustration frame (Figma node 62342:23171).
struct IntroIllustrationWIP: View {
  var image: Image?

  var body: some View {
    (image ?? Theme.shared.image.workInProgessLockIcon)
      .resizable()
      .scaledToFit()
      .padding(DSStyle.Spacers.SPACING_LARGE)
      .frame(maxWidth: .infinity)
      .frame(height: 184)
      .background(DSColor.surfaceContainer)
      .clipShape(RoundedRectangle(cornerRadius: DSStyle.Sizes.CornerRadius.xLarge1))
  }
}

/// eID card + card-PIN illustration (Figma node 61410:21462).
///
/// `width` is the resolved point width (computed by the caller from a fraction
/// of the available width). Height follows the image's aspect ratio. When nil,
/// the image uses its natural size.
struct IntroEIDCardIllustration: View {
  var image: Image?
  var width: CGFloat?

  var body: some View {
    (image ?? Theme.shared.image.ausweisPinAndCard)
      .resizable()
      .scaledToFit()
      .frame(width: width)
      .frame(maxWidth: .infinity)
  }
}
