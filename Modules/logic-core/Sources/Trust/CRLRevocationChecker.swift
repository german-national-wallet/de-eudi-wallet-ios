//
//  CRLRevocationChecker.swift
//  logic-core
//
//  Created by Pankaj Sachdeva on 05.11.26.
//

import Foundation
import EudiEtsi1196x2
import SwiftASN1
import X509

/// Checks a certificate against the CRLs in its CRL Distribution Points (RFC 5280).
/// It fails closed: anything that prevents a definite answer is reported as unknown.
/// `@unchecked Sendable`: the only mutable state, `cache`, is guarded by `lock`.
final class CRLRevocationChecker: NSObject, CheckRevocationIos, @unchecked Sendable {

  private let fetch: @Sendable (URL) throws -> Data
  private let now: @Sendable () -> Date
  private let lock = NSLock()
  private var cache: [URL: (crl: CertificateRevocationList, fetchedAt: Date)] = [:]

  static let refreshInterval: TimeInterval = 3600

  init(
    fetch: @escaping @Sendable (URL) throws -> Data = CRLRevocationChecker.download,
    now: @escaping @Sendable () -> Date = Date.init
  ) {
    self.fetch = fetch
    self.now = now
  }

  func invoke(certificate: Data, issuer: Data) -> any IosRevocationStatus {
    do {
      return try status(
        of: Certificate(derEncoded: Array(certificate)),
        issuer: Certificate(derEncoded: Array(issuer))
      )
    } catch {
      return IosRevocationStatusUnknown(reason: "\(error)")
    }
  }

  private func status(of certificate: Certificate, issuer: Certificate) throws -> any IosRevocationStatus {
    let urls = try certificate.crlDistributionPointURLs()
    guard !urls.isEmpty else {
      throw CRLError("Certificate \(certificate.subject) has no HTTP CRL distribution point")
    }
    let serial = CertificateRevocationList.normalizedSerial(certificate.serialNumber.bytes)
    var isCA = false
    if case .isCertificateAuthority = try certificate.extensions.basicConstraints { isCA = true }
    var lastError: Error?
    for url in urls {
      do {
        let crl = try revocationList(at: url, issuer: issuer)
        try crl.issuingDistributionPoint?.checkScope(url: url, certificateIsCA: isCA)
        return crl.revokedSerials.contains(serial)
          ? IosRevocationStatusRevoked(reason: "Certificate \(certificate.subject) is revoked (CRL \(url.absoluteString))")
          : IosRevocationStatusGood.shared
      } catch {
        lastError = error
      }
    }
    throw lastError ?? CRLError("No usable CRL for \(certificate.subject)")
  }

  /// A cached CRL is used for `refreshInterval`, then downloaded again; if that download fails, the cached
  /// one is still used until its `nextUpdate`.
  private func revocationList(at url: URL, issuer: Certificate) throws -> CertificateRevocationList {
    let date = now()
    let cached = lock.withLock { cache[url] }
      .flatMap { $0.crl.issuer == issuer.subject && $0.crl.isCurrent(at: date) ? $0 : nil }
    if let cached, date < cached.fetchedAt.addingTimeInterval(Self.refreshInterval) {
      return cached.crl
    }
    do {
      let crl = try downloadedList(at: url, issuer: issuer, date: date)
      lock.withLock { cache[url] = (crl, date) }
      return crl
    } catch {
      guard let cached else { throw error }
      return cached.crl
    }
  }

  private func downloadedList(at url: URL, issuer: Certificate, date: Date) throws -> CertificateRevocationList {
    let crl = try CertificateRevocationList(der: Array(fetch(url)))
    guard crl.issuer == issuer.subject else {
      throw CRLError("CRL \(url.absoluteString) is issued by \(crl.issuer), expected \(issuer.subject)")
    }
    guard try issuer.extensions.keyUsage?.cRLSign ?? true else {
      throw CRLError("CRL \(url.absoluteString) issuer \(issuer.subject) may not sign CRLs")
    }
    guard crl.unsupportedCriticalExtensions.isEmpty else {
      throw CRLError("CRL \(url.absoluteString) has unsupported critical extensions \(crl.unsupportedCriticalExtensions)")
    }
    guard crl.isCurrent(at: date) else {
      throw CRLError("CRL \(url.absoluteString) is outside its validity period")
    }
    guard issuer.publicKey.isValidSignature(crl.signature, for: crl.tbsBytes, signatureAlgorithm: crl.signatureAlgorithm) else {
      throw CRLError("CRL \(url.absoluteString) signature is invalid")
    }
    return crl
  }

  static let requestTimeout: TimeInterval = 5
  static let downloadTimeout: TimeInterval = 10

  static func download(_ url: URL) throws -> Data {
    let request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: requestTimeout)
    let semaphore = DispatchSemaphore(value: 0)
    var result: Result<Data, Error> = .failure(CRLError("CRL download from \(url.absoluteString) did not complete"))
    let task = URLSession.shared.dataTask(with: request) { data, response, error in
      if let error {
        result = .failure(error)
      } else if let status = (response as? HTTPURLResponse)?.statusCode, status != 200 {
        result = .failure(CRLError("CRL download from \(url.absoluteString) returned HTTP \(status)"))
      } else if let data {
        result = .success(data)
      }
      semaphore.signal()
    }
    task.resume()
    guard semaphore.wait(timeout: .now() + downloadTimeout) == .success else {
      task.cancel()
      throw CRLError("CRL download from \(url.absoluteString) timed out")
    }
    return try result.get()
  }
}

struct CRLError: Error, CustomStringConvertible {
  let description: String

  init(_ description: String) {
    self.description = description
  }
}

/// CertificateList (RFC 5280 5.1), DER only.
struct CertificateRevocationList {
  let issuer: X509.DistinguishedName
  let thisUpdate: Date
  let nextUpdate: Date?
  let revokedSerials: Set<[UInt8]>
  let issuingDistributionPoint: IssuingDistributionPoint?
  let unsupportedCriticalExtensions: [ASN1ObjectIdentifier]
  let tbsBytes: ArraySlice<UInt8>
  let signatureAlgorithm: Certificate.SignatureAlgorithm
  let signature: ArraySlice<UInt8>

  init(der: [UInt8]) throws {
    let (tbs, algorithm, signature) = try DER.sequence(DER.parse(der), identifier: .sequence) { nodes in
      (try Self.next(&nodes), try Self.algorithmOID(Self.next(&nodes)), try ASN1BitString(derEncoded: &nodes))
    }
    guard let signatureAlgorithm = Self.signatureAlgorithms[algorithm] else {
      throw CRLError("Unsupported CRL signature algorithm \(algorithm)")
    }
    self.tbsBytes = tbs.encodedBytes
    self.signatureAlgorithm = signatureAlgorithm
    self.signature = signature.bytes

    var issuer: X509.DistinguishedName?
    var thisUpdate: Date?
    var nextUpdate: Date?
    var serials = Set<[UInt8]>()
    var extensions: [Certificate.Extension] = []
    try DER.sequence(tbs, identifier: .sequence) { nodes in
      var node = try Self.next(&nodes)
      if node.identifier == .integer { node = try Self.next(&nodes) }
      guard try Self.algorithmOID(node) == algorithm else {
        throw CRLError("CRL signature algorithm does not match its TBS algorithm")
      }
      issuer = try X509.DistinguishedName(derEncoded: Self.next(&nodes))
      thisUpdate = try Self.date(Self.next(&nodes))
      var optional = nodes.next()
      if let time = optional, [.utcTime, .generalizedTime].contains(time.identifier) {
        nextUpdate = try Self.date(time)
        optional = nodes.next()
      }
      if let revoked = optional, revoked.identifier == .sequence {
        serials = try Self.revokedSerials(revoked)
        optional = nodes.next()
      }
      if let tagged = optional, tagged.identifier == ASN1Identifier(tagWithNumber: 0, tagClass: .contextSpecific) {
        extensions = try DER.explicitlyTagged(tagged, tagNumber: 0, tagClass: .contextSpecific) {
          try DER.sequence(of: Certificate.Extension.self, identifier: .sequence, rootNode: $0)
        }
      }
    }
    guard let issuer, let thisUpdate else { throw CRLError("CRL has no issuer or thisUpdate") }
    self.issuer = issuer
    self.thisUpdate = thisUpdate
    self.nextUpdate = nextUpdate
    self.revokedSerials = serials
    self.issuingDistributionPoint = try extensions
      .first { $0.oid == IssuingDistributionPoint.oid }
      .map { try IssuingDistributionPoint(der: Array($0.value)) }
    self.unsupportedCriticalExtensions = extensions
      .filter { $0.critical && $0.oid != IssuingDistributionPoint.oid }
      .map(\.oid)
  }

  func isCurrent(at date: Date) -> Bool {
    guard let nextUpdate else { return false }
    return thisUpdate <= date && date <= nextUpdate
  }

  static func normalizedSerial(_ bytes: ArraySlice<UInt8>) -> [UInt8] {
    Array(bytes.drop { $0 == 0 })
  }

  private static let signatureAlgorithms: [ASN1ObjectIdentifier: Certificate.SignatureAlgorithm] = [
    [1, 2, 840, 10045, 4, 3, 2]: .ecdsaWithSHA256,
    [1, 2, 840, 10045, 4, 3, 3]: .ecdsaWithSHA384,
    [1, 2, 840, 10045, 4, 3, 4]: .ecdsaWithSHA512,
    [1, 2, 840, 113549, 1, 1, 11]: .sha256WithRSAEncryption,
    [1, 2, 840, 113549, 1, 1, 12]: .sha384WithRSAEncryption,
    [1, 2, 840, 113549, 1, 1, 13]: .sha512WithRSAEncryption
  ]

  private static func next(_ nodes: inout ASN1NodeCollection.Iterator) throws -> ASN1Node {
    guard let node = nodes.next() else { throw CRLError("CRL is truncated") }
    return node
  }

  private static func algorithmOID(_ node: ASN1Node) throws -> ASN1ObjectIdentifier {
    try DER.sequence(node, identifier: .sequence) { nodes in
      let oid = try ASN1ObjectIdentifier(derEncoded: &nodes)
      while nodes.next() != nil {}
      return oid
    }
  }

  private static func revokedSerials(_ node: ASN1Node) throws -> Set<[UInt8]> {
    try DER.sequence(node, identifier: .sequence) { entries in
      var serials = Set<[UInt8]>()
      while let entry = entries.next() {
        try DER.sequence(entry, identifier: .sequence) { fields in
          guard case .primitive(let serial) = try next(&fields).content else { throw CRLError("Invalid revoked serial") }
          serials.insert(normalizedSerial(serial))
          _ = try next(&fields)
          if let extensions = fields.next() {
            let critical = try DER.sequence(of: Certificate.Extension.self, identifier: .sequence, rootNode: extensions)
              .filter(\.critical)
            guard critical.isEmpty else {
              throw CRLError("CRL entry has unsupported critical extensions \(critical.map(\.oid))")
            }
          }
        }
      }
      return serials
    }
  }

  private static func date(_ node: ASN1Node) throws -> Date {
    var components = DateComponents(calendar: Calendar(identifier: .gregorian), timeZone: TimeZone(identifier: "UTC"))
    switch node.identifier {
    case .utcTime:
      let time = try UTCTime(derEncoded: node)
      (components.year, components.month, components.day) = (time.year, time.month, time.day)
      (components.hour, components.minute, components.second) = (time.hours, time.minutes, time.seconds)
    case .generalizedTime:
      let time = try GeneralizedTime(derEncoded: node)
      (components.year, components.month, components.day) = (time.year, time.month, time.day)
      (components.hour, components.minute, components.second) = (time.hours, time.minutes, time.seconds)
    default:
      throw CRLError("Invalid CRL time")
    }
    guard let date = components.date else { throw CRLError("Invalid CRL time") }
    return date
  }
}

/// IssuingDistributionPoint (RFC 5280 5.2.5).
struct IssuingDistributionPoint {
  static let oid: ASN1ObjectIdentifier = [2, 5, 29, 28]

  let uris: [String]
  let onlyContainsUserCerts: Bool
  let onlyContainsCACerts: Bool
  let hasUnsupportedScope: Bool

  init(der: [UInt8]) throws {
    var uris: [String] = []
    var onlyUser = false
    var onlyCA = false
    var unsupported = false
    try DER.sequence(DER.parse(der), identifier: .sequence) { nodes in
      while let node = nodes.next() {
        guard node.identifier.tagClass == .contextSpecific else { continue }
        let isTrue = { try Bool(derEncoded: node, withIdentifier: node.identifier) }
        switch node.identifier.tagNumber {
        case 0:
          let names = try fullNameURIs(node)
          unsupported = unsupported || names == nil
          uris = names ?? []
        case 1: onlyUser = try isTrue()
        case 2: onlyCA = try isTrue()
        case 3: unsupported = true
        case 4, 5: unsupported = try unsupported || isTrue()
        default: break
        }
      }
    }
    self.uris = uris
    self.onlyContainsUserCerts = onlyUser
    self.onlyContainsCACerts = onlyCA
    self.hasUnsupportedScope = unsupported
  }

  /// Partial, indirect and attribute-certificate CRLs cannot prove that a certificate is not revoked.
  func checkScope(url: URL, certificateIsCA: Bool) throws {
    if hasUnsupportedScope {
      throw CRLError("CRL \(url.absoluteString) is a partial, indirect or attribute-certificate CRL")
    }
    if !uris.isEmpty, !uris.contains(url.absoluteString) {
      throw CRLError("CRL \(url.absoluteString) is scoped to another distribution point")
    }
    if onlyContainsUserCerts, certificateIsCA {
      throw CRLError("CRL \(url.absoluteString) only covers end-entity certificates")
    }
    if onlyContainsCACerts, !certificateIsCA {
      throw CRLError("CRL \(url.absoluteString) only covers CA certificates")
    }
  }
}

/// The URIs of a `[0] DistributionPointName` whose choice is `fullName`, or `nil` when it names no URI
/// (`nameRelativeToCRLIssuer`, an empty or malformed name, or only non-URI names).
private func fullNameURIs(_ distributionPoint: ASN1Node) throws -> [String]? {
  guard case .constructed(let choices) = distributionPoint.content,
        let fullName = choices.first(where: { _ in true }),
        fullName.identifier == ASN1Identifier(tagWithNumber: 0, tagClass: .contextSpecific),
        case .constructed(let names) = fullName.content else { return nil }
  let uris: [String] = try names.compactMap {
    guard case .uniformResourceIdentifier(let uri) = try GeneralName(derEncoded: $0) else { return nil }
    return uri
  }
  return uris.isEmpty ? nil : uris
}

extension Certificate {

  func crlDistributionPointURLs() throws -> [URL] {
    let oid: ASN1ObjectIdentifier = [2, 5, 29, 31]
    guard let value = extensions.first(where: { $0.oid == oid })?.value else { return [] }
    let uris = try DER.sequence(DER.parse(Array(value)), identifier: .sequence) { points in
      var uris: [String] = []
      while let point = points.next() {
        try DER.sequence(point, identifier: .sequence) { fields in
          while let field = fields.next() {
            guard field.identifier == ASN1Identifier(tagWithNumber: 0, tagClass: .contextSpecific) else {
              throw CRLError("CRL distribution points limited to some reasons or another CRL issuer are not supported")
            }
            uris += try fullNameURIs(field) ?? []
          }
        }
      }
      return uris
    }
    return uris.compactMap(URL.init(string:)).filter { ["http", "https"].contains($0.scheme?.lowercased()) }
  }
}
