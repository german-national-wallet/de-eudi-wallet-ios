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
import SwiftUI
import logic_ui
import logic_resources
import feature_common

private enum Constants {
  static let rowHeight: CGFloat = 48
  static let iconSlotSize: CGFloat = 28
  static let iconSize: CGFloat = 18
}

struct SettingsTabView<Router: RouterHost>: View {

  @ObservedObject private var viewModel: SettingsTabViewModel<Router>

  init(with viewModel: SettingsTabViewModel<Router>) {
    self.viewModel = viewModel
  }

  var body: some View {
    ContentScreenView(padding: .zero) {
      ScrollView {
        content(viewState: viewModel.viewState)
          .padding(.horizontal, DSStyle.Spacers.SPACING_MEDIUM)
          .padding(.top, DSStyle.Spacers.SPACING_LARGE_MEDIUM)
      }
    }
    .sheet(
      item: Binding(
        get: { viewModel.viewState.presentedWebLink },
        set: { if $0 == nil { viewModel.dismissWebLink() } }
      )
    ) { link in
      SafariView(url: link.url)
        .ignoresSafeArea()
    }
  }
}

@MainActor
@ViewBuilder
private func content(viewState: SettingsTabViewState) -> some View {
  VStack(alignment: .leading, spacing: DSStyle.Spacers.SPACING_MEDIUM) {
    Text(.settingsOverviewTitle)
      .font(DSTypography.Title.large)
      .foregroundStyle(DSColor.onBackground)
      .frame(maxWidth: .infinity, alignment: .leading)
      .accessibilityAddTraits(.isHeader)
      .accessibilityIdentifier("settingsTitle")

    ForEach(Array(viewState.sections.enumerated()), id: \.element.id) { index, section in
      sectionView(section, logsUrl: viewState.logsUrl)
      if index < viewState.sections.count - 1 {
        Divider()
          .overlay(DSColor.outlineVariant)
      }
    }

    Text(.custom(viewState.appVersion))
      .font(DSTypography.Body.medium)
      .foregroundStyle(DSColor.onBackground)
      .frame(maxWidth: .infinity, alignment: .center)
      .accessibilityIdentifier("settingsAppVersion")
  }
  .padding(.bottom, DSStyle.Spacers.SPACING_LARGE_MEDIUM)
}

@MainActor
@ViewBuilder
private func sectionView(_ section: SettingsTabSectionUIModel, logsUrl: URL?) -> some View {
  VStack(alignment: .leading, spacing: DSStyle.Spacers.SPACING_EXTRA_SMALL) {
    if let title = section.title {
      Text(title)
        .font(DSTypography.Label.large)
        .foregroundStyle(DSColor.onBackgroundVariant)
        .accessibilityAddTraits(.isHeader)
    }
    VStack(spacing: .zero) {
      ForEach(section.items) { item in
        if item.isShareLink {
          if let logsUrl {
            ShareLink(item: logsUrl) {
              row(item)
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier(item.id)
          }
        } else {
          rowButton(item)
        }
      }
    }
  }
  .accessibilityIdentifier(section.id)
}

@MainActor
@ViewBuilder
private func rowButton(_ item: SettingsTabItemUIModel) -> some View {
  Button(action: item.action) {
    row(item)
  }
  .buttonStyle(.plain)
  .accessibilityIdentifier(item.id)
}

@MainActor
@ViewBuilder
private func row(_ item: SettingsTabItemUIModel) -> some View {
  HStack(spacing: DSStyle.Spacers.SPACING_MEDIUM_SMALL) {
    if let leadingIcon = item.leadingIcon {
      icon(leadingIcon)
        .accessibilityHidden(true)
    }

    Text(item.title)
      .font(DSTypography.Label.large)
      .foregroundStyle(DSColor.onBackground)
      .frame(maxWidth: .infinity, alignment: .leading)
      .multilineTextAlignment(.leading)

    icon(
      item.trailingIcon == .externalLink
      ? Theme.shared.image.externalLink
      : Theme.shared.image.arrowForward
    )
    .accessibilityHidden(true)
  }
  .frame(minHeight: Constants.rowHeight)
  .contentShape(Rectangle())
  .accessibilityElement(children: .combine)
  .accessibilityAddTraits(.isButton)
}

@MainActor
@ViewBuilder
private func icon(_ image: Image) -> some View {
  image
    .renderingMode(.template)
    .resizable()
    .scaledToFit()
    .frame(width: Constants.iconSize, height: Constants.iconSize)
    .frame(width: Constants.iconSlotSize, height: Constants.iconSlotSize)
    .foregroundStyle(DSColor.onBackground)
}

#Preview {
  let viewState = SettingsTabViewState(
    sections: [
      .init(
        items: [
          .init(
            title: .settingsOverviewListSupport,
            leadingIcon: Theme.shared.image.help,
            action: {}()
          )
        ]
      ),
      .init(
        title: .settingsOverviewHeadlineSettings,
        items: [
          .init(
            title: .settingsOverviewListRevocation,
            leadingIcon: Theme.shared.image.walletKey,
            action: {}()
          ),
          .init(
            title: .settingsOverviewListNotification,
            leadingIcon: Theme.shared.image.notification,
            trailingIcon: .externalLink,
            action: {}()
          )
        ]
      ),
      .init(
        title: .settingsOverviewHeadlineLegal,
        items: [
          .init(title: .settingsOverviewListAboutEudi, action: {}()),
          .init(title: .settingsOverviewListImpress, action: {}())
        ]
      )
    ],
    appVersion: "Version: 1.2 Build: 236",
    logsUrl: nil,
    changelogUrl: nil,
    presentedWebLink: nil
  )
  ContentScreenView(
    padding: .zero,
    canScroll: false,
    background: Theme.shared.color.surface
  ) {
    content(viewState: viewState)
      .padding(.horizontal, DSStyle.Spacers.SPACING_MEDIUM)
  }
}
