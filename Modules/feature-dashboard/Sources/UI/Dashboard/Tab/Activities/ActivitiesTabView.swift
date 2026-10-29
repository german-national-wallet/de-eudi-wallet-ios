/*
 * Copyright (c) 2023 European Commission
 *
 * Licensed under the EUPL, Version 1.2 or - as soon they will be approved by the European
 * Commission - subsequent versions of the EUPL (the "Licence"); You may not use this work
 * except in compliance with the Licence.
 *
 * You may obtain a copy of the Licence at:
 * https://joinup.ec.europa.eu/software/page/eupl
 *
 * Unless required by applicable law or agreed to in writing, software distributed under
 * the Licence is distributed on an "AS IS" basis, WITHOUT WARRANTIES OR CONDITIONS OF
 * ANY KIND, either express or implied. See the Licence for the specific language
 * governing permissions and limitations under the Licence.
 */
import Foundation
import logic_ui
import logic_resources

private enum Constants {
  static let rowMinHeight: CGFloat = 60
  static let leadingSize: CGFloat = 40
  static let trailingIconSize: CGFloat = 24
  static let pidLogoSize: CGFloat = 39
  static let credentialLogoInset: CGFloat = 8
  static let headerHeight: CGFloat = 48
  static let headerTrailingPadding: CGFloat = 10
}

struct ActivitiesTabView<Router: RouterHost>: View {

  @ObservedObject private var viewModel: ActivitiesTabViewModel<Router>

  init(with viewModel: ActivitiesTabViewModel<Router>) {
    self.viewModel = viewModel
  }

  var body: some View {
    ContentScreenView(padding: .zero) {
      header(
        showsMenu: !viewModel.viewState.sections.isEmpty,
        onHelp: viewModel.onHelpTapped,
        onDeleteAll: viewModel.onDeleteAllRequested
      )
      ScrollView {
        content(
          viewState: viewModel.viewState,
          onSelect: viewModel.onActivitySelected,
          onHowToUse: viewModel.onHowToUseTapped
        )
          .padding(.top, DSStyle.Spacers.SPACING_MEDIUM_LARGE)
      }
    }
    .task {
      await viewModel.onAppear()
    }
    .centerDialog(
      isPresented: Binding(
        get: { viewModel.viewState.isDeleteAllConfirmationPresented },
        set: { if !$0 { viewModel.onDeleteAllDismissed() } }
      ),
      icon: Theme.shared.image.warningOutline,
      iconColor: DSColor.error,
      title: .activitiesDeleteAllTitle,
      buttons: [
        CustomAlertDialogConfig(title: .activitiesDeleteAllConfirm, role: .destructive) {
          Task { await viewModel.onDeleteAllConfirmed() }
        },
        CustomAlertDialogConfig(title: .cancelButton, role: .secondary) {}
      ]
    )
  }
}

@MainActor
@ViewBuilder
private func header(showsMenu: Bool, onHelp: @escaping () -> Void, onDeleteAll: @escaping () -> Void) -> some View {
  HStack(spacing: DSStyle.Spacers.SPACING_SMALL) {
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
    .accessibilityIdentifier("activitiesHelpButton")
    if showsMenu {
      Menu {
        Button(role: .destructive, action: onDeleteAll) {
          Text(.activitiesDeleteAllEntries)
        }
      } label: {
        Image(systemName: "ellipsis")
          .rotationEffect(.degrees(90))
          .font(.system(size: 20, weight: .medium))
          .foregroundStyle(DSColor.onBackground)
          .frame(width: Constants.headerHeight, height: Constants.headerHeight)
          .contentShape(Rectangle())
      }
      .accessibilityLabel(Text(.globalMenu))
      .accessibilityIdentifier("activitiesMenuButton")
    }
  }
  .frame(height: Constants.headerHeight)
  .padding(.trailing, Constants.headerTrailingPadding)
}

@MainActor
@ViewBuilder
private func content(
  viewState: ActivitiesTabViewState,
  onSelect: @escaping (ActivityListItemUIModel) -> Void,
  onHowToUse: @escaping () -> Void
) -> some View {
  VStack(alignment: .leading, spacing: DSStyle.Spacers.SPACING_MEDIUM) {
    Text(.activitiesOverviewTitle)
      .font(DSTypography.Title.large)
      .foregroundStyle(DSColor.onBackground)
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(.horizontal, DSStyle.Spacers.SPACING_MEDIUM)
      .accessibilityAddTraits(.isHeader)
      .accessibilityIdentifier("activitiesTitle")

    if viewState.isLoading {
      ProgressView()
        .frame(maxWidth: .infinity)
    } else if viewState.sections.isEmpty {
      emptyView(onHowToUse: onHowToUse)
        .padding(.horizontal, DSStyle.Spacers.SPACING_MEDIUM)
    } else {
      VStack(alignment: .leading, spacing: DSStyle.Spacers.SPACING_LARGE_MEDIUM) {
        ForEach(viewState.sections) { section in
          sectionView(section, onSelect: onSelect)
        }
      }
    }
  }
  .padding(.bottom, DSStyle.Spacers.SPACING_LARGE_MEDIUM)
}

@MainActor
private func emptyView(onHowToUse: @escaping () -> Void) -> some View {
  VStack(spacing: DSStyle.Spacers.SPACING_MEDIUM) {
    ActivityBannerView(
      style: .info,
      headline: .activitiesOverviewEmptyHeadline,
      message: .activitiesOverviewEmptyParagraph
    )
    .accessibilityIdentifier("activitiesEmpty")

    DSSecondaryButton(
      title: LocalizableStringKey.activitiesOverviewHowToUseButton([LocalizableStringKey.appName.toString]).toString,
      trailingIcon: Theme.shared.image.externalLink
    ) {
      onHowToUse()
    }
    .accessibilityIdentifier("activitiesHowToUseButton")
  }
}

@MainActor
@ViewBuilder
private func sectionView(
  _ section: ActivitySectionUIModel,
  onSelect: @escaping (ActivityListItemUIModel) -> Void
) -> some View {
  VStack(alignment: .leading, spacing: DSStyle.Spacers.SPACING_SMALL) {
    Text(section.category.title())
      .font(DSTypography.Label.large)
      .foregroundStyle(DSColor.onBackgroundVariant)
      .padding(.horizontal, DSStyle.Spacers.SPACING_MEDIUM)
      .accessibilityAddTraits(.isHeader)

    VStack(spacing: .zero) {
      ForEach(section.items) { item in
        Button {
          onSelect(item)
        } label: {
          row(item)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("activityItem")
      }
    }
  }
}

@MainActor
@ViewBuilder
private func row(_ item: ActivityListItemUIModel) -> some View {
  HStack(spacing: DSStyle.Spacers.SPACING_MEDIUM) {
    leading(item.leading)
      .accessibilityHidden(true)

    VStack(alignment: .leading, spacing: .zero) {
      Text(.custom(item.title))
        .font(DSTypography.Body.large)
        .foregroundStyle(DSColor.onBackground)
      Text(.custom(item.subtitle))
        .font(DSTypography.Body.medium)
        .fontWeight(DSStyle.FontWeight.medium_500)
        .foregroundStyle(item.isCompleted ? DSColor.onBackgroundVariant : DSColor.error)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .multilineTextAlignment(.leading)

    Theme.shared.image.arrowForward
      .renderingMode(.template)
      .resizable()
      .scaledToFit()
      .frame(width: Constants.trailingIconSize, height: Constants.trailingIconSize)
      .foregroundStyle(DSColor.onBackground)
      .accessibilityHidden(true)
  }
  .padding(.horizontal, DSStyle.Spacers.SPACING_MEDIUM)
  .padding(.vertical, DSStyle.Spacers.SPACING_SMALL)
  .frame(minHeight: Constants.rowMinHeight)
  .contentShape(Rectangle())
  .accessibilityElement(children: .combine)
}

@MainActor
@ViewBuilder
private func leading(_ leading: ActivityLeadingUIModel) -> some View {
  switch leading {
  case .pidLogo:
    Theme.shared.image.pidCardEagleImage
      .resizable()
      .scaledToFit()
      .frame(width: Constants.pidLogoSize, height: Constants.pidLogoSize)
      .frame(width: Constants.leadingSize, height: Constants.leadingSize)
      .background(DSColor.background, in: Circle())
  case .logo(let logo, let initials):
    AsyncImage(url: logo.url) { phase in
      if let image = phase.image {
        if let hex = logo.backgroundHex, !hex.isEmpty {
          image
            .resizable()
            .scaledToFit()
            .padding(Constants.credentialLogoInset)
            .frame(width: Constants.leadingSize, height: Constants.leadingSize)
            .background(Color(hex: hex))
            .clipShape(Circle())
        } else {
          image
            .resizable()
            .scaledToFit()
            .frame(width: Constants.leadingSize, height: Constants.leadingSize)
            .background(DSColor.background)
            .clipShape(Circle())
        }
      } else {
        initialsView(initials)
      }
    }
  case .initials(let initials):
    initialsView(initials)
  }
}

@MainActor
private func initialsView(_ initials: String) -> some View {
  Text(.custom(initials))
    .font(DSTypography.Label.large)
    .foregroundStyle(DSColor.onPrimaryContainer)
    .frame(width: Constants.leadingSize, height: Constants.leadingSize)
    .background(DSColor.surfaceContainerHigh, in: Circle())
}
