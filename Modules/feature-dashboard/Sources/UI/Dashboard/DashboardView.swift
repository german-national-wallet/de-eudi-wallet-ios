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

struct DashboardView<Router: RouterHost>: View {

  @ObservedObject private var viewModel: DashboardViewModel<Router>

  public init(with viewModel: DashboardViewModel<Router>) {
    self.viewModel = viewModel
  }

  var body: some View {
    ContentScreenView(
      padding: .zero,
      canScroll: false,
      navigationTitle: viewModel.viewState.navigationTitle,
      toolbarContent: viewModel.viewState.toolBarContent
    ) {
        content(
          tabView: { tab in
            return switch tab {
            case .overview:
              overviewContent.eraseToAnyView()
            case .activity:
              viewModel.viewState.activitiesTab
                .eraseToAnyView()
            case .settings:
              viewModel.viewState.settingsTab
                .eraseToAnyView()
            default:
              EmptyView().eraseToAnyView()
            }
          },
          selectionBinding: Binding(
            get: { viewModel.selectedTab },
            set: { requestedTab in
              guard requestedTab != .qrReader else {
                viewModel.selectedTab = viewModel.selectedTab
                viewModel.shouldPresentQRReader = true
                return
              }
              viewModel.selectedTab = requestedTab
            }),
          qrPresentationBinding: $viewModel.shouldPresentQRReader
        )
    }
    .onAppear {
      viewModel.onAppear()
    }
  }
  
  @ViewBuilder
  private var overviewContent: some View {
      if viewModel.viewState.hasIssuedDocuments {
      viewModel.viewState.credentialsTab.eraseToAnyView()
    } else {
      viewModel.viewState.addDocumentTab?.eraseToAnyView()
    }
  }
}

@MainActor
@ViewBuilder
private func content(
  tabView: @escaping (DashboardTab) -> AnyView,
  selectionBinding: Binding<DashboardTab>,
  qrPresentationBinding: Binding<Bool>
) -> some View {
  TabView(selection: selectionBinding) {
      Tab(value: .overview) {
        tabView(.overview)
      } label: {
        tabLabel(for: .overview)
      }
      Tab(value: .activity) {
        tabView(.activity)
      } label: {
        tabLabel(for: .activity)
      }
      Tab(value: .settings) {
        tabView(.settings)
      } label: {
        tabLabel(for: .settings)
      }
      Tab(value: .qrReader, role: .search) {
        // QR screen placeholder. Do not fill.
      } label: {
        Label {} icon: {
          DashboardTab.qrReader.tabIcon
            .renderingMode(.template)
            .foregroundStyle(Theme.shared.color.onSurface)
            .accessibilityHidden(true)
        }
        .accessibilityLabel(Text(LocalizableStringKey.dashboardTabBarTitleLabelScanner.toString))
        .accessibilityIdentifier("dashboardScanQrButton")
      }
  }
  .tint(Theme.shared.color.onSurface)
  .sheet(isPresented: qrPresentationBinding) {
    qrPresentationBinding.wrappedValue = false
  } content: {
    // TODO: QR Implementation should go here
    VStack {
      Text("QR Reader here")
    }
  }
}

@MainActor
@ViewBuilder
private func tabLabel(for tab: DashboardTab) -> some View {
  Label {
    Text(tab.tabTitle)
      .font(DSStyle.Typography.Body.small)
      .multilineTextAlignment(.center)
  } icon: {
    tab.tabIcon.accessibilityHidden(true)
  }
}

#Preview {
  ContentScreenView(padding: .zero, canScroll: false, background: Theme.shared.color.surface) {
    content(
      tabView: { _ in EmptyView().eraseToAnyView() },
      selectionBinding: .constant(.overview),
      qrPresentationBinding: .constant(false))
  }
}
