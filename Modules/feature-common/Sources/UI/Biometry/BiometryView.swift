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

struct BiometryView<Router: RouterHost>: View {

  @ObservedObject var viewModel: BiometryViewModel<Router>
  @Environment(\.scenePhase) var scenePhase

  init(with viewModel: BiometryViewModel<Router>) {
    self.viewModel = viewModel
  }

  var body: some View {
    VStack {
      content(
        viewState: viewModel.viewState,
        uiPinInputField: $viewModel.uiPinInputField,
        isSheetPresented: $viewModel.isSheetPresented,
        onBack: viewModel.backButtonTapped,
        onBiometry: viewModel.processPin
      )
    }
    .ignoresSafeArea(edges: .bottom)
    .background(DSColor.background.ignoresSafeArea())
    .onAppear {
      self.viewModel.onAppearBiometry()
    }
  }
}

@MainActor
@ViewBuilder
private func content(
  viewState: BiometryState,
  uiPinInputField: Binding<String>,
  isSheetPresented: Binding<Bool>,
  onBack: @escaping () -> Void,
  onBiometry: @escaping () -> Void
) -> some View {
  VStack {
    HeaderContentView(onBack: onBack)
      .padding(.vertical, DSStyle.Spacers.SPACING_SMALL)
    
    PresentationProgressView(progress: 0.75)
      .frame(height: 10)
    
    ContentTitleView(
      title: .enterPassword,
      titleFont: Theme.shared.font.titleMedium,
      caption: viewState.areBiometricsEnabled
      ? viewState.config.caption
      : viewState.config.quickPinOnlyCaption,
      titleColor: DSColor.primary,
      topSpacing: viewState.isCancellable ? .withToolbar : .withoutToolbar
    )
    
    VSpacer.mediumSmall()
    
    pinView(
      uiPinInputField: uiPinInputField,
      quickPinSize: viewState.quickPinSize,
      areBiometricsEnabled: viewState.areBiometricsEnabled,
      isSheetPresented: isSheetPresented,
      pinError: viewState.pinError,
      onBiometry: onBiometry
    )
    
    Spacer()
  }
}

@MainActor
@ViewBuilder
private func pinView(
  uiPinInputField: Binding<String>,
  quickPinSize: Int,
  areBiometricsEnabled: Bool,
  isSheetPresented: Binding<Bool>,
  pinError: String?,
  onBiometry: @escaping () -> Void
) -> some View {
  VStack(alignment: .center, spacing: .zero) {

    PinTextFieldView(
      numericText: uiPinInputField,
      maxDigits: quickPinSize,
      isSecureEntry: .constant(true),
      canFocus: .constant(!areBiometricsEnabled),
      errorMessage: pinError
    )
    Spacer()
    
    Button(action: {
      isSheetPresented.wrappedValue = true
    }, label: {
      HStack(spacing: 8) {
        Spacer()
        
        Theme.shared.image.infoCircle
          .resizable()
          .frame(width: 16, height: 16)
          .foregroundColor(DSColor.primary)
        
        Text(.issuanceEidUnkownTitle)
          .font(DSTypography.Label.large)
          .foregroundStyle(DSColor.primary)
        
        Spacer()
      }
    })
    .buttonStyle(DSButton.TextButtonStyle())

  if !uiPinInputField.wrappedValue.isEmpty {
    Button(action: onBiometry) {
      Text(.sendData)
        .font(DSTypography.Label.large)
        .fontWeight(DSStyle.FontWeight.medium_500)
        .foregroundColor(DSColor.onPrimary)
    }
    .buttonStyle(DSButton.FilledPressedButtonStyle(defaultBackgroundColor: DSColor.primary))
    } else {
      Button(action: {
        // TODO:- handle action
      }, label: {
        Text(.sendData)
          .font(DSTypography.Label.large)
          .fontWeight(DSStyle.FontWeight.medium_500)
          .foregroundColor(DSColor.onSurfaceVariant)
      })
    }
  }
}

@MainActor
@ViewBuilder
private func passwordView(
  password: Binding<String>,
  areBiometricsEnabled: Bool,
  passwordError: String?
) -> some View {
  VStack(spacing: .zero) {
    SecureField("Enter your passowoord", text: password)
      .padding()
      .background(Color(.systemGray6))
      .cornerRadius(8)
      .overlay(
        RoundedRectangle(cornerRadius: 8)
          .stroke(passwordError != nil ? Theme.shared.color.error : Color.clear, lineWidth: 1)
      )
      .disabled(areBiometricsEnabled) // Optional depending on logic

    VSpacer.mediumSmall()

    if let error = passwordError {
      HStack {
        Text(error)
          .typography(Theme.shared.font.bodyMedium)
          .foregroundColor(Theme.shared.color.error)
        Spacer()
      }
    }
  }
}
