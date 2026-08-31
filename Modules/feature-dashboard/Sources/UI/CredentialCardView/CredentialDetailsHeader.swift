//
//  CredentialDetailsHeader.swift
//  feature-dashboard
//

import SwiftUI
import logic_resources
import logic_ui

struct CredentialDetailsHeader: View {

  private enum Layout {
    static let cardHeight: CGFloat = 90
    static let logoPanelWidth: CGFloat = 100
    static let logoMaxWidth: CGFloat = 80
    static let logoMaxHeight: CGFloat = 60
    static let logoPadding: CGFloat = DSStyle.Spacers.SPACING_MEDIUM_SMALL
    static let logoTopPadding: CGFloat = DSStyle.Spacers.SPACING_SMALL
  }

  private let title: String
  private let issuer: String
  private let logoURL: String
  private let backgroundColor: Color?
  private let backgroundImageURL: String
  let onBack: () -> Void

  public init(
    title: String,
    issuer: String = "",
    logoURL: String = "",
    backgroundColor: Color?,
    backgroundImageURL: String = "",
    onBack: @escaping () -> Void
  ) {
    self.title = title
    self.issuer = issuer
    self.logoURL = logoURL
    self.backgroundColor = backgroundColor
    self.backgroundImageURL = backgroundImageURL
    self.onBack = onBack
  }

  private var hasBackgroundImage: Bool {
    !backgroundImageURL.isEmpty
  }

  var body: some View {
    if hasBackgroundImage {
      imageLayout
    } else {
      colorLayout
    }
  }

  // MARK: - Image layout: background image fills the header, credential card overlaps the bottom

  private var imageLayout: some View {
    ZStack(alignment: .topLeading) {
      GeometryReader { geometry in
        ZStack(alignment: .bottom) {
          AsyncImage(
            url: URL(string: backgroundImageURL),
            transaction: Transaction(animation: .easeInOut(duration: 0.25))
          ) { phase in
            switch phase {
            case .success(let image):
              image
                .resizable()
                .scaledToFill()
            case .empty:
              Color.clear
                .overlay(ProgressView())
            default:
              Color.clear
            }
          }
          .frame(width: geometry.size.width, height: geometry.size.height)
          .clipped()

          credentialInfoCard
            .frame(width: geometry.size.width)
        }
      }
      .ignoresSafeArea(edges: .top)

      backButton
    }
  }

  private var backButton: some View {
    Button(action: onBack) {
      Theme.shared.image.backButtonIcon
        .resizable()
        .scaledToFit()
        .frame(width: DSStyle.Spacers.SPACING_EXTRA_LARGE, height: DSStyle.Spacers.SPACING_EXTRA_LARGE)
    }
    .padding([.top, .leading], DSStyle.Spacers.SPACING_MEDIUM)
  }

  private var credentialInfoCard: some View {
    HStack(spacing: 0) {
      VStack(alignment: .leading, spacing: DSStyle.Spacers.SPACING_EXTRA_SMALL) {
        Text(title)
          .font(DSTypography.Title.medium)
          .foregroundColor(DSColor.onSurface)
          .accessibilityIdentifier("credentialTitleView")

        if !issuer.isEmpty {
          Text(issuer)
            .font(DSTypography.Body.medium)
            .foregroundColor(DSColor.onSurfaceVariant)
        }
      }
      .padding(DSStyle.Spacers.SPACING_MEDIUM)
      .frame(maxWidth: .infinity, alignment: .leading)

      logoPanel
    }
    .frame(height: Layout.cardHeight)
    .background(DSColor.surface)
    .clipShape(RoundedCorner(radius: DSStyle.Sizes.CornerRadius.large, corners: [.topLeft, .topRight]))
    // Light-grey separator underneath the header card.
    .overlay(alignment: .bottom) {
      Rectangle()
        .fill(DSColor.tertiaryContainer)
        .frame(height: 1)
    }
  }

  private var logoPanel: some View {
    (backgroundColor ?? DSColor.colorPID)
      .frame(width: Layout.logoPanelWidth)
      .overlay {
        if !logoURL.isEmpty {
          logo
        }
      }
  }

  private var logo: some View {
    AsyncImage(
      url: URL(string: logoURL),
      transaction: Transaction(animation: .easeInOut(duration: 0.25))
    ) { phase in
      if case .success(let image) = phase {
        image
          .resizable()
          .scaledToFit()
      } else {
        Color.clear
      }
    }
    .frame(maxWidth: Layout.logoMaxWidth, maxHeight: Layout.logoMaxHeight)
    .padding(.horizontal, Layout.logoPadding)
    .padding(.top, Layout.logoTopPadding)
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
  }

  // MARK: - Color layout: solid brand color / PID eagle with title (no background image)

  private var colorLayout: some View {
    VStack {
      HeaderContentView(onBack: onBack)

      Spacer()

      HStack {
        DSTitleLabel(title, color: .white)
        Spacer()
      }
      .padding(.leading, DSStyle.Spacers.SPACING_MEDIUM)
      .padding(.bottom, DSStyle.Spacers.SPACING_LARGE_MEDIUM)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(colorBackground)
    .clipped()
  }

  @ViewBuilder
  private var colorBackground: some View {
    if let backgroundColor {
      backgroundColor
    } else {
      ZStack(alignment: .trailing) {
        DSColor.colorPID
        Theme.shared.image.deEagleWingCroppedImage
          .resizable()
          .aspectRatio(contentMode: .fit)
      }
    }
  }
}
