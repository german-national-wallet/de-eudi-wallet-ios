//
//  PinnedCertificateNetworkingTests.swift
//  logic-core
//
//  Created by Tamas Dancsi on 04.05.26.
//

import Testing
import logic_api
@testable import logic_core

@Suite("PinnedCertificateNetworking")
struct PinnedCertificateNetworkingTests {

  private func makeSUT() -> PinnedCertificateNetworking {
    PinnedCertificateNetworking(
      logger: nil,
      certificatePinner: CertificatePinner(letsEncryptHostSuffixes: ["nwb.youniqx.com", "eudiw.gov.de"])
    )
  }

  @Test
  func shouldLoadOnlyExplicitPinFiles() {
    let sut = makeSUT()

    #expect(sut.isPinCertificateFileName("pidp-tls-pin-d-trust-br-root-ca-2-2023.der"))
    #expect(sut.isPinCertificateFileName("pidp-tls-pin-next.der"))
    #expect(sut.isPinCertificateFileName("le-tls-pin-isrg-root-x1.der"))
    #expect(sut.isPinCertificateFileName("le-tls-pin-isrg-root-yr.der"))

    #expect(!sut.isPinCertificateFileName("pidissuerca02_de.der"))
    #expect(!sut.isPinCertificateFileName("german_registrar.der"))
    #expect(!sut.isPinCertificateFileName("common_codes_eudi_hub_sandbox_access_ca_01.der"))
    #expect(!sut.isPinCertificateFileName("common_codes_eudi_hub_sandbox_registration_ca_01.der"))
    #expect(!sut.isPinCertificateFileName("pidp-tls-pin-d-trust-br-root-ca-2-2023.cer"))
  }

  @Test
  func shouldPinThePIDProviderAndTheConfiguredBackendSuffixes() {
    let sut = makeSUT()

    #expect(sut.pinnedHostSuffix(for: "demo.pid-provider.bundesdruckerei.de") == "pid-provider.bundesdruckerei.de")
    #expect(sut.pinnedHostSuffix(for: "wallet-backend-dev.apps.sandbox.nwb.youniqx.com") == "nwb.youniqx.com")
    #expect(sut.pinnedHostSuffix(for: "wallet.eudiw.gov.de") == "eudiw.gov.de")
  }

  @Test
  func shouldNotPinUnrelatedHosts() {
    let sut = makeSUT()

    #expect(sut.pinnedHostSuffix(for: "evil.com") == nil)
    #expect(sut.pinnedHostSuffix(for: "youniqx.com") == nil)
    #expect(sut.pinnedHostSuffix(for: "notnwb.youniqx.com") == nil)
    #expect(sut.pinnedHostSuffix(for: "fhd.eudi-wallet.org") == nil)
  }
}
