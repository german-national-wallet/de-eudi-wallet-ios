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
      Group {
        if viewModel.isIssued {
          ContentSuccessView(
            width: Constants.loaderSize,
            successText: LocalizableStringKey.eaaIssuanceSuccessTitle.toString,
            onFinished: viewModel.successAnimationFinished
          )
        } else {
          ContentLoaderView(
            width: Constants.loaderSize,
            loadingText: LocalizableStringKey.pidIssuanceLoadingTitle.toString,
            progress: .loading
          )
        }
      }
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

    .background(DisableSwipeBackGesture())
  }
}

private enum Constants {
  /// The loader footprint both states align to, passed to `ContentLoaderView`
  /// and `ContentSuccessView` explicitly so the two states cannot drift apart.
  static let loaderSize: CGFloat = 50
}
