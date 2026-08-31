//
//  ConsentView.swift
//  feature-presentation
//

import SwiftUI
import feature_common
import logic_ui

struct ConsentView<Router: RouterHost>: View {
  
  @ObservedObject private var viewModel: ConsentViewModel<Router>
  @State private var showDetails: Bool
  @State private var showInfoSheet: Bool
  
  let columns = [
          GridItem(.flexible(), alignment: .leading),
          GridItem(.flexible(), alignment: .leading)
      ]
  
  init(with viewModel: ConsentViewModel<Router>) {
    self.viewModel = viewModel
    self.showDetails = false
    self.showInfoSheet = false
  }
  
  var body: some View {
    ContentScreenView {
      ZStack {
        VStack {
          HeaderContentView(onBack: viewModel.backButtonTapped, onClose: viewModel.closeButtonTapped)
          
          ScrollView {
            VStack(alignment: .leading, spacing: DSStyle.Spacers.SPACING_LARGE_MEDIUM) {
              
              DSTitleLabel(.rpConsentTitle)
                .padding(.bottom, DSStyle.Spacers.SPACING_MEDIUM)
              
              VStack(alignment: .leading, spacing: DSStyle.Spacers.SPACING_MEDIUM) {
                ForEach(viewModel.consentItemGroups.indices, id: \.self) { groupIndex in
                  let group = viewModel.consentItemGroups[groupIndex]
                  consentCardView(group: group)
                }
              }
              .frame(maxWidth: .infinity)
              
              DSSecondaryButton(
                title: (showDetails ? LocalizableStringKey.hideDetails : LocalizableStringKey.showDetails).toString,
                icon: showDetails ? Theme.shared.image.eyeIconOff : Theme.shared.image.eyeIcon
              ) {
                showDetails.toggle()
              }
            }
            .padding(.bottom, DSStyle.Spacers.SPACING_MEDIUM)
          }
          .padding()
          HStack {
            DSSecondaryButton(
              title: LocalizableStringKey.reject.toString,
              action: viewModel.onDecline
            )
            DSPrimaryButton(
              title: LocalizableStringKey.next.toString,
              action: viewModel.onShare
            )
            .accessibilityIdentifier("rpConsentNextButton")
          }
          .padding(DSStyle.Spacers.SPACING_MEDIUM)
        }
        
        if viewModel.isConfirmationPopupVisible {
          ConfirmationPopupView(viewModel: viewModel.confirmationPopupViewModel)
            .transition(.scale)
        }
      }
      .scrollIndicators(.hidden)
      .task {
        await viewModel.doWork()
      }
      .sheet(isPresented: $showInfoSheet) {
        BottomSheetView(
          title: LocalizableStringKey.whyIsThisDataNeededTitle.toString,
          message: LocalizableStringKey.whyIsThisDataNeededDescription.toString
        )
      }
      .background(DSColor.background)
    }
   }
  
  private func consentCardView(group: ConsentItemGroup) -> some View {
    VStack(alignment: .leading) {
      HStack {
        Text(
          .consentViewHeader(
            group.items.count,
            viewModel.interactor.getClaimCount(documentID: group.credentialID),
            group.credentialTitle
          ))
          .foregroundStyle(DSColor.onColorPID)
          .font(DSTypography.Title.medium)
        Spacer()
        Button { showInfoSheet.toggle() } label: {
          Image(systemName: "info.circle")
            .foregroundColor(DSColor.onColorPID)
            .frame(width: DSIconSize.large, height: DSIconSize.large)
        }
      }
      .frame(height: DSStyle.Spacers.SPACING_EXTRA_LARGE)
      .font(.headline)
      .foregroundColor(.white)
      .padding()
      .frame(maxWidth: .infinity, alignment: .leading)
      .background(DSColor.colorPID)
      .clipShape(RoundedCorner(radius: DSStyle.Sizes.CornerRadius.medium, corners: [.topLeft, .topRight]))

      consentListView(items: group.items, showDetails: showDetails)
    }
    .frame(maxWidth: .infinity)
    .overlay(
      RoundedRectangle(cornerRadius: DSStyle.Sizes.CornerRadius.medium)
        .stroke(DSColor.outlineVariant, lineWidth: 1)
    )
  }

  private func consentListView(items: [ConsentItem], showDetails: Bool) -> some View {
    VStack(alignment: .leading, spacing: DSStyle.Spacers.SPACING_LARGE_MEDIUM) {
      if showDetails {
        ForEach(items.indices, id: \.self) { index in
          let item = items[index]
          ConsentItemView(
            title: LocalizableStringKey.dynamic(key: item.title).toString,
            detail: item.description
          )
        }
        .transition(.opacity.combined(with: .move(edge: .top)))
        
      } else {
        LazyVGrid(columns: columns, spacing: DSStyle.Spacers.SPACING_MEDIUM) {
          let data = items
          ForEach(data.indices, id: \.self) { index in
           ConsentItemView(
              title: LocalizableStringKey.dynamic(key: data[index].title).toString)
          }
        }
        .transition(.opacity.combined(with: .move(edge: .bottom)))
      }
    }
    .padding()
    .padding(.bottom, DSStyle.Spacers.SPACING_LARGE)
    .animation(.easeInOut(duration: 0.3), value: showDetails)
  }
}

private struct ConsentItemView: View {
  let title: String
  let detail: String?
  
  init(title: String, detail: String? = nil) {
    self.title = title
    self.detail = detail
  }
  
  var body: some View {
    VStack(alignment: .leading, spacing: DSStyle.Spacers.SPACING_EXTRA_SMALL) {
      Text(title)
        .font(DSTypography.Label.large)
        .foregroundColor(DSColor.onSurfaceVariant)
        .frame(maxWidth: .infinity, alignment: .leading)
      
      if let detail {
        Text(detail)
          .font(DSTypography.Label.large)
          .foregroundColor(DSColor.onSurfaceVariant)
          .frame(maxWidth: .infinity, alignment: .leading)
      }
    }
      
  }
}
