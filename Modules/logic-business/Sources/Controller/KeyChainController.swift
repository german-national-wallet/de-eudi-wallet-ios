/*
 * Copyright (c) 2023 European Commission
 *
 * Licensed under the EUPL, Version 1.2 or - as soon they will be approved by the European
 * Commission - subsequent versions of the EUPL (the "Licence"); You may not use this work
 * except in compliance with the Licence.
 *
 * You may obtain a copy of the Licence at:
 * https://joinup.ec.europa.eu/software/page/eupl
 *
 * Unless required by applicable law or agreed to in writing, software distributed under
 * the Licence is distributed on an "AS IS" basis, WITHOUT WARRANTIES OR CONDITIONS OF
 * ANY KIND, either express or implied. See the Licence for the specific language
 * governing permissions and limitations under the Licence.
 */
import Foundation
@preconcurrency import KeychainAccess

public protocol KeyChainWrapper {
  var value: String { get }
}

public protocol KeyChainController: Sendable {
    func storeValue(key: KeyChainWrapper, value: String)
    func storeValue(key: KeyChainWrapper, value: Data)
    func getValue(key: KeyChainWrapper) -> String?
    func getData(key: KeyChainWrapper) -> Data?
    func removeObject(key: KeyChainWrapper)
    func validateKeyChainBiometry() throws
    func clearKeyChainBiometry()
    func clear()
    func clearAllKeychainItems()
}

final class KeyChainControllerImpl: KeyChainController {

  private let biometryKey = "eu.europa.ec.euidi.biometric.access"
  private let keyChain: Keychain = Keychain()
    .accessibility(.whenUnlockedThisDeviceOnly)
  private let logger: Logging?

  public init(logger: Logging? = nil) {
    self.logger = logger
  }

  public func storeValue(key: KeyChainWrapper, value: String) {
    logger?.d("[STORAGE] store key=\(key.value) dest=keychain")
    try? keyChain.set(value, key: key.value)
  }

  public func storeValue(key: KeyChainWrapper, value: Data) {
    logger?.d("[STORAGE] store key=\(key.value) dest=keychain")
    try? keyChain.set(value, key: key.value)
  }

  public func getValue(key: KeyChainWrapper) -> String? {
    keyChain[key.value]
  }

  func getData(key: KeyChainWrapper) -> Data? {
    try? keyChain.getData(key.value)
  }

  public func removeObject(key: KeyChainWrapper) {
    logger?.d("[STORAGE] clear key=\(key.value) dest=keychain")
    try? keyChain.remove(key.value)
  }

  public func validateKeyChainBiometry() throws {
    try setBiometricKey()
    try isBiometricKeyValid()
  }

  public func clearKeyChainBiometry() {
    try? self.keyChain.remove(self.biometryKey)
  }

  public func clear() {
    logger?.d("[STORAGE] clear-all dest=keychain (app keychain service)")
    try? keyChain.removeAll()
  }

  public func clearAllKeychainItems() {
    logger?.d("[STORAGE] clear-all dest=keychain (all keychain item classes)")
    let secItemClasses = [
      kSecClassGenericPassword,
      kSecClassInternetPassword,
      kSecClassCertificate,
      kSecClassKey,
      kSecClassIdentity
    ]

    for itemClass in secItemClasses {
      let query: [String: Any] = [kSecClass as String: itemClass]
      SecItemDelete(query as CFDictionary)
    }
  }
}

private extension KeyChainControllerImpl {
  func setBiometricKey() throws {
    try self.keyChain
      .accessibility(
        .whenPasscodeSetThisDeviceOnly,
        authenticationPolicy: [.touchIDAny]
      )
      .set(UUID().uuidString, key: self.biometryKey)
  }

  func isBiometricKeyValid() throws {

    let item = try self.keyChain
      .get(self.biometryKey)

    if item != nil {
      clearKeyChainBiometry()
    }
  }
}

public enum KeyChainIdentifier: String, KeyChainWrapper {

  public var value: String {
    self.rawValue
  }

  case realmKey
  case debugConfigWalletHostURL = "debug_config_wallet_host_url"
  case debugConfigWalletAPIKey = "debug_config_wallet_api_key"
  case debugConfigOTLPHostURL = "debug_config_otlp_host_url"
  case debugConfigOTLPAuthToken = "debug_config_otlp_auth_token"
  case debugConfigPIDProviderURL = "debug_config_pid_provider_url"
}
