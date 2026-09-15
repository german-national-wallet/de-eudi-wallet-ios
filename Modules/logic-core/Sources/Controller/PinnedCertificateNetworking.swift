//
//  PinnedCertificateNetworking.swift
//  logic-core
//

import EudiWalletKit
import Foundation
import logic_api
import logic_business
import Security

final class PinnedCertificateNetworking: NSObject, @unchecked Sendable, NetworkingProtocol, URLSessionDelegate {

  private let certificatePinner: CertificatePinner
  private let networkLogger: NetworkLogger
  private var session: URLSession!

  init(logger: Logging?, certificatePinner: CertificatePinner = .shared) {
    self.certificatePinner = certificatePinner
    networkLogger = NetworkLogger(logger: logger)
    super.init()
    session = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
  }

  func data(from url: URL) async throws -> (Data, URLResponse) {
    try await data(for: URLRequest(url: url))
  }

  func data(for request: URLRequest) async throws -> (Data, URLResponse) {
    let (data, response) = try await session.data(for: request)
    networkLogger.log(
      request: request,
      responseData: data,
      responseHeader: response as? HTTPURLResponse
    )
    return (data, response)
  }

  func urlSession(
    _ session: URLSession,
    didReceive challenge: URLAuthenticationChallenge,
    completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
  ) {
    let host = challenge.protectionSpace.host
    let method = challenge.protectionSpace.authenticationMethod

    guard method == NSURLAuthenticationMethodServerTrust else {
      completionHandler(.performDefaultHandling, nil)
      return
    }

    guard let hostSuffix = pinnedHostSuffix(for: host) else {
      completionHandler(.performDefaultHandling, nil)
      return
    }

    guard let serverTrust = challenge.protectionSpace.serverTrust else {
      completionHandler(.cancelAuthenticationChallenge, nil)
      return
    }

    guard SecTrustEvaluateWithError(serverTrust, nil) else {
      completionHandler(.cancelAuthenticationChallenge, nil)
      return
    }

    guard certificatePinner.matches(serverTrust: serverTrust, hostSuffix: hostSuffix) else {
      completionHandler(.cancelAuthenticationChallenge, nil)
      return
    }

    completionHandler(.useCredential, URLCredential(trust: serverTrust))
  }

  func pinnedHostSuffix(for host: String) -> String? {
    certificatePinner.pinnedHostSuffix(for: host)
  }

  func isPinCertificateFileName(_ fileName: String) -> Bool {
    certificatePinner.isPinCertificateFileName(fileName)
  }
}
