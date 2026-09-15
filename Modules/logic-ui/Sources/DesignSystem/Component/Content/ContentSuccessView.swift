//
//  ContentSuccessView.swift
//  logic-ui
//

import SwiftUI
import logic_resources

public struct ContentSuccessView: View {
  private let width: CGFloat
  private let successText: String
  private let onFinished: (() -> Void)?

  public init(
    width: CGFloat = 50,
    successText: String,
    onFinished: (() -> Void)? = nil
  ) {
    self.width = width
    self.successText = successText
    self.onFinished = onFinished
  }

  public var body: some View {
    VStack {
      Spacer()

      VideoAnimationView(
        asset: .successInline,
        size: Constants.animationSize,
        onFinished: onFinished
      )
      .frame(width: width, height: width)

      HStack {
        Spacer()

        DSTitleLabel(successText, alignment: .center)
          .padding(.top, DSStyle.Spacers.SPACING_LARGE_MEDIUM)
          .padding(.horizontal, DSStyle.Spacers.SPACING_MEDIUM)

        Spacer()
      }

      Spacer()
    }
    .frame(maxWidth: .infinity)
  }
}

private enum Constants {
  static let animationSize: CGFloat = 260
}
