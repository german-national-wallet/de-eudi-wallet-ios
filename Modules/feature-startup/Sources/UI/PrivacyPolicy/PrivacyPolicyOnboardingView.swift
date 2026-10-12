//
//  PrivacyPolicyOnboardingView.swift
//  feature-startup
//

import SwiftUI
import logic_ui
import logic_resources
import feature_common

struct PrivacyPolicyOnboardingView<Router: RouterHost>: View {

  @ObservedObject private var viewModel: PrivacyPolicyOnboardingViewModel<Router>

  init(with viewModel: PrivacyPolicyOnboardingViewModel<Router>) {
    self.viewModel = viewModel
  }

  var body: some View {
    VStack(spacing: 0) {
      HeaderContentView(onBack: viewModel.onBackTapped)

      ScrollView {
        VStack(alignment: .leading, spacing: DSStyle.Spacers.SPACING_MEDIUM) {
          Text(.appOnboardingPolicyIntroTitle)
            .font(DSTypography.Title.large)
            .foregroundStyle(DSColor.onBackground)
            .accessibilityAddTraits(.isHeader)
            .accessibilityIdentifier("policyTitle")

          Text(.appOnboardingPolicyIntroParagraph)
            .font(DSTypography.Body.large)
            .foregroundStyle(DSColor.onBackgroundVariant)

          summaryBox
        }
        .padding(.horizontal, DSStyle.Spacers.SPACING_MEDIUM)
        .padding(.top, DSStyle.Spacers.SPACING_LARGE)
      }

      bottomBar
    }
    .background(DSColor.background)
    .sheet(
      isPresented: Binding(
        get: { viewModel.viewState.isPolicyPresented },
        set: { viewModel.setPolicyPresented($0) }
      )
    ) {
      if let url = viewModel.viewState.presentedURL {
        SafariView(url: url)
          .ignoresSafeArea()
      }
    }
  }

  private var summaryBox: some View {
    VStack(alignment: .leading, spacing: DSStyle.Spacers.SPACING_SMALL) {
      OnboardingBulletRow(
        icon: Theme.shared.image.check,
        iconColor: DSColor.onSurfaceVariant,
        text: .appOnboardingPolicyIntroList1,
        textColor: DSColor.onSurface
      )
      OnboardingBulletRow(
        icon: Theme.shared.image.check,
        iconColor: DSColor.onSurfaceVariant,
        text: .appOnboardingPolicyIntroList2,
        textColor: DSColor.onSurface
      )
      OnboardingBulletRow(
        icon: Theme.shared.image.check,
        iconColor: DSColor.onSurfaceVariant,
        text: .appOnboardingPolicyIntroList3,
        textColor: DSColor.onSurface
      )
    }
    .padding(.vertical, DSStyle.Spacers.SPACING_MEDIUM_LARGE)
    .padding(.leading, DSStyle.Spacers.SPACING_MEDIUM)
    .padding(.trailing, DSStyle.Spacers.SPACING_MEDIUM_LARGE)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(
      RoundedRectangle(cornerRadius: DSStyle.Sizes.CornerRadius.xLarge1)
        .fill(DSColor.surfaceContainer)
    )
  }

  private var bottomBar: some View {
    VStack(spacing: DSStyle.Spacers.SPACING_SMALL) {
      Button(action: viewModel.onReadPolicyTapped) {
        HStack(spacing: DSStyle.Spacers.SPACING_SMALL) {
          Image(systemName: "info.circle")
            .font(.system(size: 18))
            .accessibilityHidden(true)
          Text(.appOnboardingPolicyIntroTertiaryButton)
            .font(DSTypography.Label.large)
            .fontWeight(DSStyle.FontWeight.medium_500)
        }
        .foregroundStyle(DSColor.onBackground)
        .frame(maxWidth: .infinity)
      }
      .buttonStyle(DSButton.TextButtonStyle())
      .disabled(viewModel.privacyPolicyURL == nil)
      .accessibilityIdentifier("policyReadPrivacyButton")

      OnboardingConsentCheckbox(
        isOn: viewModel.viewState.hasAgreed,
        label: .appOnboardingPolicyIntroCheckboxLabelDev,
        checkboxAccessibilityIdentifier: "policyConsentCheckbox",
        onToggle: viewModel.toggleAgreement,
        onLinkTapped: viewModel.onLinkTapped
      )

      DSPrimaryButton(
        title: LocalizableStringKey.appOnboardingPolicyIntroPrimButton.toString
      ) {
        viewModel.onPrimaryButtonTapped()
      }
      .disabled(!viewModel.viewState.hasAgreed)
      .keyboardShortcut(.defaultAction)
      .accessibilityIdentifier("policyPrimaryButton")
    }
    .padding(.horizontal, DSStyle.Spacers.SPACING_MEDIUM)
    .padding(.top, DSStyle.Spacers.SPACING_SMALL)
    .padding(.bottom, DSStyle.Spacers.SPACING_LARGE)
    .background(DSColor.background.ignoresSafeArea(edges: .bottom))
  }
}
