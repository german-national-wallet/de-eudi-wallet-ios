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

struct DocumentOfferView<Router: RouterHost>: View {

  @ObservedObject var viewModel: DocumentOfferViewModel<Router>

  init(with viewModel: DocumentOfferViewModel<Router>) {
    self.viewModel = viewModel
  }

  var body: some View {
    Group {
      if viewModel.viewState.isLoading {
        ContentScreenView {
          ContentLoaderView(
            loadingText: LocalizableStringKey.eaaIssuanceLoadingTitle.toString
          )
        }
      } else {
        content
      }
    }
      .centerDialog(
        isPresented: $viewModel.showCloseConfirmationPopup,
        icon: Theme.shared.image.infoCircleImage,
        title: .eaaIssuanceDialogCancelTitle,
        subtitle: .eaaIssuanceDialogCancelSubTitle,
        buttons: [
          CustomAlertDialogConfig(
            title: .eaaIssuanceDialogCancelPrimButton,
            role: .destructive
          ) {
            viewModel.cancelToDashboard()
          },
          CustomAlertDialogConfig(
            title: .eaaIssuanceDialogCancelSecButton,
            role: .secondary
          ) { }
        ]
      )
      .task {
        await viewModel.initialize()
      }
      .onReceive(NotificationCenter.default.publisher(for: NSNotification.CredentialOffer)) { data in
        guard let payload = data.userInfo else {
          return
        }
        viewModel.handleNotification(with: payload)
      }
  }

  @ViewBuilder private var content: some View {
    if hasNothingToOffer {
      ContentScreenView(navigationTitle: .addDocumentRequest) {
        noDocumentsFound(imageSize: getScreenRect().width / 4)
      }
    } else {
      IllustratedIntroView(
        config: viewModel.introConfig,
        errorConfig: viewModel.viewState.error
      )
    }
  }

  private var hasNothingToOffer: Bool {
    viewModel.viewState.error == nil
      && viewModel.viewState.documentOfferUiModel.uiOffers.isEmpty
  }
}

@MainActor
@ViewBuilder
private func noDocumentsFound(imageSize: CGFloat) -> some View {
  VStack(alignment: .center) {

    Spacer()

    VStack(alignment: .center, spacing: SPACING_MEDIUM) {

      Theme.shared.image.exclamationmarkCircle
        .renderingMode(.template)
        .resizable()
        .foregroundStyle(Theme.shared.color.onSurface)
        .frame(width: imageSize, height: imageSize)

      Text(.requestCredentialOfferNoDocument)
        .typography(Theme.shared.font.bodyMedium)
        .foregroundColor(Theme.shared.color.onSurface)
        .multilineTextAlignment(.center)
    }

    Spacer()
  }
}
