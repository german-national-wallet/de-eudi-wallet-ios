//
//  CRLRevocationCheckerTests.swift
//  logic-core
//
//  Created by Pankaj Sachdeva on 05.11.26.
//

import Foundation
import Testing
import EudiEtsi1196x2
import Security
import X509
@testable import logic_core

/// Fixtures: `crl-test-ca` issues `crl-test-valid-leaf` and `crl-test-revoked-leaf` (CRL distribution point
/// https://crl.example.test/ca.crl); `crl-test-ca.crl` revokes the revoked leaf and carries a critical
/// Issuing Distribution Point scoped to that URL and to end-entity certificates.
@Suite("CRLRevocationChecker")
struct CRLRevocationCheckerTests {

  private func fixture(_ name: String, _ ext: String = "der") throws -> Data {
    let url = try #require(Bundle.module.url(forResource: name, withExtension: ext))
    return try Data(contentsOf: url)
  }

  private func check(
    leaf: String = "crl-test-valid-leaf",
    crl: Data? = nil,
    fetch: (@Sendable (URL) throws -> Data)? = nil,
    at date: Date? = nil
  ) throws -> any IosRevocationStatus {
    let crlData = try crl ?? fixture("crl-test-ca", "crl")
    let thisUpdate = try CertificateRevocationList(der: Array(fixture("crl-test-ca", "crl"))).thisUpdate
    let checker = CRLRevocationChecker(
      fetch: fetch ?? { _ in crlData },
      now: { date ?? thisUpdate.addingTimeInterval(60) }
    )
    return try checker.invoke(certificate: fixture(leaf), issuer: fixture("crl-test-ca"))
  }

  @Test func notRevokedLeaf_isGood() throws {
    #expect(try check() is IosRevocationStatusGood)
  }

  @Test func revokedLeaf_isRevoked() throws {
    let status = try #require(try check(leaf: "crl-test-revoked-leaf") as? IosRevocationStatusRevoked)
    #expect(status.reason.contains("revoked"))
  }

  @Test func downloadFailure_isUnknown() throws {
    #expect(try check(fetch: { _ in throw URLError(.notConnectedToInternet) }) is IosRevocationStatusUnknown)
  }

  @Test func tamperedCrl_isUnknown() throws {
    var crl = try fixture("crl-test-ca", "crl")
    crl[crl.count - 1] ^= 0xFF
    #expect(try check(crl: crl) is IosRevocationStatusUnknown)
  }

  @Test func expiredCrl_isUnknown() throws {
    let nextUpdate = try #require(try CertificateRevocationList(der: Array(fixture("crl-test-ca", "crl"))).nextUpdate)
    #expect(try check(at: nextUpdate.addingTimeInterval(60)) is IosRevocationStatusUnknown)
  }

  @Test func certificateWithoutDistributionPoint_isUnknown() throws {
    let status = try #require(try check(leaf: "crl-test-ca") as? IosRevocationStatusUnknown)
    #expect(status.reason.contains("no HTTP CRL distribution point"))
  }

  @Test func cachedCrl_isRefreshedAfterRefreshInterval() throws {
    let crlData = try fixture("crl-test-ca", "crl")
    let crl = try CertificateRevocationList(der: Array(crlData))
    let fetches = Box(0)
    let date = Box(crl.thisUpdate.addingTimeInterval(60))
    let checker = CRLRevocationChecker(fetch: { _ in fetches.value += 1; return crlData }, now: { date.value })
    let leaf = try fixture("crl-test-valid-leaf")
    let issuer = try fixture("crl-test-ca")

    #expect(checker.invoke(certificate: leaf, issuer: issuer) is IosRevocationStatusGood)
    date.value = date.value.addingTimeInterval(CRLRevocationChecker.refreshInterval - 60)
    #expect(checker.invoke(certificate: leaf, issuer: issuer) is IosRevocationStatusGood)
    #expect(fetches.value == 1)

    date.value = date.value.addingTimeInterval(120)
    #expect(checker.invoke(certificate: leaf, issuer: issuer) is IosRevocationStatusGood)
    #expect(fetches.value == 2)
  }

  @Test func failedRefresh_usesCachedCrlUntilNextUpdate() throws {
    let crlData = try fixture("crl-test-ca", "crl")
    let crl = try CertificateRevocationList(der: Array(crlData))
    let nextUpdate = try #require(crl.nextUpdate)
    let isOnline = Box(true)
    let date = Box(crl.thisUpdate.addingTimeInterval(60))
    let checker = CRLRevocationChecker(
      fetch: { _ in
        guard isOnline.value else { throw URLError(.notConnectedToInternet) }
        return crlData
      },
      now: { date.value }
    )
    let leaf = try fixture("crl-test-valid-leaf")
    let issuer = try fixture("crl-test-ca")

    #expect(checker.invoke(certificate: leaf, issuer: issuer) is IosRevocationStatusGood)
    isOnline.value = false
    date.value = date.value.addingTimeInterval(CRLRevocationChecker.refreshInterval * 2)
    #expect(checker.invoke(certificate: leaf, issuer: issuer) is IosRevocationStatusGood)

    date.value = nextUpdate.addingTimeInterval(60)
    #expect(checker.invoke(certificate: leaf, issuer: issuer) is IosRevocationStatusUnknown)
  }

  @Test func partialDistributionPoint_isUnsupported() throws {
    // CRLDistributionPoints { DistributionPoint { fullName http://a, reasons } }
    let distributionPoints: [UInt8] = [
      0x30, 0x14, 0x30, 0x12,
      0xA0, 0x0C, 0xA0, 0x0A, 0x86, 0x08, 0x68, 0x74, 0x74, 0x70, 0x3A, 0x2F, 0x2F, 0x61,
      0x81, 0x02, 0x07, 0x80
    ]
    let certificate = try selfSignedCertificate(extensions: [
      Certificate.Extension(oid: [2, 5, 29, 31], critical: false, value: distributionPoints[...])
    ])
    #expect(throws: CRLError.self) { try certificate.crlDistributionPointURLs() }
  }

  private func selfSignedCertificate(extensions: [Certificate.Extension]) throws -> Certificate {
    let attributes: [String: Any] = [kSecAttrKeyType as String: kSecAttrKeyTypeECSECPrimeRandom, kSecAttrKeySizeInBits as String: 256]
    var error: Unmanaged<CFError>?
    let secKey = try #require(SecKeyCreateRandomKey(attributes as CFDictionary, &error))
    let key = try Certificate.PrivateKey(secKey)
    let name = try DistinguishedName { CommonName("CRL test") }
    return try Certificate(
      version: .v3,
      serialNumber: Certificate.SerialNumber(),
      publicKey: key.publicKey,
      notValidBefore: Date(),
      notValidAfter: Date().addingTimeInterval(3600),
      issuer: name,
      subject: name,
      signatureAlgorithm: .ecdsaWithSHA256,
      extensions: Certificate.Extensions(extensions),
      issuerPrivateKey: key
    )
  }

  @Test func issuingDistributionPointWithoutUri_hasUnsupportedScope() throws {
    let idp = try IssuingDistributionPoint(der: [0x30, 0x04, 0xA0, 0x02, 0xA0, 0x00])
    #expect(idp.hasUnsupportedScope)
  }

  @Test func issuingDistributionPoint_isParsedAndScoped() throws {
    let crl = try CertificateRevocationList(der: Array(fixture("crl-test-ca", "crl")))
    let idp = try #require(crl.issuingDistributionPoint)
    let url = try #require(URL(string: "https://crl.example.test/ca.crl"))
    #expect(crl.unsupportedCriticalExtensions.isEmpty)
    #expect(idp.uris == ["https://crl.example.test/ca.crl"])
    #expect(idp.onlyContainsUserCerts)
    #expect(throws: Never.self) { try idp.checkScope(url: url, certificateIsCA: false) }
    #expect(throws: CRLError.self) { try idp.checkScope(url: url, certificateIsCA: true) }
    #expect(throws: CRLError.self) {
      try idp.checkScope(url: #require(URL(string: "https://example.test/other.crl")), certificateIsCA: false)
    }
  }
}

private final class Box<Value>: @unchecked Sendable {
  var value: Value

  init(_ value: Value) {
    self.value = value
  }
}
