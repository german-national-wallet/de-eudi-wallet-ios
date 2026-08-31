//
//  PersonalDetailView.swift
//  feature-dashboard
//

import SwiftUI
import logic_ui
import logic_resources
import logic_core

struct PersonalDetailView<Router: RouterHost>: View {
  @ObservedObject private var viewModel: PersonalDetailViewModel<Router>
  var headerHeightFactor = 0.2
  var headerBackgroundColor: Color? {
    switch viewModel.viewState.documentType {
      case .other:
      return DSColor.getBackgroundColorForCredential(document: viewModel.viewState.document)
      default:
          return nil
      }
  }
  
  public init(with viewModel: PersonalDetailViewModel<Router>) {
    self.viewModel = viewModel
  }
    var body: some View {
      GeometryReader { geometry in
        
        ContentScreenView(padding: 0, background: DSColor.background) {
          VStack {
            let headerHeight = (geometry.size.height * headerHeightFactor) + geometry.safeAreaInsets.top
            
            CredentialDetailsHeader(
              title: LocalizableStringKey.personalData.toString,
              backgroundColor: headerBackgroundColor,
              onBack: viewModel.backButtonTapped
            )
            .frame(height: headerHeight)
            
            ScrollView {
              VStack(alignment: .leading, spacing: 0) {
                ForEach(viewModel.credentialDetailItems, id: \.title) { item in
                  VStack(alignment: .leading, spacing: 0) {
                    PersonalDetailItemView(title: item.title, detail: item.detail)
                      .padding(EdgeInsets(top: 0, leading: DSStyle.Spacers.SPACING_MEDIUM, bottom: DSStyle.Spacers.SPACING_MEDIUM, trailing: DSStyle.Spacers.SPACING_MEDIUM))
                    if item.showDivider {
                      Divider()
                        .padding(.bottom, DSStyle.Spacers.SPACING_MEDIUM)
                    }
                  }
                }
              }
            }
            .padding(.top, DSStyle.Spacers.SPACING_MEDIUM)
            Spacer()
          }
        }
      }
    }
  
  private struct PersonalDetailItemView: View {
    let title: String
    let detail: String
    let showDivider: Bool = false
    
    var body: some View {
      VStack(alignment: .leading, spacing: DSStyle.Spacers.SPACING_MEDIUM_SMALL) {
        HStack {
          VStack {
              Text(title)
                .font(DSTypography.Label.large)
                .foregroundColor(DSColor.onBackgroundVariant)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text(detail)
              .font(DSTypography.Body.large)
              .foregroundColor(DSColor.onBackground)
              .frame(maxWidth: .infinity, alignment: .leading)
          }
          Spacer()
        }
      }
    }
  }
}
