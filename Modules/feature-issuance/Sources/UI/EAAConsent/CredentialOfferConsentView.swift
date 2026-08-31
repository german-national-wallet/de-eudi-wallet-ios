//
//  CredentialOfferConsentView.swift
//  feature-issuance
//

import SwiftUI
import logic_ui
import logic_resources

struct CredentialOfferConsentView<Router: RouterHost>: View {
  @ObservedObject var viewModel: CredentialOfferConsentViewModel<Router>
  @State private var showRequestedClaims = false

  init(with viewModel: CredentialOfferConsentViewModel<Router>) {
    self.viewModel = viewModel
  }
  var body: some View {
    ContentScreenView(
      canScroll: true
    ) {
      HeaderContentView(onClose: viewModel.closeButtonAction, onHelp: viewModel.onHelp)

      content(
        viewState: viewModel.viewState,
        title: .eaaOfferViewTitle,
        subTitle: .eaaOfferViewSubTitle,
        issuerName: viewModel.viewState.documentOfferUiModel.issuerName,
        documentName: viewModel.documentName,
        issuerImageUrl: viewModel.issuerImageUrl?.absoluteString ?? "",
        action: viewModel.primaryButtonAction,
        primaryButtonTitle: viewModel.primaryButtonTitle,
        secondaryAction: viewModel.secondaryButtonAction,
        issuerDetailsAction: viewModel.showIssuerDetails,
        onViewData: { showRequestedClaims = true }
      )
      .padding(.horizontal, DSStyle.Spacers.SPACING_MEDIUM)
    }
    .sheet(isPresented: $showRequestedClaims) {
      RequestedClaimsSheetView(
        title: viewModel.documentName,
        issuer: viewModel.viewState.documentOfferUiModel.issuerName,
        issuerImageUrl: viewModel.issuerImageUrl?.absoluteString ?? "",
        claims: viewModel.viewState.claimNames,
        onClose: { showRequestedClaims = false }
      )
    }
    .centerDialog(
      isPresented: $viewModel.showCancelConfirmationPopup,
      icon: Theme.shared.image.infoCircleImage,
      title: .eaaConsentCancelPopupTitle,
      subtitle: .eaaConsentCancelPopupSubTitle,
      buttons: [
        CustomAlertDialogConfig(
          title: .yesReject,
          role: .destructive
        ) {
          viewModel.cancelIssuance()
        },
        // Dismissing is all this needs to do; the dialog closes itself after any action.
        CustomAlertDialogConfig(
          title: .eaaIssuanceDialogCancelSecButton,
          role: .secondary
        ) { }
      ]
    )
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
    .centerDialog(
      isPresented: $viewModel.showIssuanceFailurePopup,
      icon: Theme.shared.image.infoCircleImage,
      title: .eaaIssuanceFailureTitle,
      subtitle: .eaaIssuanceFailureSubTitle,
      buttons: [
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
}

@MainActor
@ViewBuilder
private func content(
  viewState: CredentialOfferConsentViewState,
  title: LocalizableStringKey,
  subTitle: LocalizableStringKey,
  issuerName: String,
  documentName: String,
  issuerImageUrl: String,
  action: @escaping () -> Void,
  primaryButtonTitle: String,
  secondaryAction: @escaping () -> Void,
  issuerDetailsAction: @escaping () -> Void,
  onViewData: @escaping () -> Void
) -> some View {
  VStack(alignment: .leading, spacing: DSStyle.Spacers.SPACING_MEDIUM_LARGE) {
    DSTitleLabel(title)

    EAACredentialCardView(
      viewHeight: DSStyle.Spacers.SPACING_XXL,
      credentialTitle: documentName,
      issuer: issuerName,
      logoURL: issuerImageUrl,
      backgroundColor: viewState.documentOfferUiModel.backgroundColor,
      onViewData: onViewData
    )

    DSSubTitleLabel(.pidInspectionPidIssuerTitle)

    Button(action: issuerDetailsAction) {
      HStack {
        Theme.shared.image.buildingBlocks
          .frame(width: DSStyle.Spacers.SPACING_LARGE, height: DSStyle.Spacers.SPACING_LARGE)
          .clipped()

        Text(issuerName)
          .font(DSTypography.Body.large)
          .foregroundColor(DSColor.onSurface)
          .fontWeight(DSStyle.FontWeight.regular_400)

        Spacer()

        Theme.shared.image.arrowForward
          .resizable()
          .frame(width: DSStyle.Spacers.SPACING_MEDIUM, height: DSStyle.Spacers.SPACING_MEDIUM)
          .accessibilityIdentifier("showIssuerDetails")
      }
    }
    .buttonStyle(.plain)

    Spacer()

    HStack(spacing: DSStyle.Spacers.SPACING_SMALL) {
      DSSecondaryButton(
        title: LocalizableStringKey.reject.toString,
        action: secondaryAction
      )

      DSPrimaryButton(
        title: primaryButtonTitle,
        action: action
      )
      .accessibilityIdentifier("rpConsentNextButton")
    }
  }
}

private struct RequestedClaimsSheetView: View {
  let title: String
  let issuer: String
  let issuerImageUrl: String
  let claims: [String]
  let onClose: () -> Void

  @State private var sheetHeight: CGFloat = 320
  @State private var claimsHeight: CGFloat = 0

  // The claim list hugs its content but scrolls once it would exceed half the screen.
  private var maxClaimsHeight: CGFloat { UIScreen.main.bounds.height * 0.5 }

  var body: some View {
    VStack(spacing: 0) {
      header

      ScrollView {
        VStack(spacing: 0) {
          ForEach(claims, id: \.self) { claim in
            DSBodyLabel(claim)
              .frame(maxWidth: .infinity, alignment: .leading)
              .padding(.vertical, DSStyle.Spacers.SPACING_MEDIUM)

            Divider()
          }
        }
        .padding(.horizontal, DSStyle.Spacers.SPACING_MEDIUM)
        .background(
          GeometryReader { proxy in
            Color.clear.preference(key: ClaimsHeightPreferenceKey.self, value: proxy.size.height)
          }
        )
      }
      .frame(height: min(claimsHeight, maxClaimsHeight))
      .onPreferenceChange(ClaimsHeightPreferenceKey.self) { claimsHeight = $0 }

      DSSecondaryButton(
        title: LocalizableStringKey.eaaIssuanceDialogCancelSecButton.toString,
        action: onClose
      )
      .padding(DSStyle.Spacers.SPACING_MEDIUM)
    }
    .background(DSColor.surface)
    .background(
      GeometryReader { proxy in
        Color.clear.preference(key: SheetHeightPreferenceKey.self, value: proxy.size.height)
      }
    )
    .onPreferenceChange(SheetHeightPreferenceKey.self) { sheetHeight = $0 }
    .presentationDetents([.height(sheetHeight)])
    .presentationDragIndicator(.hidden)
  }

  private var header: some View {
    VStack(spacing: 0) {
      HStack(alignment: .top, spacing: DSStyle.Spacers.SPACING_MEDIUM) {
        VStack(alignment: .leading, spacing: DSStyle.Spacers.SPACING_EXTRA_SMALL) {
          DSTitleLabel(title)

          DSBodyLabel(issuer)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.leading, DSStyle.Spacers.SPACING_MEDIUM)
        .padding(.vertical, DSStyle.Spacers.SPACING_LARGE_MEDIUM)

        RemoteImageView(urlString: issuerImageUrl)
          .frame(width: Self.logoWidth)
          .frame(maxHeight: .infinity)
          .clipped()
      }
      .fixedSize(horizontal: false, vertical: true)
      Divider()
    }
  }

  /// Width of the issuer logo in the header. `RemoteImageView` fills whatever it is given, so the
  /// frame alone decides how large the logo appears.
  private static let logoWidth: CGFloat = 96
}

private struct SheetHeightPreferenceKey: PreferenceKey {
  static var defaultValue: CGFloat { 0 }
  static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
    value = max(value, nextValue())
  }
}

private struct ClaimsHeightPreferenceKey: PreferenceKey {
  static var defaultValue: CGFloat { 0 }
  static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
    value = max(value, nextValue())
  }
}

#Preview {
  let state = CredentialOfferConsentViewState(
    isLoading: false,
    documentOfferUiModel: .mock(),
    offerUri: "",
    claimNames: ["Vorname", "Familienname", "Geburtsdatum"],
    config: UIConfig.Generic(
      arguments: [:],
      navigationSuccessType: .popTo(.featureIssuanceModule(.credentialOfferRequest(config: NoConfig()))),
      navigationCancelType: .pop
    ),
    initialized: true
  )

  ContentScreenView(canScroll: true) {
    HeaderContentView(onClose: {})

    content(
      viewState: state,
      title: .eaaOfferViewTitle,
      subTitle: .eaaOfferViewSubTitle,
      issuerName: state.documentOfferUiModel.issuerName,
      documentName: "Document Name",
      issuerImageUrl: "https://eudiplo.eudi-wallet.org/storage/f5ec0db5-38e3-4f42-822b-b3c0b638c478",
      action: {}, primaryButtonTitle: "Next",
      secondaryAction: {},
      issuerDetailsAction: {},
      onViewData: {}
    )
    .padding(.horizontal, DSStyle.Spacers.SPACING_MEDIUM)
  }
}

#Preview {
  VStack {
    Spacer()

    RequestedClaimsSheetView(
      title: "Document Name",
      issuer: LocalizableStringKey.unknownIssuer.toString,
      issuerImageUrl: "https://eudiplo.eudi-wallet.org/storage/f5ec0db5-38e3-4f42-822b-b3c0b638c478",
      claims: [
        "Vorname",
        "Familienname",
        "Geburtsdatum",
        "Geburtsort",
        "Staatsangehörigkeit",
        "Anschrift",
        "Ausstellende Behörde",
        "Ausstellungsdatum",
        "Gültig bis"
      ],
      onClose: {}
    )
    .clipShape(RoundedCorner(radius: 20, corners: [.topLeft, .topRight]))
  }
  .background(DSColor.scrim.opacity(0.3))
  .ignoresSafeArea()
}
