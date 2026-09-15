//
//  ConfigLogicTests.swift
//  logic-business
//
//  Created by Tamas Dancsi on 14.08.26.
//

import Foundation
import Testing

@testable import logic_business

struct ConfigLogicTests {

  @Test
  func walletHostUrl_WhenOverridden_ThenReturnsOverride() {
    let sut = makeSUT(overrides: .init(walletHostURL: "https://wallet.example"))

    #expect(sut.walletHostUrl == "https://wallet.example")
  }

  @Test
  func walletHostUrl_WhenNotOverridden_ThenReturnsBundleValue() {
    let sut = makeSUT(overrides: .init())

    #expect(sut.walletHostUrl == "WALLET_HOST_URL".valueFromBundle)
  }

  @Test
  func walletOTLPURL_WhenOverridden_ThenReturnsOverride() {
    let sut = makeSUT(overrides: .init(otlpHostURL: "https://otlp.example"))

    #expect(sut.walletOTLPURL == "https://otlp.example")
  }

  @Test
  func vciIssuerURL_WhenOverridden_ThenReturnsOverride() {
    let sut = makeSUT(overrides: .init(pidProviderURL: "https://pid.example/"))

    #expect(sut.vciIssuerURL == "https://pid.example/")
  }

  @Test
  func vciIssuerName_WhenPIDProviderOverridden_ThenDerivesHostFromOverride() {
    let sut = makeSUT(overrides: .init(pidProviderURL: "https://pid.example/some/path"))

    #expect(sut.vciIssuerName == "pid.example")
  }

  @Test
  func vciIssuerName_WhenNotOverridden_ThenReturnsBundleValue() {
    let sut = makeSUT(overrides: .init())

    #expect(sut.vciIssuerName == "PID_ISSUER_NAME".valueFromBundle)
  }

  private func makeSUT(overrides: DebugConfigOverrides) -> ConfigLogicImpl {
    ConfigLogicImpl(debugConfigController: DebugConfigControllerStub(overrides: overrides))
  }
}

private struct DebugConfigControllerStub: DebugConfigController {

  let overrides: DebugConfigOverrides

  func store(_ overrides: DebugConfigOverrides) {}

  func clearAll() {}
}
