//
//  SwiftUIView.swift
//  feature-issuance
//

import SwiftUI
import logic_ui
import feature_common
struct IssuanceLoadingView<Router: RouterHost>: View {

  @ObservedObject private var viewModel: IssuanceLoadingViewModel<Router>

  init(with viewModel: IssuanceLoadingViewModel<Router>) {
    self.viewModel = viewModel
  }

  var body: some View {
    ZStack {
      ContentLoaderView()
        .onAppear {
          Task {
            try await viewModel.issueCredentials()
          }
        }
      if viewModel.isErrorPopupVisible {
        ConfirmationPopupView(viewModel: viewModel.errorPopupViewModel)
      }
    }
    .ignoresSafeArea(.keyboard, edges: .bottom)
  }
}
