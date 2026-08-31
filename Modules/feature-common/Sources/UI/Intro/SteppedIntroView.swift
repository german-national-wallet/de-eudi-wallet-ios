//
//  SteppedIntroView.swift
//  feature-common
//
//  Implemented from Figma "Design System EUDI Wallet App (extended M3)",
//  ContentIntro / Default variant (node 61410:21457).
//

import SwiftUI
import logic_ui

struct SteppedIntroView: View {
  let config: IntroConfig

  private var progress: (current: Int, total: Int)? {
    if case let .stepped(current, total) = config.style {
      return (current, total)
    }
    return nil
  }

  var body: some View {
    ContentScreenView(padding: 0, background: DSColor.background) {
      VStack(spacing: 0) {
        HeaderContentView(
          onBack: config.onBack,
          onClose: config.onClose,
          onHelp: config.onHelp,
          progress: progress
        )

        GeometryReader { proxy in
          let horizontalPadding: CGFloat = DSStyle.Spacers.SPACING_MEDIUM
          let availableWidth: CGFloat = proxy.size.width - horizontalPadding * 2
          let illustrationWidth: CGFloat = availableWidth * config.illustrationWidthFactor

          ScrollView {
            VStack(alignment: .leading, spacing: DSStyle.Spacers.SPACING_LARGE) {
              VStack(alignment: .leading, spacing: DSStyle.Spacers.SPACING_MEDIUM) {
                DSTitleLabel(config.title)
                  .if(config.titleAccessibilityId != nil) { view in
                    view.accessibilityIdentifier(config.titleAccessibilityId!)
                  }

                if let body = config.body {
                  DSBodyLabel(body)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
              }

              Spacer(minLength: DSStyle.Spacers.SPACING_MEDIUM)

              IntroEIDCardIllustration(
                image: config.illustration,
                width: illustrationWidth
              )
              Spacer(minLength: DSStyle.Spacers.SPACING_MEDIUM)

              if let bannerText = config.bannerText {
                IntroWarningBanner(text: bannerText)
              }
            }
            .padding(DSStyle.Spacers.SPACING_MEDIUM)
            .frame(minHeight: proxy.size.height, alignment: .top)
          }
        }

        IntroBottomActions(
          primary: config.primaryAction,
          secondary: config.secondaryAction
        )
      }
    }
  }
}

#if DEBUG
#Preview {
  SteppedIntroView(
    config: IntroConfig(
      style: .stepped(currentStep: 1, totalSteps: 4),
      title: "Hast du die 6-stellige Karten-PIN deines Ausweises schon festgelegt?",
      body: "Um den Vorgang abzuschließen, gehe zurück zum Dienst, von dem aus du die Identifizierung gestartet hast.",
      bannerText: "Um den Vorgang abzuschließen, gehe zurück zum Dienst, von dem aus du die Identifizierung gestartet hast.",
      primaryAction: .init(title: "Label", handler: {}),
      secondaryAction: .init(title: "Label", handler: {}),
      onBack: {},
      onHelp: {},
      onClose: {}
    )
  )
}
#endif
