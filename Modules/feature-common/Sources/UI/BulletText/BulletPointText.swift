//
//  SwiftUIView.swift
//  feature-common
//

import SwiftUI
import logic_ui

public struct BulletPointText: View {
  var text: String
  
  public init(text: String) {
    self.text = text
  }
  
  public var body: some View {
    HStack(alignment: .top, spacing: DSStyle.Spacers.SPACING_SMALL) {
      Text("•")
      Text(text)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }
}
