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
import feature_common
import logic_resources
import logic_core

struct AddDocumentView<Router: RouterHost>: View {
  
  @ObservedObject var viewModel: AddDocumentViewModel<Router>
  var contentSize: CGFloat = 0.0
  @State private var showWebView = false
  private let verifier: String = "https://playground.eudi-wallet.org/"
  
  init(with viewModel: AddDocumentViewModel<Router>) {
    self.viewModel = viewModel
    self.contentSize = getScreenRect().width / 2.0
  }
  
  var body: some View {
    ContentScreenView(
      padding: .zero,
      canScroll: true,
      errorConfig: viewModel.viewState.error,
      navigationTitle: .chooseFromList,
      isLoading: viewModel.viewState.isLoading,
      toolbarContent: viewModel.toolbarContent()
    ) {
      HStack {
        Button(action: {
          viewModel.onMenuTap()
        }, label: {
          Theme.shared.image.burgerMenu
        })
        Spacer()
      }
      .padding(.leading, DSStyle.Spacers.SPACING_MEDIUM)

      Content(viewState: viewModel.viewState) {
        viewModel.onClick()
      }

      // UITests only: button for triggering deeplink UI Test
      if AppEnvironment.isUITesting {
        Button("Trigger presentation") {
          showWebView = true
        }
        .accessibilityIdentifier("deeplinkTriggerButton")
      }
    }
    .onAppear {
      Task {
        await self.viewModel.initialize()
      }
    }
    .sheet(isPresented: $showWebView) {
      if let url = URL(string: verifier) {
        NavigationView {
          VStack {
            Text("Loading: \(url.absoluteString)")
              .font(.caption)
              .foregroundColor(.gray)
              .padding()

            WebViewContainer(url: url)
              .frame(maxWidth: .infinity, maxHeight: .infinity)
          }
          .navigationTitle("Trigger presentation")
          .navigationBarTitleDisplayMode(.inline)
          .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
              Button("Done") {
                showWebView = false
              }
              .accessibilityIdentifier("closeWebViewButton")
            }
          }
        }
      }
    }
    .overlay {
      if viewModel.isErrorPopupVisible {
        ConfirmationPopupView(viewModel: viewModel.errorPopupViewModel)
      }
    }
  }
}

private struct Content: View {
  
  @ObservedObject var appState = AppState.shared
  let viewState: AddDocumentViewState
  let action: () -> Void
  
  init(viewState: AddDocumentViewState, action: @escaping () -> Void) {
    self.viewState = viewState
    self.action = action
  }
  
  var body: some View {
    ScrollView {
      VStack(spacing: 0) {
        VStack(alignment: .leading) {
          DSTitleLabel(.chooseFromListTitle, font: DSTypography.Headline.large)
            .padding()
            .padding(.top)
          
          HStack {
            Spacer()
            Theme.shared.image.backgroundPID
            Spacer()
          }
          Spacer()
          HStack {
            Text(.dashboardScreenSecondaryText)
              .font(DSTypography.Body.medium)
              .foregroundStyle(DSColor.onSurface)
            Spacer(minLength: 45)
            DSPrimaryButton(title: LocalizableStringKey.dashboardPrimaryButtonTitle.toString, action: action)
            .accessibilityIdentifier("dashboardPrimaryButton")
          }
          .padding(.vertical, 23)
          .padding(.horizontal, 13)
          .background {
            Rectangle()
              .foregroundStyle(DSColor.backgroundPIDMedium)
              .border(DSColor.outlineVariant, width: 1)
          }
        }
        .background {
          RoundedRectangle(cornerRadius: 12)
            .fill(DSColor.backgroundPIDLight)
            .overlay(
              RoundedRectangle(cornerRadius: 12)
                .stroke(DSColor.outlineVariant, lineWidth: 1)
            )
        }

        Toggle(isOn: $appState.useSimulatedEIDCard) {
          Text(.pidInspectionInitialDashboardTempLabel1)
            .foregroundStyle(DSColor.onSurface)
            .font(DSTypography.Body.medium)
            .bold()
        }
        .toggleStyle(DSToggle.TintedToggleStyle())
        .padding()
      }
      .overlay(
        RoundedRectangle(cornerRadius: 12)
          .stroke(DSColor.outlineVariant, lineWidth: 1)
      )
      .padding(.horizontal, Theme.shared.dimension.padding)
      .padding(.bottom)
      .padding(.top)
      
    }
    .shimmer(isLoading: viewState.isLoading)
    .ignoresSafeArea(edges: .bottom)
  }
}
