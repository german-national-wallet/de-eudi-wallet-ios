//
//  PresentationErrorNoticeContent.swift
//  feature-presentation
//

import SwiftUI
import logic_ui
import logic_resources

struct PresentationErrorNoticeContent: View {
  struct Action {
    let title: LocalizableStringKey
    let trailingIcon: Image?
    let handler: () -> Void

    init(title: LocalizableStringKey, trailingIcon: Image? = nil, handler: @escaping () -> Void) {
      self.title = title
      self.trailingIcon = trailingIcon
      self.handler = handler
    }
  }

  let illustration: Image?
  let title: LocalizableStringKey
  let message: LocalizableStringKey
  let primary: Action
  let secondary: Action?
  let onClose: (() -> Void)?

  @AccessibilityFocusState private var isTitleFocused: Bool

  var body: some View {
    ContentScreenView(padding: 0, background: DSColor.background, backgroundIgnoresSafeArea: true) {
      ZStack(alignment: .topTrailing) {
        VStack(spacing: 0) {
          ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
              illustrationView

              VStack(alignment: .leading, spacing: DSStyle.Spacers.SPACING_MEDIUM) {
                DSTitleLabel(title)
                  .frame(maxWidth: .infinity, alignment: .leading)
                  .accessibilityAddTraits(.isHeader)
                  .accessibilityFocused($isTitleFocused)
                  .accessibilityIdentifier("presentationErrorNoticeTitle")

                DSBodyLabel(message, color: DSColor.onBackgroundVariant)
                  .fixedSize(horizontal: false, vertical: true)
              }
              .frame(maxWidth: .infinity, alignment: .leading)
              .padding(.horizontal, DSStyle.Spacers.SPACING_MEDIUM)
              .padding(.top, DSStyle.Spacers.SPACING_LARGE_MEDIUM)
              .padding(.bottom, DSStyle.Spacers.SPACING_MEDIUM)
            }
          }
          .ignoresSafeArea(edges: .top)

          VStack(spacing: DSStyle.Spacers.SPACING_SMALL) {
            DSPrimaryButton(title: primary.title.toString, trailingIcon: primary.trailingIcon, action: primary.handler)
              .accessibilityIdentifier("presentationErrorNoticePrimaryButton")

            if let secondary {
              DSSecondaryButton(
                title: secondary.title.toString,
                trailingIcon: secondary.trailingIcon,
                action: secondary.handler
              )
              .accessibilityIdentifier("presentationErrorNoticeSecondaryButton")
            }
          }
          .padding(.horizontal, DSStyle.Spacers.SPACING_MEDIUM)
          .padding(.top, DSStyle.Spacers.SPACING_SMALL)
          .padding(.bottom, DSStyle.Spacers.SPACING_LARGE)
        }

        if let onClose {
          closeButton(onClose)
        }
      }
    }
    .navigationBarBackButtonHidden()
    .onAppear {
      isTitleFocused = true
    }
  }

  @ViewBuilder private var illustrationView: some View {
    if let illustration {
      illustration
        .resizable()
        .scaledToFill()
        .frame(maxWidth: .infinity)
        .aspectRatio(1, contentMode: .fit)
        .clipped()
        .accessibilityHidden(true)
    }
  }

  private func closeButton(_ action: @escaping () -> Void) -> some View {
    Button(action: action) {
      Theme.shared.image.xmark
        .renderingMode(.template)
        .resizable()
        .scaledToFit()
        .frame(width: DSStyle.Sizes.Icons.xxLarge, height: DSStyle.Sizes.Icons.xxLarge)
        .foregroundColor(DSColor.onBackground)
        .padding(DSStyle.Spacers.SPACING_EXTRA_SMALL)
        .background(DSColor.background, in: Circle())
        .overlay(Circle().stroke(DSColor.outlineVariant))
        .iconButtonSlot()
    }
    .padding(.horizontal, DSStyle.Spacers.SPACING_MEDIUM)
    .padding(.bottom, DSStyle.Spacers.SPACING_MEDIUM)
    .accessibilitySortPriority(1)
    .accessibilityLabel(Text(LocalizableStringKey.globalCloseButtonA11y.toLocalizedStringKey))
    .accessibilityIdentifier("presentationErrorNoticeCloseButton")
  }
}
