//
//  DebugConfigControllerTests.swift
//  logic-business
//
//  Created by Tamas Dancsi on 14.08.26.
//

import Foundation
import Testing

@testable import logic_business

struct DebugConfigControllerTests {

  @Test
  func store_WhenValuesProvided_ThenOverridesRoundTrip() {
    let (sut, _) = makeSUT(buildVariant: .DEV)
    let overrides = DebugConfigOverrides(
      walletHostURL: "https://wallet.example",
      walletAPIKey: "api-key",
      otlpHostURL: "https://otlp.example",
      otlpAuthToken: "auth-token",
      pidProviderURL: "https://pid.example/"
    )

    sut.store(overrides)

    #expect(sut.overrides == overrides)
  }

  @Test
  func store_WhenValuesHaveWhitespace_ThenStoresTrimmedValues() {
    let (sut, _) = makeSUT(buildVariant: .SANDBOX)

    sut.store(.init(walletHostURL: "  https://wallet.example \n"))

    #expect(sut.overrides.walletHostURL == "https://wallet.example")
  }

  @Test
  func store_WhenValueIsBlank_ThenRemovesOverride() {
    let (sut, _) = makeSUT(buildVariant: .DEV)
    sut.store(.init(walletHostURL: "https://wallet.example", walletAPIKey: "api-key"))

    sut.store(.init(walletHostURL: "  ", walletAPIKey: nil))

    #expect(!sut.overrides.hasOverrides)
  }

  @Test
  func clearAll_WhenOverridesStored_ThenRemovesEverything() {
    let (sut, keyChain) = makeSUT(buildVariant: .DEV)
    sut.store(
      .init(
        walletHostURL: "https://wallet.example",
        walletAPIKey: "api-key",
        otlpHostURL: "https://otlp.example",
        otlpAuthToken: "auth-token",
        pidProviderURL: "https://pid.example"
      )
    )

    sut.clearAll()

    #expect(!sut.overrides.hasOverrides)
    #expect(keyChain.storage.isEmpty)
  }

  @Test
  func store_WhenBuildVariantIsStaging_ThenStoresNothing() {
    let (sut, keyChain) = makeSUT(buildVariant: .STAGING)

    sut.store(.init(walletHostURL: "https://wallet.example"))

    #expect(keyChain.storage.isEmpty)
  }

  @Test
  func overrides_WhenBuildVariantIsStaging_ThenIgnoresStoredValues() {
    let (sut, keyChain) = makeSUT(buildVariant: .STAGING)
    keyChain.storage[KeyChainIdentifier.debugConfigWalletHostURL.rawValue] = "https://wallet.example"
    keyChain.storage[KeyChainIdentifier.debugConfigWalletAPIKey.rawValue] = "api-key"

    #expect(!sut.overrides.hasOverrides)
  }

  private func makeSUT(buildVariant: AppBuildVariant) -> (DebugConfigControllerImpl, KeyChainControllerFake) {
    let keyChain = KeyChainControllerFake()
    return (DebugConfigControllerImpl(keyChainController: keyChain, buildVariant: buildVariant), keyChain)
  }
}

// In-memory store keeps the tests deterministic and free of Keychain side effects.
private final class KeyChainControllerFake: KeyChainController, @unchecked Sendable {

  var storage: [String: String] = [:]

  func storeValue(key: KeyChainWrapper, value: String) {
    storage[key.value] = value
  }

  func storeValue(key: KeyChainWrapper, value: Data) {
    storage[key.value] = String(bytes: value, encoding: .utf8)
  }

  func getValue(key: KeyChainWrapper) -> String? {
    storage[key.value]
  }

  func getData(key: KeyChainWrapper) -> Data? {
    storage[key.value].map { Data($0.utf8) }
  }

  func removeObject(key: KeyChainWrapper) {
    storage.removeValue(forKey: key.value)
  }

  func validateKeyChainBiometry() throws {}

  func clearKeyChainBiometry() {}

  func clear() {
    storage.removeAll()
  }

  func clearAllKeychainItems() {
    storage.removeAll()
  }
}
