//
//  CredentialTeaserView.swift
//  feature-common
//
//  Created by Ameen Qadri on 02.11.26.
//

import SwiftUI
import logic_ui
import logic_resources
import logic_core

public struct CredentialTeaserView: View {

  @State private var isCredentialCatalogueVisible = false

  public init() {}

  public var body: some View {
    HStack(spacing: 8) {
      Theme.shared.image.credentialTeaserCards
        .accessibilityHidden(true)
      Text(.initialCredentialTeaserLabel)
        .font(DSTypography.Label.large)
        .foregroundStyle(DSColor.onSurface)
        .frame(maxWidth: .infinity, alignment: .leading)
      Button {
        isCredentialCatalogueVisible = true
      } label: {
        Theme.shared.image.plus
          .renderingMode(.template)
          .resizable()
          .scaledToFit()
          .frame(width: 24, height: 24)
          .foregroundStyle(DSColor.onSurface)
          .padding(8)
          .background(Circle().fill(DSColor.secondaryContainer))
          .overlay(Circle().strokeBorder(DSColor.outline, lineWidth: 1))
          .padding(4)
      }
      .accessibilityLabel(Text(.initialCredentialTeaserButtonA11y))
      .accessibilityIdentifier("credentialCatalogueButton")
    }
    .padding(.vertical, 12)
    .padding(.trailing, 12)
    .background(DSColor.surfaceContainer)
    .clipShape(RoundedRectangle(cornerRadius: 24))
    .sheet(isPresented: $isCredentialCatalogueVisible) {
      if let url = AppEnvironment.credentialCatalogueLink {
        SafariView(url: url)
          .ignoresSafeArea()
      }
    }
  }
}
