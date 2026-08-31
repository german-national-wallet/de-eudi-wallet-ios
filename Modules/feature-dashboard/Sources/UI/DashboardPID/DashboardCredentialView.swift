//
//  SwiftUIView.swift
//  feature-dashboard
//

import SwiftUI
import logic_ui
import logic_resources
import logic_core
import feature_common

struct DashboardCredentialView<Router: RouterHost>: View {
  @ObservedObject private var viewModel: DashboardCredentialViewModel<Router>
  var headerHeightFactor = 0.28
  private let eaaCardHeight: CGFloat = 120
  private let verticalStackSpacing: CGFloat = -44
  
  @State private var showWebView = false
  private let verifier: String = "https://playground.eudi-wallet.org/"

  public init(with viewModel: DashboardCredentialViewModel<Router>) {
    self.viewModel = viewModel
  }

  var body: some View {
    GeometryReader { geometry in
      let totalHeight = geometry.size.height
      let headerHeight = totalHeight * headerHeightFactor

      ContentScreenView(
        padding: .zero,
        background: DSColor.background
      ) {
        VStack {
          HStack {
            Button(action: {
              viewModel.onMenuTap()
            }, label: {
              Theme.shared.image.burgerMenu
            })
            .padding()
            Spacer()
          }
          ScrollView(.vertical, showsIndicators: false) {
          if viewModel.isPIDAvailable {
            PIDCredentialCardView(
              viewHeight: headerHeight,
              credentialTitle: viewModel.pidName,
              additionalDescription: viewModel.fullName
            )
              .onTapGesture {
                viewModel.onTap()
              }
              .padding()
          } else {
            AddPIDCredentialView(action: viewModel.performIssuance)
          }

            if viewModel.showAdditionalDocuments {
              VStack(spacing: verticalStackSpacing) {
                ForEach(viewModel.additionalDocuments ?? [], id: \.id) { document in
                  let credentialLogo = document.display?.first?.logo?.urlString
                  let displayName = document.displayName ?? document.docType
                  EAACredentialCardView(
                    viewHeight: eaaCardHeight,
                    credentialTitle: displayName,
                    issuer: document.issuerName,
                    logoURL: credentialLogo,
                    backgroundColor: DSColor.getBackgroundColorForCredential(document: document),
                    backgroundImageURL: getBackgroundImage(document: document)
                  )
                  .onTapGesture {
                    viewModel.onTap(additionalDocument: document)
                  }
                }
              }
              .padding(.horizontal)
              .padding(.top, 20)
              .padding(.bottom, 150)
              
            }

          Spacer()

          // UITests only: button for triggering deeplink UI Test
          if AppEnvironment.isUITesting {
            Button("Trigger presentation") {
              showWebView = true
            }
            .accessibilityIdentifier("deeplinkTriggerButton")
          }
        }
        .background(DisableSwipeBackGesture())
        .sheet(isPresented: $showWebView) {
          if let url = URL(string: verifier) {
            NavigationView {
              VStack {
                Text("Loading: \(url.absoluteString)")
                  .font(.caption)
                  .foregroundColor(.gray)
                  .padding()

                WebViewContainer(url: url)
                  .frame(maxWidth: .infinity, maxHeight: .infinity)
              }
              .navigationTitle("Trigger presentation")
              .navigationBarTitleDisplayMode(.inline)
              .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                  Button("Done") {
                    showWebView = false
                  }
                  .accessibilityIdentifier("closeWebViewButton")
                }
              }
            }
          }
        }
        .onAppear {
          viewModel.getMainPIDDocument()
          viewModel.getAdditionalDocuments()
        }
        .task {
          await viewModel.handleDeepLink()
        }
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
}

// TODO: Refactor / fix AdditionalCredentialCard dashboard UI

private struct AdditionalCredentialCard: View {
  let documentName: String
  let onTap: () -> Void

  var body: some View {
    Button(action: onTap) {
      VStack(alignment: .leading, spacing: 8) {
        HStack {
          Text(documentName)
            .font(DSTypography.Body.medium)
            .foregroundColor(DSColor.onSurface)
            .lineLimit(2)
            .multilineTextAlignment(.leading)

          Spacer()

          Theme.shared.image.chevronRight
            .renderingMode(.template)
            .foregroundStyle(DSColor.primary)
            .frame(width: 16, height: 16)
        }
      }
      .padding()
      .frame(width: 200, height: 80)
      .background(DSColor.onPrimary)
      .clipShape(RoundedRectangle(cornerRadius: DSStyle.Spacers.SPACING_MEDIUM_SMALL))
      .overlay(
        RoundedRectangle(cornerRadius: DSStyle.Spacers.SPACING_MEDIUM_SMALL)
          .stroke(DSColor.outlineVariant, lineWidth: 1)
      )
    }
    .buttonStyle(PlainButtonStyle())
  }
}

// MARK: - Credential Details Sheet View
private struct CredentialDetailsSheetView: View {
  let document: DocClaimsDecodable
  let onDelete: () -> Void
  let onDismiss: () -> Void
  
  var body: some View {
    VStack(alignment: .leading, spacing: DSStyle.Spacers.SPACING_MEDIUM) {
      // Header
      HStack {
        VStack(alignment: .leading, spacing: 4) {
          Text(document.displayName ?? document.docType ?? "Credential")
            .font(DSTypography.Title.large)
            .foregroundColor(DSColor.onSurface)
          
          if let issuerName = document.issuerDisplay?.first?.name, !issuerName.isEmpty {
            Text(issuerName)
              .font(DSTypography.Body.medium)
              .foregroundColor(DSColor.onSurfaceVariant)
          }
        }
        
        Spacer()
        
        Button(action: onDismiss) {
          Image(systemName: "xmark.circle.fill")
            .foregroundColor(DSColor.onSurfaceVariant)
            .font(.system(size: 24))
        }
      }
      .padding(.horizontal, DSStyle.Spacers.SPACING_MEDIUM)
      .padding(.top, DSStyle.Spacers.SPACING_MEDIUM)
      
      Divider()
      
      // Document Details
      ScrollView {
        VStack(alignment: .leading, spacing: DSStyle.Spacers.SPACING_MEDIUM) {
          // Display all claims dynamically
          ForEach(getDisplayableClaims(), id: \.name) { claim in
            VStack(alignment: .leading, spacing: 4) {
              Text(claim.name)
                .font(DSTypography.Title.small)
                .foregroundColor(DSColor.onSurfaceVariant)
              
              Text(claim.value)
                .font(DSTypography.Body.large)
                .foregroundColor(DSColor.onSurface)
            }
            .padding(.horizontal, DSStyle.Spacers.SPACING_MEDIUM)
            
            Divider()
              .padding(.horizontal, DSStyle.Spacers.SPACING_MEDIUM)
          }
          
          // TODO: - To be fixed in the UI Ticket
          DSPrimaryButton(title: "Delete credential", action: onDelete)
        }
        .padding(.vertical, DSStyle.Spacers.SPACING_SMALL)
      }
    }
    .background(DSColor.background)
  }
  
  private func getDisplayableClaims() -> [(name: String, value: String)] {
    var claims: [(name: String, value: String)] = []
    
    // Add all claims as they are
    for claim in document.docClaims {
      let value = claim.stringValue.isEmpty ? claim.dataValue.description : claim.stringValue
      
      if !value.isEmpty {
        claims.append((name: claim.name, value: value))
      }
    }
    
    return claims
  }
  
}
