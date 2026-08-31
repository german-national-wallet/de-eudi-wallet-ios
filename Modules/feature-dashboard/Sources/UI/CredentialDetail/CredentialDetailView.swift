//
//  CredentialDetailView.swift
//  feature-dashboard
//

import SwiftUI
import logic_ui
import logic_resources
import logic_core
import feature_common

struct CredentialDetailView<Router: RouterHost>: View {
  @ObservedObject private var viewModel: CredentialDetailViewModel<Router>

  public init(with viewModel: CredentialDetailViewModel<Router>) {
    self.viewModel = viewModel
  }
  
  var body: some View {
    GeometryReader { geometry in
      ContentScreenView(padding: 0, background: DSColor.background) {
        VStack {
          let backgroundImageURL = getBackgroundImage(document: viewModel.viewState.document)
          let credentialLogo = viewModel.viewState.document.display?.first?.logo?.urlString

          CredentialDetailsHeader(
            title: viewModel.documentName,
            issuer: viewModel.viewState.document.issuerName,
            logoURL: credentialLogo ?? "",
            backgroundColor: viewModel.isCredentialPID() ? nil : DSColor.getBackgroundColorForCredential(
              document: viewModel.viewState.document
            ),
            backgroundImageURL: backgroundImageURL,
            onBack: viewModel.backButtonTapped
          )
          .frame(width: geometry.size.width, height: geometry.size.height / 3)

          VStack {
            VStack(spacing: DSStyle.Spacers.SPACING_MEDIUM_LARGE) {
              Button(action: {
                viewModel.viewProfileDetailTapped()
              }, label: {
                UserProfileItemView(title: nil, detail: LocalizableStringKey.personalData.toString, icon: Theme.shared.image.personOutline, showDetailIcon: true)
              })
              
              // TODO: - Currently not implemented.
              // UserProfileItemView(title: nil, detail: LocalizableStringKey.distributor.toString, icon: Theme.shared.image.apartment, showDetailIcon: true)

            }
            .padding(.top, DSStyle.Spacers.SPACING_MEDIUM)
            
            Spacer()
            
            VStack(spacing: DSStyle.Spacers.SPACING_MEDIUM_LARGE) {
              UserProfileItemView(title: LocalizableStringKey.validInUntil.toString, detail: viewModel.validityDate, icon: Theme.shared.image.event)
              UserProfileItemView(title: LocalizableStringKey.createdOn.toString, detail: viewModel.documentIssuanceDate, icon: Theme.shared.image.idCard)
            }
            .padding(.bottom, DSStyle.Spacers.SPACING_MEDIUM)
            
            // TODO: - We need to fix how to stay consistent with dynamic localisation, otherwise whenever we pull UX tokens this will break.
            
            DSSecondaryButton(
              title: viewModel.isCredentialPID() ? LocalizableStringKey.deletePID([viewModel.documentName]).toString : "Delete",
              action: {
                Task {
                  try await viewModel.deleteCredential()
                }
              }
            )
            .accessibilityIdentifier("deleteButton")
          }
          .padding(EdgeInsets(top: 0, leading: DSStyle.Spacers.SPACING_MEDIUM, bottom: 0, trailing: DSStyle.Spacers.SPACING_MEDIUM))
        }
      }
      .navigationBarBackButtonHidden()
      .background(EnableSwipeBackGesture())
      .overlay {
        if viewModel.isErrorPopupVisible {
          ConfirmationPopupView(viewModel: viewModel.errorPopupViewModel)
        }
      }
    }
  }
  
  func getBackgroundImage(document: DocClaimsDecodable) -> String {
      let currentLanguage = Locale.current.language.languageCode?.identifier
      let localisedDisplay = document.display?.first { display in
          let displayLanguage = display.localeIdentifier?.split(separator: "-").first
          return String(displayLanguage ?? "") == currentLanguage
      }
      return localisedDisplay?.backgroundImageURL ?? ""
  }
  
  private struct UserProfileItemView: View {
    let title: String?
    let detail: String?
    let icon: Image
    let showDetailIcon: Bool?
    
    init(title: String?, detail: String?, icon: Image, showDetailIcon: Bool? = false) {
      self.title = title
      self.detail = detail
      self.icon = icon
      self.showDetailIcon = showDetailIcon
    }
    
    var body: some View {
      VStack(alignment: .leading, spacing: DSStyle.Spacers.SPACING_EXTRA_SMALL) {
        HStack {
          icon
            .resizable()
            .scaledToFit()
            .frame(width: DSStyle.Spacers.SPACING_LARGE_MEDIUM, height: DSStyle.Spacers.SPACING_LARGE_MEDIUM)
          VStack {
            if let title {
              Text(title)
                .font(DSTypography.Label.large)
                .foregroundColor(DSColor.onBackgroundVariant)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            if let detail {
              HStack {
                Text(detail)
                  .font(DSTypography.Body.large)
                  .foregroundColor(DSColor.onBackground)
                  .frame(maxWidth: .infinity, alignment: .leading)
                Spacer()
                if showDetailIcon == true {
                  Theme.shared.image.arrowRight
                    .resizable()
                    .scaledToFit()
                    .frame(width: DSStyle.Spacers.SPACING_LARGE_MEDIUM, height: DSStyle.Spacers.SPACING_LARGE_MEDIUM)
                }
              }
            }
          }
          .padding(.leading, DSStyle.Spacers.SPACING_SMALL)
        }
      }
    }
  }
}
