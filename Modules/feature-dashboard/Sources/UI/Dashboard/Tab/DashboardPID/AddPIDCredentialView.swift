//
//  AddPIDCredentialView.swift
//  feature-dashboard
//

import SwiftUI
import logic_ui
import logic_business
import logic_core
import logic_resources

struct AddPIDCredentialView: View {
  
  @ObservedObject var appState = AppState.shared
  private let showsSimulatedEIDCardToggle = AppBuildVariant.current.offersSimulatedEIDCard
  let action: () -> Void
  
  init(action: @escaping () -> Void) {
    self.action = action
  }
  
  var body: some View {
    ScrollView {
      VStack(spacing: 0) {
        VStack(alignment: .leading) {
          DSTitleLabel(.chooseFromListTitle, font: DSTypography.Headline.medium)
            .padding()
            .padding(.top)
          
          HStack {
            Spacer()
            Theme.shared.image.backgroundPID
            Spacer()
          }
          Spacer()
          HStack {
            Text(.dashboardScreenSecondaryText)
              .font(DSTypography.Body.medium)
              .foregroundStyle(DSColor.onSurface)
            Spacer(minLength: 45)
            DSPrimaryButton(title: LocalizableStringKey.dashboardPrimaryButtonTitle.toString, action: action)
            .accessibilityIdentifier("dashboardPrimaryButton")
          }
          .padding(.vertical, 23)
          .padding(.horizontal, 13)
          .background {
            Rectangle()
              .foregroundStyle(DSColor.backgroundPIDMedium)
              .border(DSColor.outlineVariant, width: 1)
          }
        }

        if showsSimulatedEIDCardToggle {
          Toggle(isOn: $appState.useSimulatedEIDCard) {
            Text(.pidInspectionInitialDashboardTempLabel1)
              .foregroundStyle(DSColor.onSurface)
              .font(DSTypography.Body.medium)
              .bold()
          }
          .toggleStyle(DSToggle.TintedToggleStyle())
          .accessibilityIdentifier("pidSimulatedEidCardToggle")
          .padding()
        }
      }
      .background {
        RoundedRectangle(cornerRadius: 12)
          .fill(DSColor.backgroundPIDLight)
      }
      .clipShape(RoundedRectangle(cornerRadius: 12))
      .overlay {
        RoundedRectangle(cornerRadius: 12)
          .stroke(DSColor.outlineVariant, lineWidth: 1)
      }
      .padding(.horizontal, Theme.shared.dimension.padding)
      .padding(.bottom)
      .padding(.top)
      
    }
    .ignoresSafeArea(edges: .bottom)
  }
}
