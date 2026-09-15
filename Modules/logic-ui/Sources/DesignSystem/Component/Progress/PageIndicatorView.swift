//
//  PageIndicatorView.swift
//  logic-ui
//

import SwiftUI
import logic_resources

public extension DesignSystem.Components {

  struct PageIndicator: View {
    let current: Int
    let total: Int

    static let dotSize: CGFloat = 8
    static let dotSpacing: CGFloat = DSStyle.Spacers.SPACING_SMALL

    public init(current: Int, total: Int) {
      self.current = current
      self.total = total
    }

    public var body: some View {
      HStack(spacing: Self.dotSpacing) {
        ForEach(1...max(total, 1), id: \.self) { page in
          Circle()
            .fill(page == current ? DSColor.onSurface : DSColor.outlineVariant)
            .frame(width: Self.dotSize, height: Self.dotSize)
        }
      }
      .accessibilityElement(children: .ignore)
      .accessibilityLabel(
        Text(
          LocalizableStringKey.headerAccessibilityProgress(
            ["\(current)", "\(max(total, 1))"]
          ).toLocalizedStringKey
        )
      )
    }
  }
}

#if DEBUG
#Preview {
  VStack(spacing: 16) {
    DSPageIndicator(current: 1, total: 3)
    DSPageIndicator(current: 2, total: 3)
    DSPageIndicator(current: 3, total: 3)
  }
}
#endif
