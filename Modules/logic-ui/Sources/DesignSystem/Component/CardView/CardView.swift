//
//  CardView.swift
//  logic-ui
//

import SwiftUI
import logic_resources

public struct CardView: View {
  private var viewHeight: CGFloat
  private var backGroundColor: Color
  private var title: String
  private var detail: [String]

  @State private var isExpanded: Bool = false

  public init (
    viewHeight: CGFloat = 210,
    backGroundColor: Color  = DSColor.onSurfaceVariant,
    title: String,
    detail: [String]
  ) {
    self.viewHeight = viewHeight
    self.backGroundColor = backGroundColor
    self.title = title
    self.detail = detail
  }

  let columns = [
    GridItem(.flexible(), alignment: .leading),
    GridItem(.flexible(), alignment: .leading)
  ]

  public var body: some View {
    RoundedRectangle(cornerRadius: DSStyle.Spacers.SPACING_MEDIUM_SMALL)
      .fill(backGroundColor)
      .frame(height: viewHeight)
      .overlay(
        ZStack(alignment: .trailing) {
          VStack(alignment: .leading, spacing: DSStyle.Spacers.SPACING_SMALL) {
            Button(action: {
              withAnimation(.easeInOut(duration: 0.25)) {
                isExpanded.toggle()
              }
            },
                   label: {
              HStack {
                Text(title)
                  .font(DSTypography.Title.medium)
                  .foregroundColor(DSColor.onColorPID)
                  .accessibilityIdentifier("digitalEAATitleView")

                Spacer()
                Theme.shared.image.arrowheadDown
                  .resizable()
                  .frame(
                    width: DSStyle.Spacers.SPACING_LARGE_MEDIUM,
                    height: DSStyle.Spacers.SPACING_LARGE_MEDIUM
                  )
                  .rotationEffect(.degrees(isExpanded ? 180 : 0))
                  .animation(.easeInOut(duration: 0.25), value: isExpanded)
              }
              .padding(DSStyle.Spacers.SPACING_SMALL)
            }
            )
            .padding(.leading, DSStyle.Spacers.SPACING_MEDIUM_SMALL)
            .padding(.trailing, DSStyle.Spacers.SPACING_MEDIUM_SMALL)

            if isExpanded {
              ScrollView {
                LazyVGrid(columns: columns, spacing: DSStyle.Spacers.SPACING_SMALL) {
                  ForEach(detail, id: \.self) { item in
                    HStack {
                      Text("•")
                        .padding(.leading, DSStyle.Spacers.SPACING_SMALL)
                      Text(item)
                        .font(DSTypography.Body.medium)
                        .foregroundColor(DSColor.onSurfaceVariant)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                  }
                }
              }
              .transition(.opacity.combined(with: .move(edge: .top)))
              .padding(.top, DSStyle.Spacers.SPACING_SMALL)
              .background(Color.white)
            } else {
              Spacer()
            }
          }
          .padding(.top, DSStyle.Spacers.SPACING_SMALL)
        }
      )
      .clipShape(RoundedRectangle(cornerRadius: DSStyle.Spacers.SPACING_MEDIUM_SMALL))
      .overlay(
        RoundedRectangle(cornerRadius: DSStyle.Spacers.SPACING_MEDIUM_SMALL)
          .stroke(DSColor.outlineVariant, lineWidth: 1)
      )
      .clipped()
  }
}
