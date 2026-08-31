//
//  PinnedCertificateNetworking.swift
//  logic-core
//

import CryptoKit
import EudiWalletKit
import Foundation
import logic_api
import logic_business
import Security

final class PinnedCertificateNetworking: NSObject, @unchecked Sendable, NetworkingProtocol, URLSessionDelegate {
  private enum Constants {
    static let certificateFileExtension = "der"
    static let certificateSubdirectory = "Wallet/Certificates/Pinning"
    static let pinCertificateFilePrefix = "pidp-tls-pin-"
    static let pinnedHostSuffix = "pid-provider.bundesdruckerei.de"
  }

  private let pinnedCertificates: [SecCertificate]
  private let pinnedCertificateHashes: Set<Data>
  private let networkLogger: NetworkLogger
  private var session: URLSession!

  init(logger: Logging?) {
    networkLogger = NetworkLogger(logger: logger)

    let pinnedCertificateData = Bundle.main
      .urls(forResourcesWithExtension: Constants.certificateFileExtension, subdirectory: Constants.certificateSubdirectory)?
      .filter {
        $0.lastPathComponent.hasPrefix(Constants.pinCertificateFilePrefix)
        && $0.lastPathComponent.hasSuffix(".\(Constants.certificateFileExtension)")
      }
      .compactMap { try? Data(contentsOf: $0) }

    pinnedCertificates = pinnedCertificateData?
      .compactMap { SecCertificateCreateWithData(nil, $0 as CFData) } ?? []
    pinnedCertificateHashes = pinnedCertificateData?
      .map { Data(SHA256.hash(data: $0)) }
      .reduce(into: Set<Data>()) { $0.insert($1) } ?? []
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

    guard shouldPin(host: host) else {
      completionHandler(.performDefaultHandling, nil)
      return
    }

    guard let serverTrust = challenge.protectionSpace.serverTrust else {
      completionHandler(.cancelAuthenticationChallenge, nil)
      return
    }

    guard !pinnedCertificates.isEmpty else {
      completionHandler(.cancelAuthenticationChallenge, nil)
      return
    }

    guard SecTrustEvaluateWithError(serverTrust, nil) else {
      completionHandler(.cancelAuthenticationChallenge, nil)
      return
    }

    guard serverTrustMatchesPin(serverTrust) else {
      completionHandler(.cancelAuthenticationChallenge, nil)
      return
    }

    completionHandler(.useCredential, URLCredential(trust: serverTrust))
  }

  func shouldPin(host: String) -> Bool {
#if DEBUG
    return false
#else
    let host = host.lowercased()
    return host == Constants.pinnedHostSuffix || host.hasSuffix(".\(Constants.pinnedHostSuffix)")
#endif
  }

  func isPinCertificateFileName(_ fileName: String) -> Bool {
    fileName.hasPrefix(Constants.pinCertificateFilePrefix) && fileName.hasSuffix(".\(Constants.certificateFileExtension)")
  }

  private func serverTrustMatchesPin(_ serverTrust: SecTrust) -> Bool {
    if serverTrustContainsPinnedCertificate(serverTrust) {
      return true
    }

    guard SecTrustSetAnchorCertificates(serverTrust, pinnedCertificates as CFArray) == errSecSuccess else {
      return false
    }

    guard SecTrustSetAnchorCertificatesOnly(serverTrust, true) == errSecSuccess else {
      return false
    }

    return SecTrustEvaluateWithError(serverTrust, nil)
  }

  private func serverTrustContainsPinnedCertificate(_ serverTrust: SecTrust) -> Bool {
    guard let certificates = SecTrustCopyCertificateChain(serverTrust) as? [SecCertificate] else {
      return false
    }

    for certificate in certificates {
      let certificateData = SecCertificateCopyData(certificate) as Data
      if pinnedCertificateHashes.contains(Data(SHA256.hash(data: certificateData))) {
        return true
      }
    }
    return false
  }
}
