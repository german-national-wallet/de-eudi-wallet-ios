//
//  DashboardOverviewHeader.swift
//  feature-dashboard
//
//  Created by Pankaj Sachdeva on 04.11.26.
//

import SwiftUI
import logic_ui
import logic_resources

private enum Constants {
  static let headerHeight: CGFloat = 48
  static let wordmarkSize = CGSize(width: 84, height: 25.63)
}

struct DashboardOverviewHeader: View {
  var onHelp: () -> Void = {
    // Intentionally a no-op until the help center link is delivered.
  }

  var body: some View {
    HStack {
      Theme.shared.image.dYouWordmark
        .resizable()
        .scaledToFit()
        .frame(width: Constants.wordmarkSize.width, height: Constants.wordmarkSize.height)
        .foregroundColor(DSColor.onBackground)
        .accessibilityLabel(Text(verbatim: "d-you"))
        .accessibilityAddTraits(.isHeader)

      Spacer()

      Button(action: onHelp) {
        Theme.shared.image.help
          .resizable()
          .scaledToFit()
          .frame(width: DSStyle.Sizes.Icons.large, height: DSStyle.Sizes.Icons.large)
          .foregroundColor(DSColor.onBackground)
          .iconButtonSlot()
      }
      .accessibilityLabel(Text(LocalizableStringKey.headerAccessibilityHelp.toLocalizedStringKey))
      .accessibilityIdentifier("dashboardHelpButton")
    }
    .frame(height: Constants.headerHeight)
    .padding(.horizontal, DSStyle.Spacers.SPACING_MEDIUM)
  }
}
