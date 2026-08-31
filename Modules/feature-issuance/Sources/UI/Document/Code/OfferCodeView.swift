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

struct OfferCodeView<Router: RouterHost>: View {

  @ObservedObject var viewModel: OfferCodeViewModel<Router>

  init(with viewModel: OfferCodeViewModel<Router>) {
    self.viewModel = viewModel
  }

  var body: some View {
    ContentScreenView(
      padding: 0,
      errorConfig: viewModel.viewState.error,
      background: DSColor.background
    ) {
      HeaderContentView(
        onBack: viewModel.backButtonTapped,
        onClose: viewModel.closeButtonAction,
        onHelp: viewModel.onHelp
      )

      content(
        viewState: viewModel.viewState,
        codeInput: $viewModel.codeInput,
        codeIsFocused: $viewModel.codeIsFocused,
        isPrimaryButtonEnabled: viewModel.isPrimaryButtonEnabled,
        errorMessage: $viewModel.errorMessage,
        action: viewModel.primaryButtonAction
      )
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
    .onChange(of: viewModel.showCloseConfirmationPopup) { isPresented in
      guard !isPresented else { return }
      viewModel.codeIsFocused = true
    }
    .task {
      await viewModel.checkPendingIssuance()
    }
  }
}

@MainActor
@ViewBuilder
private func loader() -> some View {
  Spacer()
  ContentLoaderView()
  Spacer()
}

@MainActor
@ViewBuilder
private func pinView(
  isLoading: Bool,
  txCodeLength: Int,
  codeInput: Binding<String>,
  codeIsFocused: Binding<Bool>,
  errorMessage: String
) -> some View {
  PinTextFieldView(
    numericText: codeInput,
    maxDigits: txCodeLength,
    isSecureEntry: .constant(false),
    canFocus: codeIsFocused,
    errorMessage: errorMessage
  )
  .disabled(isLoading)
}

@MainActor
@ViewBuilder
private func content(
  viewState: OfferCodeViewState,
  codeInput: Binding<String>,
  codeIsFocused: Binding<Bool>,
  isPrimaryButtonEnabled: Bool,
  errorMessage: Binding<String>,
  action: @escaping () -> Void
) -> some View {
  ScrollView {
    VStack(alignment: .leading, spacing: .zero) {
      DSTitleLabel(LocalizableStringKey.eaaOfferTransactionCodeViewTitle(["\(viewState.config.txCodeLength)"]))
        .padding(.top, DSStyle.Spacers.SPACING_MEDIUM)

      if viewState.isLoading {
        loader()
      } else {
        pinView(
          isLoading: viewState.isLoading,
          txCodeLength: viewState.config.txCodeLength,
          codeInput: codeInput,
          codeIsFocused: codeIsFocused,
          errorMessage: errorMessage.wrappedValue
        )
        .padding(.top, DSStyle.Spacers.SPACING_EXTRA_LARGE)
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(DSStyle.Spacers.SPACING_MEDIUM)
  }
  .safeAreaInset(edge: .bottom) {
    DSPrimaryButton(
      title: LocalizableStringKey.eaaIssuanceTransactionCodeEntryPrimButton.toString,
      action: action
    )
    .disabled(!isPrimaryButtonEnabled)
    .accessibilityIdentifier("pinSubmitPrimaryButton")
    .padding(DSStyle.Spacers.SPACING_MEDIUM)
    .background(DSColor.background)
  }
  .modifier(KeyboardOverlapPadding())
}

private struct KeyboardOverlapPadding: ViewModifier {

  @State private var keyboardOverlap: CGFloat = 0

  func body(content: Content) -> some View {
    content
      .padding(.bottom, keyboardOverlap)
      .ignoresSafeArea(.keyboard, edges: .bottom)
      .animation(.easeOut(duration: 0.25), value: keyboardOverlap)
      .onReceive(
        NotificationCenter.default.publisher(for: UIResponder.keyboardWillChangeFrameNotification)
      ) { notification in
        guard
          let endFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect
        else {
          return
        }
        let screen = UIScreen.main.bounds
        let bottomInset = UIApplication.shared.currentUIWindow?.safeAreaInsets.bottom ?? 0
        keyboardOverlap = max(0, screen.maxY - endFrame.minY - bottomInset)
      }
      .onReceive(
        NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)
      ) { _ in
        keyboardOverlap = 0
      }
  }
}

#Preview {
  let state = OfferCodeViewState(
    isLoading: false,
    error: nil,
    config: IssuanceCodeUiConfig(
      offerUri: "",
      issuerName: "Issuer Name",
      txCodeLength: 6,
      docOffers: [],
      successNavigation: .popTo(
        .featureIssuanceModule(
          .credentialOfferRequest(config: NoConfig())
        )
      ),
      navigationCancelType: .pop
    ),
    title: LocalizableStringKey.addDocumentTitle,
    caption: LocalizableStringKey.addDocumentSubtitle,
    contentHeaderConfig: .init(
      appIconAndTextData: AppIconAndTextData(
        appIcon: ThemeManager.shared.image.logoEuDigitalIndentityWallet,
        appText: ThemeManager.shared.image.euditext
      )
    )
  )

  ContentScreenView {
    content(
      viewState: state,
      codeInput: .constant("inout"),
      codeIsFocused: .constant(false),
      isPrimaryButtonEnabled: false,
      errorMessage: .constant(""),
      action: { }
    )
  }
}
