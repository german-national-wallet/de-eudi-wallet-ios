//
//  CertificatePinningTests.swift
//  logic-api
//

import Testing

@testable import logic_api

struct CertificatePinningTests {

  private let sut = CertificatePinner(letsEncryptHostSuffixes: ["nwb.youniqx.com", "eudiw.gov.de"])

  @Test
  func pinnedHostSuffix_MatchesConfiguredSuffixesAndTheirSubdomains() {
    #expect(sut.pinnedHostSuffix(for: "nwb.youniqx.com") == "nwb.youniqx.com")
    #expect(sut.pinnedHostSuffix(for: "wallet-backend-dev.apps.sandbox.nwb.youniqx.com") == "nwb.youniqx.com")
    #expect(sut.pinnedHostSuffix(for: "eudiw.gov.de") == "eudiw.gov.de")
    #expect(sut.pinnedHostSuffix(for: "wallet.eudiw.gov.de") == "eudiw.gov.de")
    #expect(sut.pinnedHostSuffix(for: "WALLET.EUDIW.GOV.DE") == "eudiw.gov.de")
  }

  @Test
  func pinnedHostSuffix_KeepsPinningThePIDProvider() {
    #expect(sut.pinnedHostSuffix(for: "demo.pid-provider.bundesdruckerei.de") == "pid-provider.bundesdruckerei.de")
    #expect(sut.pinnedHostSuffix(for: "preprod.pid-provider.bundesdruckerei.de") == "pid-provider.bundesdruckerei.de")
  }

  @Test
  func pinnedHostSuffix_DoesNotMatchUnrelatedOrPartialHosts() {
    #expect(sut.pinnedHostSuffix(for: "evil.com") == nil)
    #expect(sut.pinnedHostSuffix(for: "youniqx.com") == nil)
    #expect(sut.pinnedHostSuffix(for: "gov.de") == nil)
    #expect(sut.pinnedHostSuffix(for: "notnwb.youniqx.com") == nil)
    #expect(sut.pinnedHostSuffix(for: "nwb.youniqx.com.evil.com") == nil)
    #expect(sut.pinnedHostSuffix(for: "bundesdruckerei.de") == nil)
  }

  @Test
  func pinnedHostSuffix_IsNilWhenNoSuffixesAreConfigured() {
    let sut = CertificatePinner(letsEncryptHostSuffixes: [])

    #expect(sut.pinnedHostSuffix(for: "nwb.youniqx.com") == nil)
    #expect(sut.pinnedHostSuffix(for: "demo.pid-provider.bundesdruckerei.de") == "pid-provider.bundesdruckerei.de")
  }

  @Test
  func anchors_AreGroupedPerHostSuffixSoOneGroupCannotSatisfyAnother() {
    #expect(sut.anchors(forHostSuffix: "nwb.youniqx.com").isEmpty)
    #expect(sut.anchors(forHostSuffix: "eudiw.gov.de").isEmpty)
    #expect(sut.anchors(forHostSuffix: "pid-provider.bundesdruckerei.de").isEmpty)
    #expect(sut.anchors(forHostSuffix: "evil.com").isEmpty)
  }

  @Test
  func isPinCertificateFileName_AcceptsBothPinPrefixesOnly() {
    #expect(sut.isPinCertificateFileName("pidp-tls-pin-d-trust-br-root-ca-2-2023.der"))
    #expect(sut.isPinCertificateFileName("le-tls-pin-isrg-root-x1.der"))
    #expect(sut.isPinCertificateFileName("le-tls-pin-isrg-root-x2.der"))
    #expect(sut.isPinCertificateFileName("le-tls-pin-isrg-root-ye.der"))
    #expect(sut.isPinCertificateFileName("le-tls-pin-isrg-root-yr.der"))

    #expect(!sut.isPinCertificateFileName("pidissuerca02_de.der"))
    #expect(!sut.isPinCertificateFileName("german_registrar.der"))
    #expect(!sut.isPinCertificateFileName("le-tls-pin-isrg-root-x1.cer"))
    #expect(!sut.isPinCertificateFileName("isrg-root-x1.der"))
  }

  @Test
  func serverTrustManager_ResolvesAnEvaluatorOnlyForPinnedHosts() throws {
    let sut = PinnedServerTrustManager(pinner: sut)

    #expect(try sut.serverTrustEvaluator(forHost: "wallet-backend-dev.apps.sandbox.nwb.youniqx.com") != nil)
    #expect(try sut.serverTrustEvaluator(forHost: "wallet.eudiw.gov.de") != nil)
    #expect(try sut.serverTrustEvaluator(forHost: "demo.pid-provider.bundesdruckerei.de") != nil)

    #expect(try sut.serverTrustEvaluator(forHost: "fhd.eudi-wallet.org") == nil)
    #expect(try sut.serverTrustEvaluator(forHost: "evil.com") == nil)
  }
}
