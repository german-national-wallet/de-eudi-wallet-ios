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

struct SideMenuView<Router: RouterHost>: View {

  @ObservedObject private var viewModel: SideMenuViewModel<Router>

  init(with viewModel: SideMenuViewModel<Router>) {
    self.viewModel = viewModel
  }

  var body: some View {
    ContentScreenView(
      canScroll: true,
      navigationTitle: .myEuWallet,
      toolbarContent: toolbarContent()
    ) {
      HeaderContentView(onBack: viewModel.backButtonTapped)
      content(
        viewState: viewModel.viewState
      )
      .padding(DSStyle.Spacers.SPACING_MEDIUM)
    }
  }

  func toolbarContent() -> ToolBarContent {
    .init(
      trailingActions: [],
      leadingActions: [
        Action(image: Theme.shared.image.chevronLeft) {
          viewModel.onPop()
        }
      ]
    )
  }
}

@MainActor
@ViewBuilder
private func content(viewState: SideMenuViewState) -> some View {
  VStack(spacing: SPACING_MEDIUM_SMALL) {
    DSTitleLabel(.globalMenu)
      .frame(maxWidth: .infinity, alignment: .leading)
      .lineLimit(1)
      .minimumScaleFactor(0.8)

    if !viewState.items.isEmpty {
      Text(.logsDownloadDisclaimer)
        .font(DSTypography.Title.medium)
        .foregroundColor(DSColor.onSurfaceVariant)
        .frame(maxWidth: .infinity, alignment: .leading)
        .minimumScaleFactor(0.8)
        .padding(.bottom, DSStyle.Spacers.SPACING_MEDIUM)
    }

    ForEach(viewState.items) { item in
      if item.isShareLink {
        if let fileUrl = viewState.logsUrl {
          ShareLink(item: fileUrl) {
            TappableCellView(
              title: .globalRetrieveLogs,
              showDivider: item.showDivider,
              useOverlay: false,
              action: {}()
            )
          }
        }
      } else {
        TappableCellView(
          title: item.title,
          showDivider: item.showDivider,
          trailingIcon: nil,
          action: item.action()
        )
      }
    }
    Spacer()
  }
  .padding(.bottom, SPACING_LARGE_MEDIUM)
}

#Preview {
  let viewSate = SideMenuViewState(
    items: [
      .init(
        title: .changeQuickPinOption,
        action: {}()
      )
    ],
    appVersion: "",
    logsUrl: URL(string: "https://www.example.com"),
    changelogUrl: URL(string: "https://www.example.com")
  )
  ContentScreenView(
    padding: .zero,
    canScroll: false,
    background: Theme.shared.color.surface
  ) {
    content(viewState: viewSate)
  }
}
