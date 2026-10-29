//
//  ActivityDetailView.swift
//  feature-dashboard
//
//  Created by Pankaj Sachdeva on 02.10.26.
//

import SwiftUI
import logic_ui
import logic_core
import logic_resources

private enum Constants {
  static let cardRadius = DSStyle.Sizes.CornerRadius.xLarge1
  static let cardBottomRadius = DSStyle.Sizes.CornerRadius.mediumLarge
  static let leadingSize: CGFloat = 40
  static let leadingIconSize: CGFloat = 20
  static let trailingIconSize: CGFloat = 24
  static let logoSize: CGFloat = 68
  static let rowHeight: CGFloat = 38
  static let credentialCardHeight: CGFloat = 120
  static let cardHeaderHeight: CGFloat = 78
  static let brandPanelWidth: CGFloat = 109
  static let brandLogoWidth: CGFloat = 80
  static let brandLogoHeight: CGFloat = 60
}

struct ActivityDetailView<Router: RouterHost>: View {

  @ObservedObject private var viewModel: ActivityDetailViewModel<Router>

  init(with viewModel: ActivityDetailViewModel<Router>) {
    self.viewModel = viewModel
  }

  var body: some View {
    ContentScreenView(padding: .zero) {
      HeaderContentView(onBack: viewModel.backButtonTapped, onHelp: viewModel.onHelpTapped)

      ScrollView {
        content
          .frame(maxWidth: .infinity, alignment: .leading)
          .padding(.horizontal, DSStyle.Spacers.SPACING_MEDIUM)
          .padding(.top, DSStyle.Spacers.SPACING_MEDIUM_LARGE)
          .padding(.bottom, DSStyle.Spacers.SPACING_LARGE)
      }
    }
    .task {
      await viewModel.onAppear()
    }
    .centerDialog(
      isPresented: Binding(
        get: { viewModel.viewState.isDeleteConfirmationPresented },
        set: { if !$0 { viewModel.onDeleteDismissed() } }
      ),
      icon: Theme.shared.image.warningOutline,
      iconColor: DSColor.error,
      title: .activitiesDetailDeleteTitle,
      buttons: [
        CustomAlertDialogConfig(title: .activitiesDeleteAllConfirm, role: .destructive) {
          Task { await viewModel.onDeleteConfirmed() }
        },
        CustomAlertDialogConfig(title: .cancelButton, role: .secondary) {}
      ]
    )
  }

  @ViewBuilder
  private var content: some View {
    if let presentation = viewModel.viewState.detail?.presentation {
      PresentationDetailContent(
        presentation: presentation,
        onLinkSelected: viewModel.onLinkSelected,
        onDelete: viewModel.onDeleteRequested
      )
    } else if let issuance = viewModel.viewState.detail?.issuance {
      IssuanceDetailContent(
        issuance: issuance,
        onLinkSelected: viewModel.onLinkSelected,
        onDelete: viewModel.onDeleteRequested
      )
    } else if let detail = viewModel.viewState.detail {
      VStack(alignment: .leading, spacing: DSStyle.Spacers.SPACING_MEDIUM) {
        Text(.custom(detail.title))
          .font(DSTypography.Title.large)
          .foregroundStyle(DSColor.onBackground)
          .accessibilityAddTraits(.isHeader)
          .accessibilityIdentifier("activityDetailTitle")

        ForEach(detail.rows) { row in
          VStack(alignment: .leading, spacing: DSStyle.Spacers.SPACING_EXTRA_SMALL) {
            Text(row.title)
              .font(DSTypography.Label.large)
              .foregroundStyle(DSColor.onBackgroundVariant)
            Text(.custom(row.value))
              .font(DSTypography.Body.large)
              .foregroundStyle(DSColor.onBackground)
              .textSelection(.enabled)
          }
          .frame(maxWidth: .infinity, alignment: .leading)
          .accessibilityElement(children: .combine)
        }

        DeleteActivityButton(onDelete: viewModel.onDeleteRequested)
      }
    } else if viewModel.viewState.isLoading {
      ProgressView()
        .frame(maxWidth: .infinity)
    }
  }
}

/// The layout for a presentation: the service, the shared credentials with their data, and the service's links.
private struct PresentationDetailContent: View {

  let presentation: ActivityPresentationDetailUIModel
  let onLinkSelected: (ActivityServiceLinkUIModel) -> Void
  let onDelete: () -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: DSStyle.Spacers.SPACING_LARGE) {
      Text(.custom(presentation.serviceName))
        .font(DSTypography.Title.large)
        .foregroundStyle(DSColor.onBackground)
        .accessibilityAddTraits(.isHeader)
        .accessibilityIdentifier("activityDetailTitle")

      VStack(alignment: .leading, spacing: DSStyle.Spacers.SPACING_SMALL) {
        LabeledValue(label: presentation.dateLabel, value: presentation.date)
        if let failure = presentation.failureMessage {
          ActivityBannerView(style: .warning, message: failure)
            .accessibilityIdentifier("activityDetailFailureBanner")
        }
      }

      if let purpose = presentation.purpose {
        LabeledValue(label: .activitiesLogDetailPurpose, value: purpose)
      }

      if !presentation.credentials.isEmpty {
        VStack(alignment: .leading, spacing: DSStyle.Spacers.SPACING_SMALL) {
          Text(presentation.credentialsLabel)
            .font(DSTypography.Label.large)
            .foregroundStyle(DSColor.onBackgroundVariant)
          VStack(alignment: .leading, spacing: DSStyle.Spacers.SPACING_LARGE_MEDIUM) {
            ForEach(presentation.credentials) { credential in
              credentialCard(credential)
            }
          }
        }
      }

      if !presentation.services.isEmpty {
        serviceInformation
      }

      actions
    }
  }

  private func credentialCard(_ credential: ActivitySharedCredentialUIModel) -> some View {
    VStack(alignment: .leading, spacing: DSStyle.Spacers.SPACING_MEDIUM) {
      HStack(alignment: .center) {
        VStack(alignment: .leading, spacing: 2) {
          Text(.custom(credential.name))
            .font(DSTypography.Body.large)
            .foregroundStyle(DSColor.onSurface)
            .strikethrough(!credential.isShared)
          if let issuer = credential.issuerName {
            Text(.custom(issuer))
              .font(DSTypography.Label.large)
              .foregroundStyle(DSColor.onSurfaceVariant)
          }
        }
        Spacer()
        if credential.isPid {
          Theme.shared.image.pidCardEagleImage
            .resizable()
            .scaledToFit()
            .frame(width: Constants.logoSize, height: Constants.logoSize)
            .accessibilityHidden(true)
        }
      }
      .padding(DSStyle.Spacers.SPACING_MEDIUM)
      .padding(.trailing, credential.hasBrandPanel ? Constants.brandPanelWidth : 0)
      .frame(maxWidth: .infinity, minHeight: Constants.cardHeaderHeight, alignment: .leading)
      .overlay(alignment: .trailing) {
        if credential.hasBrandPanel {
          brandPanel(credential)
        }
      }
      .clipped()
      .overlay(alignment: .bottom) {
        Rectangle().fill(DSColor.outlineVariant).frame(height: 1)
      }

      if credential.isShared {
        valuesSummary(credential)
      }

      claimList(credential)
    }
    .padding(.bottom, DSStyle.Spacers.SPACING_MEDIUM)
    .background(DSColor.surface)
    .clipShape(
      UnevenRoundedRectangle(
        topLeadingRadius: Constants.cardRadius,
        bottomLeadingRadius: Constants.cardBottomRadius,
        bottomTrailingRadius: Constants.cardBottomRadius,
        topTrailingRadius: Constants.cardRadius
      )
    )
    .overlay(
      UnevenRoundedRectangle(
        topLeadingRadius: Constants.cardRadius,
        bottomLeadingRadius: Constants.cardBottomRadius,
        bottomTrailingRadius: Constants.cardBottomRadius,
        topTrailingRadius: Constants.cardRadius
      )
      .stroke(DSColor.outlineVariant, lineWidth: 1)
    )
    .accessibilityElement(children: .contain)
  }

  private func brandPanel(_ credential: ActivitySharedCredentialUIModel) -> some View {
    DSColor.getBackgroundColorForCredential(display: credential.display, id: credential.id)
      .frame(width: Constants.brandPanelWidth)
      .frame(maxHeight: .infinity)
      .overlay(alignment: .top) {
        if let logo = credential.display?.first?.logo?.urlString {
          RemoteImageView(urlString: logo)
            .frame(width: Constants.brandLogoWidth, height: Constants.brandLogoHeight)
            .padding(.top, DSStyle.Spacers.SPACING_SMALL)
        }
      }
      .accessibilityHidden(true)
  }

  private func valuesSummary(_ credential: ActivitySharedCredentialUIModel) -> some View {
    Text(credential.valuesSummary)
      .font(DSTypography.Body.medium)
      .fontWeight(DSStyle.FontWeight.medium_500)
      .foregroundStyle(DSColor.onBackground)
      .padding(.horizontal, DSStyle.Spacers.SPACING_MEDIUM)
      .padding(.vertical, DSStyle.Spacers.SPACING_SMALL)
      .background(
        RoundedRectangle(cornerRadius: DSStyle.Sizes.CornerRadius.small).fill(DSColor.surfaceContainer)
      )
      .padding(.horizontal, DSStyle.Spacers.SPACING_MEDIUM_SMALL)
  }

  private func claimList(_ credential: ActivitySharedCredentialUIModel) -> some View {
    VStack(spacing: .zero) {
      ForEach(Array(credential.sharedClaims.enumerated()), id: \.offset) { index, claim in
        Text(.custom(claim))
          .font(DSTypography.Body.large)
          .foregroundStyle(DSColor.onSurface)
          .strikethrough(!credential.isShared)
          .frame(maxWidth: .infinity, minHeight: Constants.rowHeight, alignment: .leading)
          .overlay(alignment: .bottom) {
            if index < credential.sharedClaims.count - 1 {
              Rectangle().fill(DSColor.tertiaryContainer).frame(height: 1)
            }
          }
      }
    }
    .padding(.horizontal, DSStyle.Spacers.SPACING_MEDIUM)
  }

  private var serviceInformation: some View {
    ServiceLinksSection(
      title: .activitiesDetailServiceInformation,
      links: presentation.services,
      onSelect: onLinkSelected
    )
  }

  @ViewBuilder
  private var actions: some View {
    VStack(spacing: DSStyle.Spacers.SPACING_SMALL) {
      if let reportLink = presentation.reportLink {
        DSSecondaryButton(
          title: LocalizableStringKey.activitiesDetailReportSuspicion.toString,
          trailingIcon: Theme.shared.image.externalLink
        ) {
          onLinkSelected(reportLink)
        }
        .accessibilityIdentifier("activityDetailReportButton")
      }
      DeleteActivityButton(onDelete: onDelete)
    }
  }
}

private struct IssuanceDetailContent: View {

  let issuance: ActivityIssuanceDetailUIModel
  let onLinkSelected: (ActivityServiceLinkUIModel) -> Void
  let onDelete: () -> Void

  @State private var showsClaims = false

  var body: some View {
    VStack(alignment: .leading, spacing: DSStyle.Spacers.SPACING_LARGE) {
      Text(.custom(issuance.title))
        .font(DSTypography.Title.large)
        .foregroundStyle(DSColor.onBackground)
        .accessibilityAddTraits(.isHeader)
        .accessibilityIdentifier("activityDetailTitle")

      LabeledValue(label: issuance.dateLabel, value: issuance.date)

      VStack(alignment: .leading, spacing: DSStyle.Spacers.SPACING_SMALL) {
        Text(issuance.cardLabel)
          .font(DSTypography.Label.large)
          .foregroundStyle(DSColor.onBackgroundVariant)
        card
      }

      if !issuance.issuerLinks.isEmpty {
        ServiceLinksSection(
          title: .activitiesDetailIssuerInformation,
          links: issuance.issuerLinks,
          onSelect: onLinkSelected
        )
      }

      DeleteActivityButton(onDelete: onDelete)
    }
    .sheet(isPresented: $showsClaims) {
      CredentialClaimsSheetView(
        title: issuance.card.title,
        issuer: issuance.card.issuer,
        issuerImageUrl: logoURL,
        logo: issuance.card.isPid ? Theme.shared.image.pidCardEagleImage : nil,
        claims: issuance.card.claimNames,
        onClose: { showsClaims = false }
      )
    }
  }

  private var logoURL: String {
    issuance.card.display?.first?.logo?.urlString ?? issuance.card.issuerLogoURL ?? ""
  }

  @ViewBuilder
  private var card: some View {
    let card = issuance.card
    let onViewData: (() -> Void)? = card.claimNames.isEmpty ? nil : { showsClaims = true }
    if card.isPid {
      PIDCredentialCardView(credentialTitle: card.title, issuer: card.issuer, onViewData: onViewData)
        .accessibilityIdentifier("activityDetailCredentialCard")
    } else {
      EAACredentialCardView(
        viewHeight: Constants.credentialCardHeight,
        credentialTitle: card.title,
        issuer: card.issuer,
        logoURL: logoURL,
        backgroundColor: DSColor.getBackgroundColorForCredential(display: card.display, id: card.documentId ?? card.title),
        backgroundImageURL: card.backgroundImageURL,
        onViewData: onViewData
      )
      .accessibilityIdentifier("activityDetailCredentialCard")
    }
  }
}

private struct ServiceLinksSection: View {

  let title: LocalizableStringKey
  let links: [ActivityServiceLinkUIModel]
  let onSelect: (ActivityServiceLinkUIModel) -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: DSStyle.Spacers.SPACING_SMALL) {
      Text(title)
        .font(DSTypography.Label.large)
        .foregroundStyle(DSColor.onBackgroundVariant)
      VStack(spacing: .zero) {
        ForEach(links) { link in
          if link.url != nil {
            Button {
              onSelect(link)
            } label: {
              row(link, isOpenable: true)
            }
            .buttonStyle(.plain)
          } else {
            row(link, isOpenable: false)
          }
        }
      }
    }
  }

  private func row(_ service: ActivityServiceLinkUIModel, isOpenable: Bool) -> some View {
    HStack(spacing: DSStyle.Spacers.SPACING_MEDIUM) {
      service.icon
        .renderingMode(.template)
        .resizable()
        .scaledToFit()
        .frame(width: Constants.leadingIconSize, height: Constants.leadingIconSize)
        .foregroundStyle(DSColor.onBackground)
        .frame(width: Constants.leadingSize, height: Constants.leadingSize)
        .background(DSColor.surfaceContainerLow, in: Circle())
        .accessibilityHidden(true)

      VStack(alignment: .leading, spacing: .zero) {
        Text(service.title)
          .font(DSTypography.Label.large)
          .foregroundStyle(DSColor.onBackgroundVariant)
        Text(.custom(service.value))
          .font(DSTypography.Body.large)
          .foregroundStyle(DSColor.onBackground)
          .lineLimit(1)
          .truncationMode(.tail)
      }
      .frame(maxWidth: .infinity, alignment: .leading)

      if isOpenable {
        Theme.shared.image.externalLink
          .renderingMode(.template)
          .resizable()
          .scaledToFit()
          .frame(width: Constants.trailingIconSize, height: Constants.trailingIconSize)
          .foregroundStyle(DSColor.onBackground)
          .accessibilityHidden(true)
      }
    }
    .padding(.vertical, DSStyle.Spacers.SPACING_EXTRA_SMALL)
    .frame(minHeight: 64)
    .contentShape(Rectangle())
    .accessibilityElement(children: .combine)
  }
}

private struct DeleteActivityButton: View {

  let onDelete: () -> Void

  var body: some View {
    Button(action: onDelete) {
      Text(.activitiesDetailDeleteActivity)
        .font(DSTypography.Label.large)
        .fontWeight(DSStyle.FontWeight.medium_500)
        .foregroundStyle(DSColor.errorOutline)
        .frame(maxWidth: .infinity, minHeight: 48)
    }
    .accessibilityIdentifier("activityDetailDeleteButton")
  }
}

private extension ActivityServiceLinkUIModel {
  var icon: Image {
    switch kind {
    case .support: Theme.shared.image.activitySupport
    case .dataPolicy: Theme.shared.image.activityDataPolicy
    case .website: Theme.shared.image.activityWebsite
    }
  }
}

private struct LabeledValue: View {

  let label: LocalizableStringKey
  let value: String

  var body: some View {
    VStack(alignment: .leading, spacing: DSStyle.Spacers.SPACING_SMALL) {
      Text(label)
        .font(DSTypography.Label.large)
        .foregroundStyle(DSColor.onBackgroundVariant)
      Text(.custom(value))
        .font(DSTypography.Body.large)
        .foregroundStyle(DSColor.onBackground)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .accessibilityElement(children: .combine)
  }
}

private extension ActivityCredentialCardUIModel {
  // The background image for the app's language, as the dashboard card picks it
  var backgroundImageURL: String {
    let language = Locale.current.language.languageCode?.identifier
    let localized = display?.first { display in
      String(display.localeIdentifier?.split(separator: "-").first ?? "") == language
    }
    return localized?.backgroundImageURL ?? ""
  }
}

private extension ActivitySharedCredentialUIModel {
  var hasBrandPanel: Bool {
    !isPid && display?.first.map { $0.backgroundColor != nil || $0.logo?.urlString != nil } == true
  }
}
