//
//  IssuanceConsentView.swift
//  feature-issuance
//

import SwiftUI
import feature_common
import logic_ui
import logic_resources

struct IssuanceConsentView<Router: RouterHost>: View {

  @ObservedObject private var viewModel: IssuanceConsentViewModel<Router>
  @State private var showInfoSheet: Bool
  @State private var isShowingAllData: Bool

  private let collapsedClaimCount = 6

  init(with viewModel: IssuanceConsentViewModel<Router>) {
    self.viewModel = viewModel
    self.showInfoSheet = false
    self.isShowingAllData = false
  }

  private var consentItems: [ConsentItem] {
    viewModel.viewState.config.consentItems
  }

  private var visibleConsentItems: [ConsentItem] {
    isShowingAllData ? consentItems : Array(consentItems.prefix(collapsedClaimCount))
  }

  private var hasHiddenConsentItems: Bool {
    consentItems.count > collapsedClaimCount
  }

  var body: some View {
    ContentScreenView(padding: .zero) {
      HeaderContentView(
        onBack: viewModel.backButtonTapped,
        onClose: viewModel.closeButtonTapped,
        onHelp: { showInfoSheet = true },
        progress: (current: 1, total: 4)
      )

      ScrollView {
        VStack(alignment: .leading, spacing: DSStyle.Spacers.SPACING_LARGE_MEDIUM) {
          DSTitleLabel(.issuanceConsentViewTitle)
            .accessibilityIdentifier("issuanceConsentViewTitle")

          VStack(alignment: .leading, spacing: DSStyle.Spacers.SPACING_SMALL) {
            Text(.issuanceDigitalID)
              .font(DSTypography.Body.large)
              .foregroundColor(DSColor.onBackgroundVariant)
              .multilineTextAlignment(.leading)
              .fixedSize(horizontal: false, vertical: true)

            consentListView
          }

          pidIssuerView
        }
        .padding(.horizontal, DSStyle.Spacers.SPACING_MEDIUM)
        .padding(.top, DSStyle.Spacers.SPACING_SMALL)
        .padding(.bottom, DSStyle.Spacers.SPACING_LARGE)
      }
      .scrollIndicators(.hidden)

      bottomActions
    }
    .sheet(isPresented: $showInfoSheet) {
      BottomSheetView(
        title: LocalizableStringKey.whyIsThisDataNeededTitle.toString,
        message: LocalizableStringKey.whyIsThisDataNeededDescription.toString
      )
    }
    .centerDialog(
      isPresented: $viewModel.isRejectSheetOpen,
      icon: Theme.shared.image.infoCircle,
      title: .issuanceConsentRejectInfoTitle,
      subtitle: .issuanceConsentRejectInfoParagraph,
      buttons: [
        .init(
          title: .issuanceConsentRejectInfoPrimaryButtonTitle,
          role: .destructive,
          action: viewModel.rejectConfirmed
        ),
        .init(
          title: .reportProblem,
          role: .secondary,
          trailingIcon: Theme.shared.image.externalLink,
          action: viewModel.reportProblem
        ),
        .init(
          title: .globalCloseButton,
          role: .secondary,
          action: {}
        )
      ]
    )
  }

  private var consentListView: some View {
    VStack(alignment: .leading, spacing: DSStyle.Spacers.SPACING_SMALL) {
      VStack(alignment: .leading, spacing: DSStyle.Spacers.SPACING_EXTRA_SMALL) {
        ForEach(visibleConsentItems.indices, id: \.self) { index in
          BulletPointText(text: visibleConsentItems[index].title)
            .font(DSTypography.Label.large)
            .foregroundColor(DSColor.onSurface)
        }
      }

      if hasHiddenConsentItems {
        toggleDataButton
      }
    }
    .padding(DSStyle.Spacers.SPACING_MEDIUM_SMALL)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(DSColor.surfaceContainer)
    .clipShape(RoundedRectangle(cornerRadius: DSStyle.Sizes.CornerRadius.mediumLarge))
  }

  private var toggleDataButton: some View {
    Button(
      action: { isShowingAllData.toggle() },
      label: {
        HStack(spacing: DSStyle.Spacers.SPACING_SMALL) {
          (isShowingAllData ? Theme.shared.image.chevronUp : Theme.shared.image.chevronDown)
            .renderingMode(.template)
            .resizable()
            .scaledToFit()
            .frame(
              width: DSStyle.Sizes.Icons.small,
              height: DSStyle.Sizes.Icons.small
            )
            .foregroundColor(DSColor.onSecondaryContainer)
            .accessibilityHidden(true)

          Text(isShowingAllData
               ? .issuanceConsentViewShowLessDataButtonTitle
               : .issuanceConsentViewShowMoreDataButtonTitle)
            .font(DSTypography.Label.large)
            .fontWeight(DSStyle.FontWeight.medium_500)
            .foregroundColor(DSColor.onSecondaryContainer)
        }
        .padding(.horizontal, DSStyle.Spacers.SPACING_MEDIUM)
        .padding(.vertical, DSStyle.Spacers.SPACING_MEDIUM_SMALL)
        .contentShape(Rectangle())
      }
    )
    .accessibilityIdentifier("issuanceConsentViewToggleDataButton")
  }

  private var pidIssuerView: some View {
    VStack(alignment: .leading, spacing: DSStyle.Spacers.SPACING_SMALL) {
      DSTitleLabel(.issuedBy, font: DSTypography.Label.large, color: DSColor.onBackgroundVariant)

      HStack(spacing: DSStyle.Spacers.SPACING_SMALL) {
        Theme.shared.image.bdrLogo
          .clipShape(Circle())
          .overlay(
            Circle()
              .stroke(DSColor.surfaceContainerHighest, lineWidth: 1)
          )

        Text(verbatim: "Bundesdruckerei")
          .foregroundStyle(DSColor.onBackground)
          .font(DSTypography.Body.large)
      }
      .frame(maxWidth: .infinity, alignment: .leading)
    }
    .contentShape(Rectangle())
    .onTapGesture {
      viewModel.goToPidIssuer()
    }
  }

  private var bottomActions: some View {
    HStack(spacing: DSStyle.Spacers.SPACING_MEDIUM) {
      DSSecondaryButton(
        title: LocalizableStringKey.issuanceConsentViewSecondaryButtonTitle.toString,
        action: viewModel.rejectButtonTapped
      )
      .accessibilityIdentifier("issuanceConsentViewSecondaryButton")

      DSPrimaryButton(
        title: LocalizableStringKey.issuanceConsentViewPrimaryButtonTitle.toString,
        action: viewModel.doWork
      )
      .accessibilityIdentifier("issuanceConsentViewPrimaryButton")
    }
    .padding(.horizontal, DSStyle.Spacers.SPACING_MEDIUM)
    .padding(.top, DSStyle.Spacers.SPACING_SMALL)
    .padding(.bottom, DSStyle.Spacers.SPACING_LARGE)
  }
}
