//
//  PresentationErrorNoticeView.swift
//  feature-presentation
//

import SwiftUI
import logic_ui
import logic_resources

struct PresentationErrorNoticeView<Router: RouterHost>: View {
  @ObservedObject var viewModel: PresentationErrorNoticeViewModel<Router>

  private var config: PresentationErrorNoticeConfig { viewModel.viewState.config }

  var body: some View {
    PresentationErrorNoticeContent(
      illustration: config.illustration,
      title: config.title,
      message: config.message,
      primary: .init(title: config.primary.title, trailingIcon: config.primary.trailingIcon) {
        handle(config.primary.action)
      },
      secondary: config.secondary.map { button in
          .init(title: button.title, trailingIcon: button.trailingIcon) { handle(button.action) }
      },
      onClose: { viewModel.perform(.dismiss) }
    )
  }

  private func handle(_ action: PresentationErrorNoticeConfig.Action) {
    if case .reportSuspicion(let supervisoryAuthorityURL) = action {
      guard let supervisoryAuthorityURL, UIApplication.shared.canOpenURL(supervisoryAuthorityURL) else {
        return
      }
      UIApplication.shared.open(supervisoryAuthorityURL)
      return
    }
    viewModel.perform(action)
  }
}

#if DEBUG
@MainActor private func previewNotice(_ config: PresentationErrorNoticeConfig) -> some View {
  PresentationErrorNoticeView(viewModel: PresentationErrorNoticeViewModel(router: PreviewRouter(), config: config))
}

#Preview("RP not trusted") {
  previewNotice(PresentationErrorHandlerImpl.notTrustedNotice(originator: .featureDashboardModule(.dashboard)))
}

#Preview("Credential missing") {
  previewNotice(PresentationErrorHandlerImpl.credentialMissingNotice(.featureDashboardModule(.dashboard)))
}

#Preview("PID missing") {
  previewNotice(PresentationErrorHandlerImpl.pidMissingNotice(.featureDashboardModule(.dashboard)))
}

#Preview("Reset PID confirmation") {
  previewNotice(PresentationErrorHandlerImpl.pidMissingNotice(.featureDashboardModule(.dashboard)))
}
#endif
