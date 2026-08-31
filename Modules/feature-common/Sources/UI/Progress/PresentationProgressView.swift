//
//  PresentationProgressView.swift
//  feature-common
//

import SwiftUI
import logic_ui

public struct PresentationProgressView: View {
  private let progress: Double
  
  public init(progress: Double) {
    self.progress = progress
  }
  
  public var body: some View {
    GeometryReader { geometry in
      HStack(spacing: 5) {
        Capsule()
          .fill(DSColor.primary)
          .frame(width: geometry.size.width * progress, height: 4)

        Capsule()
          .fill(DSColor.primaryContainer)
          .frame(width: geometry.size.width * (1-progress), height: 4)
      }
      .frame(height: 5)
    }
  }
}
