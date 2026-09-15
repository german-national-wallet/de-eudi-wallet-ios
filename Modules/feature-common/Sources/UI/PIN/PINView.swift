//
//  PINView.swift
//  feature-presentation
//

import SwiftUI
import logic_ui
import logic_resources

public struct PINView<Router: RouterHost>: View {
  @ObservedObject var viewModel: PINViewModel<Router>
  @State private var pinInput = ""
  @State private var isSecureEntry = true
  @State private var isCancelDialogPresented = false

  public init(viewModel: PINViewModel<Router>) {
    self.viewModel = viewModel
  }
  
  public var body: some View {
    VStack {
      HeaderContentView(
        onBack: viewModel.backButtonTapped,
        onClose: { isCancelDialogPresented = true },
        onHelp: viewModel.viewState.config.showsHelpButton
          ? { viewModel.isSheetPresented = true }
          : nil,
        progress: viewModel.viewState.config.progressSteps.map {
          (current: $0.current, total: $0.total)
        }
      )
      VStack(spacing: 0) {
        ScrollView {
          VStack {
            VStack(alignment: .leading) {
              DSTitleLabel(viewModel.viewState.config.navigationTitle)
                .padding(.bottom, DSStyle.Spacers.SPACING_EXTRA_LARGE)

              Spacer()

              PinTextFieldView(
                numericText: $pinInput,
                maxDigits: viewModel.viewState.config.quickPinSize,
                isSecureEntry: $isSecureEntry,
                canFocus: $viewModel.canFocus,
                showsSecureEntryToggle: true,
                errorMessage: viewModel.errorMessage
              )
              .padding(.vertical, DSStyle.Spacers.SPACING_LARGE_MEDIUM)
              .disabled(!viewModel.canFocus)
              .shimmer(isLoading: viewModel.viewState.isLoading)

              Spacer(minLength: 40)
            }
            .padding(.vertical, DSStyle.Spacers.SPACING_SMALL)
          }
          .padding(.horizontal, DSStyle.Spacers.SPACING_MEDIUM)
        }
        self.addBottomButtons()
      }
    }
    .background(DSColor.background.ignoresSafeArea())
    .onAppear {
      viewModel.onViewAppeared()
      pinInput = ""
      Task {
        await viewModel.doWork()
      }
    }
    .onChange(of: viewModel.errorMessage) { message in
      if !message.isEmpty {
        viewModel.canFocus = true
      }
    }
    .onChange(of: pinInput) { newValue in
      let digitsOnly = newValue.filter(\.isNumber)
      let limitedDigits = String(digitsOnly.prefix(viewModel.viewState.config.quickPinSize))
      if limitedDigits != newValue {
        pinInput = limitedDigits
        return
      }

      let updatedPin = limitedDigits.map(String.init)
      if viewModel.pin != updatedPin {
        viewModel.pin = updatedPin
      }
    }
    .sheet(isPresented: $viewModel.isSheetPresented) {
      switch viewModel.viewState.config.pinScreenType {
        
      case .eidCanFlow:
        CanInfoView()
          .clipShape(RoundedCorner(radius: 20, corners: [.topLeft, .topRight]))
          .presentationDetents([.fraction(0.9)])
          .background(DSColor.background)
          .ignoresSafeArea()
        
      case .issueEidPinFlow:
        CardPinLetterInfoSheetView(
          onSetCardPin: viewModel.setCardPinTapped,
          onClose: { viewModel.isSheetPresented = false }
        )
        .presentationDetents([.fraction(0.9)])

      case .transportPinFlow:
        BottomSheetViewWithAction(
          title: LocalizableStringKey.setupPinSheetTitle.toString,
          message: LocalizableStringKey.setupPinSheetMessage.toString,
          buttonTitle: LocalizableStringKey.setupPinSheetButtonText.toString,
          action: {}
        )
        .presentationDetents([.fraction(0.9)])
      default:
        BottomSheetView(
          title: LocalizableStringKey.whatIsSecurityPassword.toString,
          message: LocalizableStringKey.whatIsSecurityPasswordMessage.toString
        )
        .presentationDetents([.fraction(0.9)])
      }
    }
    .cancelConfirmationDialog(
      isPresented: $isCancelDialogPresented,
      onConfirm: viewModel.handleCloseButton
    )
  }

  func addBottomButtons() -> AnyView {
    let view =
    VStack {
      DSPrimaryButton(
        title: viewModel.viewState.config.primaryButtonTitle?.toString ?? LocalizableStringKey.sendData.toString,
        action: {
          viewModel.canFocus = false
          Task {
            await viewModel.onSendData()
            pinInput = ""
          }
        }
      )
      .disabled(viewModel.pin.count != viewModel.viewState.config.quickPinSize)
      .accessibilityIdentifier("pinSubmitPrimaryButton")
      .shimmer(isLoading: viewModel.viewState.isLoading)
      if let caption = viewModel.viewState.config.caption {
        DSSecondaryButton(
          title: caption.toString,
          icon: Theme.shared.image.help
        ) {
          $viewModel.isSheetPresented.wrappedValue = true
        }
      }
    }
    return view
      .fixedSize(horizontal: false, vertical: true)
      .padding(.horizontal, DSStyle.Spacers.SPACING_MEDIUM)
      .padding(.bottom, DSStyle.Spacers.SPACING_EXTRA_SMALL)
      .eraseToAnyView()
  }
}
