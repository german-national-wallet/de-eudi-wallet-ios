//
//  IssuerDetailsView.swift
//  feature-issuance
//

import SwiftUI
import feature_common
import logic_ui

struct IssuerDetailsView<Router: RouterHost>: View {
  
  @ObservedObject private var viewModel: IssuerDetailsViewModel<Router>
  @State private var showInfoSheet: Bool
  
  let columns = [
    GridItem(.flexible(), alignment: .leading),
    GridItem(.flexible(), alignment: .leading)
  ]
  
  init(with viewModel: IssuerDetailsViewModel<Router>) {
    self.viewModel = viewModel
    self.showInfoSheet = false
  }
  
  var body: some View {
    GeometryReader { _ in
      ContentScreenView {
        VStack {
          HeaderContentView(onBack: viewModel.backButtonTapped)
          
          ScrollView {
            VStack(alignment: .leading, spacing: 24) {
              DSTitleLabel(.eaaIssuerInfoTitle)

              if let logoURL = viewModel.viewState.config.issuerDetails.logoURL {
                RemoteImageView(urlString: logoURL)
                  .frame(width: 70, height: 70)
                  .clipped()
              } else {
                viewModel.viewState.config.issuerDetails.logo
                  .resizable()
                  .frame(width: 70, height: 70)
              }

              let details = viewModel.viewState.config.issuerDetails
              if !details.name.isEmpty {
                PidIssuerDetailsCell(
                  title: .name,
                  value: details.name,
                  imageIcon: Theme.shared.image.balance
                )
              }
              if !details.address.isEmpty {
                PidIssuerDetailsCell(
                  title: .address,
                  value: details.address,
                  imageIcon: Theme.shared.image.locationOn
                )
              }

              if !details.email.isEmpty {
                PidIssuerDetailsCell(
                  title: .email,
                  value: details.email,
                  imageIcon: Theme.shared.image.language
                )
              }

              if !details.dataProtectionURL.isEmpty {
                PidIssuerDetailsCell(
                  title: .privacyPolicy,
                  value: details.dataProtectionURL,
                  imageIcon: Theme.shared.image.verifiedUser
                )
              }

              if !details.certificateExpirationDate.isEmpty {
                PidIssuerDetailsCell(
                  title: .certificateValidUntil,
                  value: details.certificateExpirationDate,
                  imageIcon: Theme.shared.image.storefront
                )
              }
            }
          }
          .padding()
          
          DSSecondaryButton(
            title: LocalizableStringKey.reportProblem.toString,
            trailingIcon: Theme.shared.image.externalLink,
            action: viewModel.reportProblem
          )
          .padding()
        }
        .scrollIndicators(.hidden)
        .sheet(isPresented: $showInfoSheet) {
          BottomSheetView(
            title: LocalizableStringKey.whyIsThisDataNeededTitle.toString,
            message: LocalizableStringKey.whyIsThisDataNeededDescription.toString
          )
        }
        .background(DSColor.background)
      }
    }
  }
  
  private struct PidIssuerDetailsCell: View {
    let title: LocalizableStringKey
    let value: String
    let imageIcon: Image
    
    var body: some View {
      HStack {
        imageIcon
        
        VStack(alignment: .leading) {
          Text(title)
            .foregroundStyle(DSColor.onBackground)
            .font(DSTypography.Body.large)
            .fontWeight(DSStyle.FontWeight.regular_400)
            .kerning(DSStyle.FontKerning.regular)
          
          Text(value)
            .foregroundStyle(DSColor.onBackground)
            .font(DSTypography.Body.large)
            .kerning(DSStyle.FontKerning.regular)
        }
        Spacer()
      }
    }
  }
}
