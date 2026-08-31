//
//  IssuanceProcessOverviewView.swift
//  feature-issuance
//

import SwiftUI
import logic_ui
import logic_resources
import logic_core
import feature_common

private enum A11ySortPriority {
  static let title: Double = 50
  static let header: Double = 40
  static let steps: Double = 30
  static let privacyPolicy: Double = 20
  static let primaryButton: Double = 10
}

private struct PrivacyPolicyLink: Identifiable {
  let url: URL
  var id: String { url.absoluteString }
}

struct IssuanceProcessOverviewView<Router: RouterHost>: View {
  let router: Router
  let issuanceInteractor: IssuanceVerificationInteractor?
  var onBack: () -> Void = {}
  var onClose: () -> Void = {}
  var onContinue: () -> Void = {}

  @State private var isPinInfoSheetPresented = false
  @State private var privacyPolicyLink: PrivacyPolicyLink?

  private let badgeSize: CGFloat = 44

  private var steps: [LocalizableStringKey] {
    [
      .pidProcessOverviewList1,
      .pidProcessOverviewList2,
      .pidProcessOverviewList3,
      .pidProcessOverviewList4
    ]
  }

  var body: some View {
    ContentScreenView(padding: .zero) {
      HeaderContentView(
        onBack: onBack,
        onClose: onClose,
        onHelp: { isPinInfoSheetPresented = true }
      )
      .accessibilitySortPriority(A11ySortPriority.header)

      ScrollView {
        VStack(alignment: .leading, spacing: DSStyle.Spacers.SPACING_LARGE) {
          DSTitleLabel(.pidProcessOverviewTitle)
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilitySortPriority(A11ySortPriority.title)

          stepList
            .accessibilitySortPriority(A11ySortPriority.steps)
        }
        .padding(.horizontal, DSStyle.Spacers.SPACING_MEDIUM)
        .padding(.top, DSStyle.Spacers.SPACING_LARGE)
      }

      VStack(spacing: DSStyle.Spacers.SPACING_SMALL) {
        privacyPolicyButton
          .accessibilitySortPriority(A11ySortPriority.privacyPolicy)

        DSPrimaryButton(
          title: LocalizableStringKey.pidProcessOverviewPrimButton.toString,
          trailingIcon: Theme.shared.image.arrowForward,
          action: onContinue
        )
        .accessibilityIdentifier("processOverviewContinueButton")
        .accessibilitySortPriority(A11ySortPriority.primaryButton)
      }
      .padding(.horizontal, DSStyle.Spacers.SPACING_MEDIUM)
      .padding(.top, DSStyle.Spacers.SPACING_SMALL)
      .padding(.bottom, DSStyle.Spacers.SPACING_LARGE)
    }
    .sheet(isPresented: $isPinInfoSheetPresented) {
      PINIssuanceInfoView(
        onFindNearbyBurgerAmt: openBurgeramtWebpage,
        router: router,
        isSheetPresented: $isPinInfoSheetPresented,
        issuanceInteractor: issuanceInteractor
      )
      .background(DSColor.background)
      .clipShape(RoundedCorner(radius: 20, corners: [.topLeft, .topRight]))
      .ignoresSafeArea()
      .presentationDetents([.fraction(0.7)])
    }
    .sheet(item: $privacyPolicyLink) { link in
      SafariView(url: link.url)
        .ignoresSafeArea()
    }
  }

  @ViewBuilder private var stepList: some View {
    VStack(alignment: .leading, spacing: DSStyle.Spacers.SPACING_SMALL) {
      ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
        HStack(spacing: DSStyle.Spacers.SPACING_MEDIUM_SMALL) {
          stepBadge(number: index + 1)

          DSBodyLabel(step)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .accessibilityElement(children: .combine)

        if index < steps.count - 1 {
          stepConnector
        }
      }
    }
  }

  private func stepBadge(number: Int) -> some View {
    Text(verbatim: "\(number)")
      .font(DSTypography.Label.large)
      .fontWeight(DSStyle.FontWeight.medium_500)
      .foregroundColor(DSColor.onPrimaryContainer)
      .frame(width: badgeSize, height: badgeSize)
      .background(DSColor.surfaceContainer)
      .clipShape(Circle())
  }

  private var stepConnector: some View {
    Rectangle()
      .fill(DSColor.surfaceContainerHighest)
      .frame(width: 1, height: DSStyle.Spacers.SPACING_LARGE)
      .frame(width: badgeSize, alignment: .center)
      .accessibilityHidden(true)
  }

  private var privacyPolicyButton: some View {
    Button(
      action: {
        guard let url = AppEnvironment.privacyPolicyLink else { return }
        privacyPolicyLink = PrivacyPolicyLink(url: url)
      },
      label: {
        HStack(spacing: DSStyle.Spacers.SPACING_SMALL) {
          Theme.shared.image.infoCircle
            .renderingMode(.template)
            .resizable()
            .scaledToFit()
            .frame(
              width: DSStyle.Sizes.Icons.small,
              height: DSStyle.Sizes.Icons.small
            )
            .foregroundColor(DSColor.onBackground)
            .accessibilityHidden(true)

          Text(.pidProcessOverviewTertButton)
            .font(DSTypography.Label.large)
            .fontWeight(DSStyle.FontWeight.medium_500)
            .foregroundColor(DSColor.onBackground)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, DSStyle.Spacers.SPACING_MEDIUM_SMALL)
        .contentShape(Rectangle())
      }
    )
    .accessibilityIdentifier("processOverviewPrivacyPolicyButton")
  }

  private func openBurgeramtWebpage() {
    if let url = AppEnvironment.burgeramtServiceLink {
      UIApplication.shared.open(url)
    }
  }
}
