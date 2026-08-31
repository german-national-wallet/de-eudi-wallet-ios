//
//  InvalidPinRetryMessageView.swift
//  feature-common
//

import SwiftUI
import logic_ui
import feature_common

struct InvalidPinRetryMessageView<Router: RouterHost>: View {
  @ObservedObject var viewModel: InvalidPinRetryMessageViewModel<Router>

  public init(viewModel: InvalidPinRetryMessageViewModel<Router>) {
    self.viewModel = viewModel
  }

  var body: some View {
    ZStack {
      ContentScreenView(padding: 0) {
        GeometryReader { geometry in
          VStack {
            ScrollView(.vertical, showsIndicators: false) {
              HeaderContentView()
              VStack(alignment: .leading, spacing: DSStyle.Spacers.SPACING_LARGE_MEDIUM) {
                
                Text(viewModel.viewState.config.mainTitle)
                  .font(DSStyle.Typography.Title.large)
                  .foregroundStyle(DSColor.primary)
                  .padding(.top, DSStyle.Spacers.SPACING_LARGE)
                  .fontWeight(DSStyle.FontWeight.medium_500)
                  .accessibilityIdentifier("invalidWalletPin")
                
                VStack(spacing: DSStyle.Spacers.SPACING_LARGE) {
                  HStack {
                    Spacer()
                    viewModel.warningImage
                      .resizable()
                      .frame(width: 95, height: 91)
                    Spacer()
                  }
                  if viewModel.showCounterView {
                    counterView
                      .padding(.top, DSStyle.Spacers.SPACING_LARGE)
                  }
                }
                .padding(.top, DSStyle.Spacers.SPACING_EXTRA_LARGE)
                
                Spacer()
              }
              
            }
            if viewModel.showWarningMessageView {
              warningMessage
            }
            if viewModel.showBlockedUserButtons {
              blockedUserButtons
            } else {
              resetPINButton
            }
          }
          .frame(minHeight: geometry.size.height)
          .padding(.horizontal, DSStyle.Spacers.SPACING_LARGE_MEDIUM)
          .padding(.bottom, DSStyle.Spacers.SPACING_SMALL)
        }
      }
      if viewModel.showForgotPinPopup {
        ConfirmationPopupView(viewModel: viewModel.confirmationPopupViewModel)
        .transition(.opacity)
        .zIndex(1)
      }
    }
    .animation(.easeInOut, value: viewModel.showForgotPinPopup)
    .sheet(isPresented: $viewModel.showInfoSheet) {
      forgotPinBottomSheet
    }
    .background(DSColor.background)
  }

  private var counterView: some View {
    HStack {
      Text(viewModel.viewState.config.retryMessage)
        .font(DSTypography.Body.large)
        .foregroundStyle(DSColor.onSurfaceVariant)
        .fontWeight(DSStyle.FontWeight.regular_400)
      Spacer()
      Text(viewModel.countdownText)
        .font(DSTypography.Title.large)
        .foregroundStyle(DSColor.onSurfaceVariant)
        .fontWeight(DSStyle.FontWeight.medium_500)
    }
    .padding()
    .clipShape(RoundedCorner(radius: 10, corners: [.allCorners]))
    .overlay(
      RoundedCorner(radius: 10, corners: [.allCorners])
        .stroke(DSColor.outlineVariant, lineWidth: 1)
    )
  }

  private var warningMessage: some View {
    viewModel.warningMessage?.extractBoldAndRegularText(font: DSTypography.Body.large)
      .padding()
      .background {
        RoundedRectangle(cornerRadius: 12)
          .foregroundStyle(.white)
      }
      .padding(.bottom, DSStyle.Spacers.SPACING_MEDIUM)
  }

  private var forgotPinBottomSheet: some View {
    BottomSheetViewWithAction(
      title: LocalizableStringKey.walletPinForgotten.toString,
      message: LocalizableStringKey.walletPinForgotPopupDesc.toString,
      buttonTitle: LocalizableStringKey.walletResetNow.toString,
      action: {
        viewModel.showInfoSheet = false
        viewModel.showForgotPinPopup = true
    })
  }

  private var blockedUserButtons: some View {
    VStack(alignment: .leading, spacing: DSStyle.Spacers.SPACING_SMALL) {
      DSPrimaryButton(title: LocalizableStringKey.walletResetNow.toString) {
        Task {
          await viewModel.resetWallet()
        }
      }
      .accessibilityIdentifier("resetWalletNow")
      DSSecondaryButton(title: LocalizableStringKey.toWallet.toString) {
        viewModel.sendUserToDashboard()
      }
    }
  }

  private var resetPINButton: some View {
    DSSecondaryButton(title: viewModel.viewState.config.primaryButtonTitle.toString) {
      viewModel.showInfoSheet = true
    }
  }
}
