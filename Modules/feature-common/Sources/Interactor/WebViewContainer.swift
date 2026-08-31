//
//  WebViewContainer.swift
//  feature-dashboard
//
import SwiftUI
import WebKit

public struct WebViewContainer: UIViewRepresentable {
  
  let url: URL
  
  public init(url: URL) {
    self.url = url
  }
  
  public func makeUIView(context: Context) -> WKWebView {
    let configuration = WKWebViewConfiguration()
    configuration.allowsInlineMediaPlayback = true
    configuration.mediaTypesRequiringUserActionForPlayback = []
    
    let webView = WKWebView(frame: .zero, configuration: configuration)
    webView.navigationDelegate = context.coordinator
    webView.allowsBackForwardNavigationGestures = true
    webView.backgroundColor = UIColor.systemBackground
    
    let request = URLRequest(url: url)
    webView.load(request)
    return webView
  }
  
  public func updateUIView(_ uiView: WKWebView, context: Context) {}
  
  public func makeCoordinator() -> Coordinator {
    Coordinator(allowedHost: url.host)
  }

  public class Coordinator: NSObject, WKNavigationDelegate {
    private let allowedHost: String?

    init(allowedHost: String?) {
      self.allowedHost = allowedHost?.lowercased()
    }

    private func shouldAllowInAppNavigation(to url: URL) -> Bool {
      guard let scheme = url.scheme?.lowercased(), ["http", "https"].contains(scheme) else {
        return false
      }

      guard let allowedHost, let host = url.host?.lowercased() else {
        return false
      }

      return host == allowedHost
    }

    // MARK: - WKNavigationDelegate Extension

    public func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
      guard let url = navigationAction.request.url else {
        decisionHandler(.cancel)
        return
      }

      if shouldAllowInAppNavigation(to: url) {
        decisionHandler(.allow)
        return
      }

      if UIApplication.shared.canOpenURL(url) {
        UIApplication.shared.open(url)
      }

      decisionHandler(.cancel)
    }
  }
}
