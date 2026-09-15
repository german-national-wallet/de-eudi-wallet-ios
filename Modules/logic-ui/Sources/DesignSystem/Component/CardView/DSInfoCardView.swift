//
//  DSInfoCardView.swift
//  logic-ui
//

import SwiftUI
import logic_resources

public struct DSInfoCardView: View {

  public enum ImagePlacement {
    case aboveMessage
    case belowMessage
  }

  private let title: LocalizableStringKey?
  private let message: LocalizableStringKey
  private let image: Image?
  private let customIllustration: AnyView?
  private let imagePlacement: ImagePlacement
  private let imageWidth: CGFloat?
  private let buttonTitle: LocalizableStringKey?
  private let buttonAction: (() -> Void)?
  private let accessibilityId: String?

  public init(
    title: LocalizableStringKey? = nil,
    message: LocalizableStringKey,
    image: Image? = nil,
    imagePlacement: ImagePlacement = .belowMessage,
    imageWidth: CGFloat? = nil,
    buttonTitle: LocalizableStringKey? = nil,
    buttonAction: (() -> Void)? = nil,
    accessibilityId: String? = nil
  ) {
    self.title = title
    self.message = message
    self.image = image
    self.customIllustration = nil
    self.imagePlacement = imagePlacement
    self.imageWidth = imageWidth
    self.buttonTitle = buttonTitle
    self.buttonAction = buttonAction
    self.accessibilityId = accessibilityId
  }

  public init<Illustration: View>(
    title: LocalizableStringKey? = nil,
    message: LocalizableStringKey,
    imagePlacement: ImagePlacement = .belowMessage,
    buttonTitle: LocalizableStringKey? = nil,
    buttonAction: (() -> Void)? = nil,
    accessibilityId: String? = nil,
    @ViewBuilder illustration: () -> Illustration
  ) {
    self.title = title
    self.message = message
    self.image = nil
    self.customIllustration = AnyView(illustration())
    self.imagePlacement = imagePlacement
    self.imageWidth = nil
    self.buttonTitle = buttonTitle
    self.buttonAction = buttonAction
    self.accessibilityId = accessibilityId
  }

  public var body: some View {
    VStack(alignment: .leading, spacing: DSStyle.Spacers.SPACING_MEDIUM_SMALL) {
      if let title {
        DSSubTitleLabel(title, font: DSTypography.Title.medium)
      }

      if imagePlacement == .aboveMessage {
        illustration
      }

      Text(message.toAttributedString)
        .font(DSTypography.Body.large)
        .foregroundColor(DSColor.onSurface)
        .multilineTextAlignment(.leading)
        .fixedSize(horizontal: false, vertical: true)
        .frame(maxWidth: .infinity, alignment: .leading)

      if imagePlacement == .belowMessage {
        illustration
      }

      if let buttonTitle, let buttonAction {
        DSSecondaryButton(title: buttonTitle.toString, action: buttonAction)
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(DSStyle.Spacers.SPACING_MEDIUM)
    .background(
      RoundedRectangle(cornerRadius: DSStyle.Sizes.CornerRadius.xLarge1)
        .fill(DSColor.surfaceContainer)
    )
    .if(accessibilityId != nil) { view in
      view.accessibilityIdentifier(accessibilityId!)
    }
  }

  /// `imageWidth` narrows and centres the illustration; without it the image
  /// fills the card, as the credential artwork does in the design.
  @ViewBuilder private var illustration: some View {
    if let customIllustration {
      customIllustration
        .accessibilityHidden(true)
    } else if let image {
      image
        .resizable()
        .scaledToFit()
        .frame(maxWidth: imageWidth ?? .infinity)
        .frame(maxWidth: .infinity, alignment: imageWidth == nil ? .leading : .center)
        .accessibilityHidden(true)
    }
  }
}
