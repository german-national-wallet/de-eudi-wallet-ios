//
//  CredentialClaimsSheetView.swift
//  logic-ui
//

import SwiftUI
import logic_resources

public struct CredentialClaimsSheetView: View {
  private let title: String
  private let issuer: String
  private let issuerImageUrl: String
  private let logo: Image?
  private let claims: [String]
  private let onClose: () -> Void

  public init(
    title: String,
    issuer: String,
    issuerImageUrl: String,
    logo: Image? = nil,
    claims: [String],
    onClose: @escaping () -> Void
  ) {
    self.title = title
    self.issuer = issuer
    self.issuerImageUrl = issuerImageUrl
    self.logo = logo
    self.claims = claims
    self.onClose = onClose
  }

  @State private var sheetHeight: CGFloat = 320
  @State private var claimsHeight: CGFloat = 0

  private var maxClaimsHeight: CGFloat { UIScreen.main.bounds.height * 0.5 }

  public var body: some View {
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
        .padding(.trailing, hasLogo ? 0 : DSStyle.Spacers.SPACING_MEDIUM)
        .padding(.vertical, DSStyle.Spacers.SPACING_LARGE_MEDIUM)

        if let logo {
          logo
            .resizable()
            .scaledToFit()
            .frame(width: Self.logoWidth)
            .padding(.vertical, DSStyle.Spacers.SPACING_MEDIUM)
            .accessibilityHidden(true)
        } else if !issuerImageUrl.isEmpty {
          RemoteImageView(urlString: issuerImageUrl)
            .frame(width: Self.logoWidth)
            .frame(maxHeight: .infinity)
            .clipped()
        }
      }
      .fixedSize(horizontal: false, vertical: true)
      Divider()
    }
  }

  private var hasLogo: Bool {
    logo != nil || !issuerImageUrl.isEmpty
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
