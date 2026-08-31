//
//  RemoteImageView.swift
//  logic-ui
//

import SwiftUI

public struct RemoteImageView: View {
  let urlString: String

  public init(urlString: String) {
    self.urlString = urlString
  }

  public var body: some View {
    AsyncImage(
      url: URL(string: urlString),
      transaction: Transaction(animation: .easeInOut(duration: 0.25))
    ) { phase in
      switch phase {
      case .empty:
        ProgressView()
          .frame(maxWidth: .infinity, maxHeight: .infinity)

      case .success(let image):
        image
          .resizable()
          .scaledToFill()
          .frame(maxWidth: .infinity, maxHeight: .infinity)
          .clipped()
          .transition(.opacity.combined(with: .scale(scale: 0.98)))

      case .failure:
        Image(systemName: "photo")
          .resizable()
          .scaledToFit()
          .foregroundStyle(.secondary)
          .padding(24)
          .frame(maxWidth: .infinity, maxHeight: .infinity)

      @unknown default:
        EmptyView()
          .frame(maxWidth: .infinity, maxHeight: .infinity)
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }
}
