//
//  IllustratedIntroView.swift
//  feature-common
//

import SwiftUI
import logic_ui

public struct IllustratedIntroView: View {
  let config: IntroConfig
  let errorConfig: ContentErrorView.Config?

  public init(config: IntroConfig, errorConfig: ContentErrorView.Config? = nil) {
    self.config = config
    self.errorConfig = errorConfig
  }

  public var body: some View {
    ContentScreenView(padding: 0, errorConfig: errorConfig, background: DSColor.background) {
      VStack(spacing: 0) {
        HeaderContentView(
          onBack: config.onBack,
          onClose: config.onClose,
          onHelp: config.onHelp
        )

        ScrollView {
          VStack(alignment: .leading, spacing: DSStyle.Spacers.SPACING_MEDIUM) {
            IntroIllustrationWIP(image: config.illustration)
              .padding(.bottom, DSStyle.Spacers.SPACING_SMALL)

            DSTitleLabel(config.title)
              .if(config.titleAccessibilityId != nil) { view in
                view.accessibilityIdentifier(config.titleAccessibilityId!)
              }

            if let body = config.body {
              DSBodyLabel(body, color: DSColor.onBackgroundVariant)
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            if let bannerText = config.bannerText {
              IntroWarningBanner(text: bannerText)
                .padding(.top, DSStyle.Spacers.SPACING_SMALL)
            }
          }
          .padding(DSStyle.Spacers.SPACING_MEDIUM)
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
  IllustratedIntroView(
    config: IntroConfig(
      style: .illustrated,
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
