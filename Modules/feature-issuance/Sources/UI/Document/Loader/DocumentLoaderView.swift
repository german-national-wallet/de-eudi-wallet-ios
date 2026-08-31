//
//  DocumentLoaderView.swift
//  feature-issuance
//

import SwiftUI
import logic_ui
import logic_resources

struct DocumentLoaderView<Router: RouterHost>: View {

  @ObservedObject var viewModel: DocumentLoaderViewModel<Router>

  init(with viewModel: DocumentLoaderViewModel<Router>) {
    self.viewModel = viewModel
  }

  var body: some View {
    ContentScreenView(background: DSColor.background) {
      ContentLoaderView(
        loadingText: title,
        progress: viewModel.viewState.progress
      )
    }
    .task {
      await viewModel.issueDocuments()
    }
  }

  /// A failure carries no text: this screen leaves immediately, and the screen it returns to is the
  /// one that explains what went wrong.
  private var title: String {
    return switch viewModel.viewState.progress {
    case .loading: LocalizableStringKey.eaaIssuanceLoadingTitle.toString
    case .success: LocalizableStringKey.eaaIssuanceSuccessTitle.toString
    case .error: ""
    }
  }
}
