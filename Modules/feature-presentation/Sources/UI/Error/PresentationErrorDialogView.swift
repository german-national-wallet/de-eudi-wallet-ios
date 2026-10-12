//
//  PresentationErrorDialogView.swift
//  feature-presentation
//

import SwiftUI
import logic_ui
import logic_resources
import feature_common

struct PresentationErrorDialogView: View {
  let config: PresentationErrorDialogConfig
  let onAction: (PresentationErrorDialogConfig.Action) -> Void

  @State private var isTraceIdCopied = false
  @AccessibilityFocusState private var isTitleFocused: Bool

  var body: some View {
    ZStack {
      Color.black.opacity(0.4)
        .ignoresSafeArea()

      VStack(spacing: DSStyle.Spacers.SPACING_MEDIUM) {
        (config.titleIcon ?? Theme.shared.image.errorIndicator)
          .resizable()
          .scaledToFit()
          .frame(width: DSStyle.Sizes.Icons.large, height: DSStyle.Sizes.Icons.large)
          .foregroundStyle(DSColor.error)
          .padding(.bottom, DSStyle.Spacers.SPACING_EXTRA_SMALL)
          .accessibilityHidden(true)

        Text(config.title.toString)
          .font(DSTypography.Headline.small)
          .foregroundStyle(DSColor.onSurface)
          .multilineTextAlignment(.center)
          .fixedSize(horizontal: false, vertical: true)
          .accessibilityAddTraits(.isHeader)
          .accessibilityFocused($isTitleFocused)

        Text(config.message.toString)
          .font(DSTypography.Body.large)
          .foregroundStyle(DSColor.onSurfaceVariant)
          .multilineTextAlignment(.center)
          .fixedSize(horizontal: false, vertical: true)

        VStack(alignment: .leading, spacing: DSStyle.Spacers.SPACING_MEDIUM) {
          if let errorCode = config.errorCode {
            diagnosticRow(label: .globalErrorCodeTitle, value: errorCode)
          }
          traceRow
        }
        .frame(maxWidth: .infinity, alignment: .leading)

        VStack(spacing: DSStyle.Spacers.SPACING_MEDIUM_SMALL) {
          DSPrimaryButton(title: config.primary.title.toString) {
            onAction(config.primary.action)
          }
          .accessibilityIdentifier("presentationErrorPrimaryButton")

          if let secondary = config.secondary {
            DSSecondaryButton(title: secondary.title.toString) {
              onAction(secondary.action)
            }
            .accessibilityIdentifier("presentationErrorSecondaryButton")
          }
        }
        .padding(.top, DSStyle.Spacers.SPACING_SMALL)
      }
      .padding(DSStyle.Spacers.SPACING_LARGE_MEDIUM)
      .frame(maxWidth: 320)
      .background(DSColor.background)
      .clipShape(RoundedRectangle(cornerRadius: DSStyle.Sizes.CornerRadius.large))
      .shadow(radius: 20)
      .padding(DSStyle.Spacers.SPACING_LARGE)
      .accessibilityAddTraits(.isModal)
    }
    .onAppear {
      isTitleFocused = true
    }
  }

  private var traceRow: some View {
    HStack(spacing: DSStyle.Spacers.SPACING_SMALL) {
      diagnosticRow(label: .globalTraceIdTitle, value: config.traceId)
      Button(action: copyTraceId) {
        Image(systemName: isTraceIdCopied ? "checkmark" : "doc.on.doc")
          .font(.system(size: DSStyle.Sizes.Icons.medium))
          .foregroundStyle(isTraceIdCopied ? DSColor.primary : DSColor.onSurfaceVariant)
          .iconButtonSlot()
      }
      .accessibilityLabel(Text(LocalizableStringKey.settingsRevocationKeyCopyButton.toLocalizedStringKey))
      .accessibilityIdentifier("presentationErrorCopyTraceIdButton")
    }
  }

  private func diagnosticRow(label: LocalizableStringKey, value: String) -> some View {
    VStack(alignment: .leading, spacing: DSStyle.Spacers.SPACING_EXTRA_SMALL) {
      Text(label.toString)
        .foregroundStyle(DSColor.onSurfaceVariant)
      Text(value)
        .foregroundStyle(DSColor.onSurface)
        .textSelection(.enabled)
    }
    .font(DSTypography.Body.medium)
    .frame(maxWidth: .infinity, alignment: .leading)
    .accessibilityElement(children: .combine)
  }

  private func copyTraceId() {
    UIPasteboard.general.string = config.traceId
    isTraceIdCopied = true
    UIAccessibility.post(
      notification: .announcement,
      argument: LocalizableStringKey.settingsRevocationKeyCopiedButton.toString
    )
    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
      isTraceIdCopied = false
    }
  }
}
#if DEBUG
#Preview("Generic") {
  CustomFonts().loadFonts()
  return PresentationErrorDialogView(
    config: PresentationErrorHandlerImpl.genericDialog(
      traceId: "12344ds1234ff12sd312445235fs234545d",
      originator: .featureDashboardModule(.dashboard)
    ),
    onAction: { _ in }
  )
}

#Preview("Generic + code") {
  CustomFonts().loadFonts()
  return PresentationErrorDialogView(
    config: PresentationErrorHandlerImpl.genericDialog(
      traceId: "12344ds1234ff12sd312445235fs234545d",
      originator: .featureDashboardModule(.dashboard),
      errorCode: "SOMETHING_ELSE"
    ),
    onAction: { _ in }
  )
}
#endif
