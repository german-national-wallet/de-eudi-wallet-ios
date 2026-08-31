//
//  SafariView.swift
//  feature-common
//

import SwiftUI
import SafariServices

public struct SafariView: UIViewControllerRepresentable {

  private let url: URL

  public init(url: URL) {
    self.url = url
  }

  public func makeUIViewController(context: Context) -> SFSafariViewController {
    let controller = SFSafariViewController(url: url)
    controller.dismissButtonStyle = .close
    return controller
  }

  public func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}
