//
//  PIDTeaserView.swift
//  feature-common
//
//  Created by Ameen Qadri on 02.11.26.
//

import SwiftUI
import logic_ui
import logic_resources
import logic_business
import logic_core

public struct PIDTeaserView: View {

  @ObservedObject private var appState = AppState.shared
  private let showsSimulatedEIDCardToggle = AppBuildVariant.current.offersSimulatedEIDCard
  private let action: () -> Void

  public init(action: @escaping () -> Void) {
    self.action = action
  }

  public var body: some View {
    VStack {
      VStack(spacing: -55) {
        VStack(spacing: 12) {
          DSTitleLabel(.initialPidTeaserTitle, font: DSTypography.Headline.medium)
            .frame(maxWidth: .infinity, alignment: .leading)

          Theme.shared.image.backgroundPID
            .mask(
              LinearGradient(
                stops: [
                  .init(color: .black, location: 0.45),
                  .init(color: .clear, location: 0.7)
                ],
                startPoint: .top,
                endPoint: .bottom
              )
            )
        }
        .padding([.top, .horizontal], 16)

        DSPrimaryButton(
          title: LocalizableStringKey.initialPidTeaserPrimaryButton.toString,
          leadingIcon: Theme.shared.image.plus,
          action: action
        )
        .accessibilityIdentifier("dashboardPrimaryButton")
        .padding([.horizontal, .bottom], 16)
      }

      if showsSimulatedEIDCardToggle {
        Toggle(isOn: $appState.useSimulatedEIDCard) {
          Text(.pidInspectionInitialDashboardTempLabel1)
            .foregroundStyle(DSColor.onSurface)
            .font(DSTypography.Label.large)
        }
        .toggleStyle(DSToggle.TintedToggleStyle(activeHandleBackground: DSColor.onSurface))
        .accessibilityIdentifier("pidSimulatedEidCardToggle")
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(DSColor.surfaceContainerHigh)
      }
    }
    .background(DSColor.surfaceContainer)
    .clipShape(RoundedRectangle(cornerRadius: 24))
  }
}
