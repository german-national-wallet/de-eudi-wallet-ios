//
//  PresentationRejectedView.swift
//  feature-common
//

import logic_resources
import logic_ui
import SwiftUI

/// Terminal screen for a presentation the wallet refused on registration-certificate grounds.
///
/// Laid out like ``IllustratedNoticeView`` — full-bleed square illustration, then title and body,
/// with the actions pinned to the bottom — but with a close button instead of a back button, since
/// there is nothing to go back to, and a secondary action alongside the primary one.
public struct PresentationRejectedView: View {

  private let config: PresentationRejectedUiConfig
  private let onDismiss: () -> Void

  @State private var isRedirectDialogPresented = false

  public init(
    config: any UIConfigType,
    onDismiss: @escaping () -> Void
  ) {
    guard let config = config as? PresentationRejectedUiConfig else {
      fatalError("PresentationRejectedView:: Invalid configuration")
    }
    self.config = config
    self.onDismiss = onDismiss
  }

  public var body: some View {
    ContentScreenView(padding: .zero, background: DSColor.background) {
      ScrollView {
        VStack(alignment: .leading, spacing: 0) {
          illustration

          VStack(alignment: .leading, spacing: DSStyle.Spacers.SPACING_MEDIUM) {
            DSTitleLabel(config.title)
              .frame(maxWidth: .infinity, alignment: .leading)
              .accessibilityAddTraits(.isHeader)

            DSBodyLabel(config.message)
              .fixedSize(horizontal: false, vertical: true)
          }
          .frame(maxWidth: .infinity, alignment: .leading)
          .padding(.horizontal, DSStyle.Spacers.SPACING_MEDIUM)
          .padding(.top, DSStyle.Spacers.SPACING_LARGE)
        }
      }

      VStack(spacing: DSStyle.Spacers.SPACING_SMALL) {
        if config.canReport {
          DSPrimaryButton(
            title: config.primaryButtonTitle.toString,
            trailingIcon: Theme.shared.image.externalLink,
            action: onReport
          )

          DSSecondaryButton(title: config.secondaryButtonTitle.toString, action: onDismiss)
        } else {
          DSPrimaryButton(title: config.secondaryButtonTitle.toString, action: onDismiss)
        }
      }
      .padding(.horizontal, DSStyle.Spacers.SPACING_MEDIUM)
      .padding(.top, DSStyle.Spacers.SPACING_SMALL)
      .padding(.bottom, DSStyle.Spacers.SPACING_LARGE)
    }
    .ignoresSafeArea(edges: .top)
    .redirectConfirmationDialog(
      isPresented: $isRedirectDialogPresented,
      url: config.reportURI
    ) { url in
      UIApplication.shared.open(url)
    }
  }

  private func onReport() {
    isRedirectDialogPresented = true
  }

  /// Square illustration bleeding to the top edge, with the close button floating over it.
  @ViewBuilder private var illustration: some View {
    ZStack(alignment: .topTrailing) {
      Theme.shared.image.presentationAccessDenied
        .resizable()
        .scaledToFill()
        .frame(maxWidth: .infinity)
        .aspectRatio(1, contentMode: .fit)
        .clipped()
        .accessibilityHidden(true)

      Button(action: onDismiss) {
        Theme.shared.image.closeIcon
          .renderingMode(.template)
          .resizable()
          .scaledToFit()
          .frame(width: DSStyle.Sizes.Icons.large, height: DSStyle.Sizes.Icons.large)
          .foregroundColor(DSColor.onBackground)
          .padding(DSStyle.Spacers.SPACING_SMALL)
          .background(DSColor.secondaryContainer, in: Circle())
          .iconButtonSlot()
      }
      .padding(.horizontal, DSStyle.Spacers.SPACING_MEDIUM)
      .padding(.top, DSStyle.Spacers.SPACING_EXTRA_LARGE)
      .accessibilityLabel(Text(LocalizableStringKey.globalCloseButtonA11y.toLocalizedStringKey))
    }
  }
}
