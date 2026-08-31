//
//  DebugConfigView.swift
//  feature-dashboard
//

import SwiftUI
import logic_resources
import logic_ui

struct DebugConfigView<Router: RouterHost>: View {

  @ObservedObject private var viewModel: DebugConfigViewModel<Router>

  init(with viewModel: DebugConfigViewModel<Router>) {
    self.viewModel = viewModel
  }

  var body: some View {
    ContentScreenView(
      canScroll: true,
      navigationTitle: .custom("Debug config"),
      toolbarContent: toolbarContent()
    ) {
      HeaderContentView(onBack: viewModel.onPop)
      ScrollView {
        content
          .padding(DSStyle.Spacers.SPACING_MEDIUM)
      }
    }
    .confirmationDialog(
      "Apply configuration?",
      isPresented: Binding(
        get: { viewModel.viewState.isConfirmationVisible },
        set: { isPresented in
          if !isPresented {
            viewModel.cancelPendingAction()
          }
        }
      ),
      titleVisibility: .visible
    ) {
      Button("Apply and keep data") {
        viewModel.confirmPendingAction(wipeData: false)
      }
      Button("Apply and delete wallet data", role: .destructive) {
        viewModel.confirmPendingAction(wipeData: true)
      }
      Button("Cancel", role: .cancel) {
        viewModel.cancelPendingAction()
      }
    } message: {
      Text(
        "The app will close to apply the configuration. " +
        "Keep data when targeting the same backend (e.g. a new version of it). " +
        "Delete wallet data when switching to a different environment, otherwise the wallet's registration won't match it."
      )
    }
  }

  private var content: some View {
    VStack(spacing: DSStyle.Spacers.SPACING_MEDIUM) {
      DSTitleLabel(.custom("Debug config"))
        .frame(maxWidth: .infinity, alignment: .leading)

      infoBox

      field(
        label: "Wallet backend host",
        placeholder: viewModel.viewState.defaults.walletHostURL,
        text: $viewModel.walletHostURL
      )
      field(
        label: "Wallet backend api key",
        placeholder: "Default from app config",
        text: $viewModel.walletAPIKey,
        isSecure: true
      )
      field(
        label: "Open telemetry host",
        placeholder: viewModel.viewState.defaults.otlpHostURL,
        text: $viewModel.otlpHostURL
      )
      field(
        label: "Open telemetry auth token",
        placeholder: "Default from app config",
        text: $viewModel.otlpAuthToken,
        isSecure: true
      )
      field(
        label: "PID provider host",
        placeholder: viewModel.viewState.defaults.pidProviderURL,
        text: $viewModel.pidProviderURL
      )

      DSPrimaryButton(title: "Update") {
        viewModel.onUpdate()
      }
      DSSecondaryButton(title: "Reset") {
        viewModel.onReset()
      }
    }
    .frame(maxWidth: .infinity, alignment: .topLeading)
    .padding(.bottom, SPACING_LARGE_MEDIUM)
  }

  private var infoBox: some View {
    Text("Advanced settings for developers only. Changing these values will alter the app's default behavior.\n\nLeave a field blank to use the default configuration.")
      .font(DSTypography.Body.large)
      .foregroundColor(DSColor.onSurface)
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(DSStyle.Spacers.SPACING_MEDIUM)
      .background(
        RoundedRectangle(cornerRadius: 12)
          .fill(Theme.shared.color.surfaceContainer)
      )
  }

  @ViewBuilder
  private func field(
    label: String,
    placeholder: String,
    text: Binding<String>,
    isSecure: Bool = false
  ) -> some View {
    VStack(alignment: .leading, spacing: SPACING_EXTRA_SMALL) {
      Text(label)
        .font(DSTypography.Body.medium)
        .foregroundColor(DSColor.onSurfaceVariant)

      Group {
        if isSecure {
          SecureField(placeholder, text: text)
        } else {
          TextField(placeholder, text: text)
        }
      }
      .font(DSTypography.Body.large)
      .foregroundColor(DSColor.onSurface)
      .autocorrectionDisabled()
      .textInputAutocapitalization(.never)
      .padding(SPACING_MEDIUM_SMALL)
      .overlay(
        RoundedRectangle(cornerRadius: 8)
          .stroke(DSColor.outlineVariant, lineWidth: 1)
      )
    }
  }

  private func toolbarContent() -> ToolBarContent {
    .init(
      trailingActions: [],
      leadingActions: [
        Action(image: Theme.shared.image.chevronLeft) {
          viewModel.onPop()
        }
      ]
    )
  }
}
