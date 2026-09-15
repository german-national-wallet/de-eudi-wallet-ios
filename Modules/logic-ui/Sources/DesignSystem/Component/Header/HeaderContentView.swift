//
//  HeaderContentView.swift
//  logic-ui
//

import SwiftUI
import logic_resources

public struct HeaderContentView: View {
  let onBack: (() -> Void)?
  let onClose: (() -> Void)?
  let onHelp: (() -> Void)?
  let progress: (current: Int, total: Int)?

  private let headerActionRowHeight: CGFloat = 48

  private let headerActionRowInset: CGFloat = 10

  private let currentStepFill: CGFloat = 0.5

  private let fillAnimationDuration: TimeInterval = 1.0

  @State private var hasFilledCurrentStep = false

  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  public init(
    onBack: (() -> Void)? = nil,
    onClose: (() -> Void)? = nil,
    onHelp: (() -> Void)? = nil,
    progress: (current: Int, total: Int)? = nil
  ) {
    self.onBack = onBack
    self.onClose = onClose
    self.onHelp = onHelp
    self.progress = progress
  }

  public var body: some View {
    VStack(spacing: DSStyle.Spacers.SPACING_EXTRA_SMALL) {
      HStack(spacing: DSStyle.Spacers.SPACING_SMALL) {
        if let onBack = onBack {
          Button(action: { onBack() }, label: {
            Theme.shared.image.arrowBackIcon
              .iconButtonSlot()
          })
          .accessibilityLabel(Text(LocalizableStringKey.globalBackButtonA11y.toLocalizedStringKey))
          .accessibilityIdentifier("headerBackButton")
        }

        Spacer()

        if let onHelp = onHelp {
          Button(action: { onHelp() }, label: {
            Theme.shared.image.help
              .resizable()
              .scaledToFit()
              .frame(width: DSStyle.Sizes.Icons.large, height: DSStyle.Sizes.Icons.large)
              .foregroundColor(DSColor.onBackground)
              .iconButtonSlot()
          })
          .accessibilityLabel(Text(LocalizableStringKey.headerAccessibilityHelp.toLocalizedStringKey))
          .accessibilityIdentifier("headerHelpButton")
        }

        if let onClose = onClose {
          Button(action: { onClose() }, label: {
            Theme.shared.image.xmark
              .iconButtonSlot()
          })
          .accessibilityLabel(Text(LocalizableStringKey.globalCloseButtonA11y.toLocalizedStringKey))
          .accessibilityIdentifier("headerCloseButton")
        }
      }
      .padding(.horizontal, headerActionRowInset)
      .frame(height: headerActionRowHeight)

      if let progress = progress {
        HStack(spacing: DSStyle.Spacers.SPACING_SMALL) {
          ForEach(0..<max(progress.total, 1), id: \.self) { index in
            GeometryReader { proxy in
              ZStack(alignment: .leading) {
                Capsule()
                  .fill(DSColor.outlineVariant)

                Capsule()
                  .fill(DSColor.onSurface)
                  .frame(width: proxy.size.width * fillFraction(for: index, progress: progress))
              }
            }
            .frame(height: DSStyle.Spacers.SPACING_EXTRA_SMALL)
            .frame(maxWidth: .infinity)
          }
        }
        .onAppear {
          guard !reduceMotion else {
            hasFilledCurrentStep = true
            return
          }
          withAnimation(.easeInOut(duration: fillAnimationDuration)) {
            hasFilledCurrentStep = true
          }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
          Text(
            LocalizableStringKey.headerAccessibilityProgress(
              ["\(progress.current)", "\(max(progress.total, 1))"]
            ).toLocalizedStringKey
          )
        )
        .padding(.horizontal, DSStyle.Spacers.SPACING_MEDIUM)
      }
    }
    .padding(.top, DSStyle.Spacers.SPACING_MEDIUM)
  }

  private func fillFraction(for index: Int, progress: (current: Int, total: Int)) -> CGFloat {
    let currentIndex = progress.current - 1

    if index < currentIndex {
      return 1
    }

    if index == currentIndex {
      return hasFilledCurrentStep ? currentStepFill : 0
    }

    return 0
  }
}
