//
//  CertificatePinner.swift
//  logic-api
//

import CryptoKit
import Foundation
import logic_business
import Security

public struct CertificatePinner: Sendable {

  private enum Constants {
    static let certificateFileExtension = "der"
    static let certificateSubdirectory = "Wallet/Certificates/Pinning"
    static let pidProviderHostSuffix = "pid-provider.bundesdruckerei.de"
    static let pidProviderFilePrefix = "pidp-tls-pin-"
    static let letsEncryptFilePrefix = "le-tls-pin-"
    static let letsEncryptHostSuffixesKey = "TLS_PIN_HOST_SUFFIXES"
  }

  public static let shared = CertificatePinner()

  private let anchorsByHostSuffix: [String: [SecCertificate]]
  private let publicKeyHashesByHostSuffix: [String: Set<Data>]

  public init(letsEncryptHostSuffixes: [String] = CertificatePinner.letsEncryptHostSuffixesFromBundle()) {
    var filePrefixByHostSuffix = [Constants.pidProviderHostSuffix: Constants.pidProviderFilePrefix]
    for hostSuffix in letsEncryptHostSuffixes {
      filePrefixByHostSuffix[hostSuffix.lowercased()] = Constants.letsEncryptFilePrefix
    }

    var anchors: [String: [SecCertificate]] = [:]
    var publicKeyHashes: [String: Set<Data>] = [:]
    for (hostSuffix, filePrefix) in filePrefixByHostSuffix {
      let certificates = Self.loadCertificates(filePrefix: filePrefix)
      anchors[hostSuffix] = certificates
      publicKeyHashes[hostSuffix] = Set(certificates.compactMap(Self.publicKeyHash))
    }
    anchorsByHostSuffix = anchors
    publicKeyHashesByHostSuffix = publicKeyHashes
  }

  public static func letsEncryptHostSuffixesFromBundle() -> [String] {
    Constants.letsEncryptHostSuffixesKey.valueFromBundle
      .split(separator: ",")
      .map { $0.trimmingCharacters(in: .whitespaces) }
      .filter { !$0.isEmpty }
  }

  public func pinnedHostSuffix(for host: String) -> String? {
    let host = host.lowercased()
    return anchorsByHostSuffix.keys.first { host == $0 || host.hasSuffix(".\($0)") }
  }

  public func anchors(forHostSuffix hostSuffix: String) -> [SecCertificate] {
    anchorsByHostSuffix[hostSuffix] ?? []
  }

  public func isPinCertificateFileName(_ fileName: String) -> Bool {
    let prefixes = [Constants.pidProviderFilePrefix, Constants.letsEncryptFilePrefix]
    return prefixes.contains { fileName.hasPrefix($0) }
    && fileName.hasSuffix(".\(Constants.certificateFileExtension)")
  }

  public func matches(serverTrust: SecTrust, hostSuffix: String) -> Bool {
    let anchors = anchors(forHostSuffix: hostSuffix)
    guard !anchors.isEmpty else {
      return false
    }

    if let hashes = publicKeyHashesByHostSuffix[hostSuffix], Self.chain(serverTrust, containsPublicKeyIn: hashes) {
      return true
    }

    guard SecTrustSetAnchorCertificates(serverTrust, anchors as CFArray) == errSecSuccess,
          SecTrustSetAnchorCertificatesOnly(serverTrust, true) == errSecSuccess else {
      return false
    }
    return SecTrustEvaluateWithError(serverTrust, nil)
  }

  private static func loadCertificates(filePrefix: String) -> [SecCertificate] {
    let urls = Bundle.main.urls(
      forResourcesWithExtension: Constants.certificateFileExtension,
      subdirectory: Constants.certificateSubdirectory
    ) ?? []
    return urls
      .filter { $0.lastPathComponent.hasPrefix(filePrefix) }
      .compactMap { try? Data(contentsOf: $0) }
      .compactMap { SecCertificateCreateWithData(nil, $0 as CFData) }
  }

  private static func publicKeyHash(_ certificate: SecCertificate) -> Data? {
    guard let publicKey = SecCertificateCopyKey(certificate),
          let representation = SecKeyCopyExternalRepresentation(publicKey, nil) as Data? else {
      return nil
    }
    return Data(SHA256.hash(data: representation))
  }

  private static func chain(_ serverTrust: SecTrust, containsPublicKeyIn hashes: Set<Data>) -> Bool {
    guard let certificates = SecTrustCopyCertificateChain(serverTrust) as? [SecCertificate] else {
      return false
    }
    return certificates.contains { certificate in
      guard let hash = publicKeyHash(certificate) else {
        return false
      }
      return hashes.contains(hash)
    }
  }
}
