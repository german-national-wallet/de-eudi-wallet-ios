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

public protocol PrefsController: Sendable {
  func setValue(_ value: Any?, forKey: Prefs.Key)
  func getString(forKey: Prefs.Key) -> String?
  func getOptionalString(forKey: Prefs.Key) -> String
  func getBool(forKey: Prefs.Key) -> Bool
  func getFloat(forKey: Prefs.Key) -> Float
  func getInt(forKey: Prefs.Key) -> Int
  func remove(forKey: Prefs.Key)
  func getValue(forKey: Prefs.Key) -> Any?
  func getUserLocale() -> String
  func fetchAndDeleteValue(forKey key: Prefs.Key) -> Any?
  func saveObject<T: Encodable>(_ object: T, forKey key: Prefs.Key)
  func getObject<T: Decodable>(forKey key: Prefs.Key, as type: T.Type) -> T?
}

final public class PrefsControllerImpl: PrefsController {

  private let logger: Logging?

  public init(logger: Logging? = nil) {
    self.logger = logger
  }

  public func setValue(_ value: Any?, forKey: Prefs.Key) {
    logger?.d("[STORAGE] store key=\(forKey.rawValue) dest=userDefaults")
    UserDefaults.standard.setValue(value, forKey: forKey.rawValue)
  }

  public func getString(forKey: Prefs.Key) -> String? {
    return UserDefaults.standard.string(forKey: forKey.rawValue)
  }

  public func getOptionalString(forKey: Prefs.Key) -> String {
    return UserDefaults.standard.string(forKey: forKey.rawValue) ?? ""
  }

  public func getFloat(forKey: Prefs.Key) -> Float {
    return UserDefaults.standard.float(forKey: forKey.rawValue)
  }

  public func getBool(forKey: Prefs.Key) -> Bool {
    return UserDefaults.standard.bool(forKey: forKey.rawValue)
  }

  public func remove(forKey: Prefs.Key) {
    logger?.d("[STORAGE] clear key=\(forKey.rawValue) dest=userDefaults")
    UserDefaults.standard.removeObject(forKey: forKey.rawValue)
  }

  public func getValue(forKey: Prefs.Key) -> Any? {
    return UserDefaults.standard.value(forKey: forKey.rawValue)
  }
  
  public func fetchAndDeleteValue(forKey key: Prefs.Key) -> Any? {
    let object = UserDefaults.standard.value(forKey: key.rawValue)
    remove(forKey: key)
    return object
  }

  public func getInt(forKey: Prefs.Key) -> Int {
    return UserDefaults.standard.integer(forKey: forKey.rawValue)
  }

  public func getUserLocale() -> String {
    return getString(forKey: .language) ?? "en_GB"
  }

  public func saveObject<T: Encodable>(_ object: T, forKey key: Prefs.Key) {
    if let data = try? JSONEncoder().encode(object) {
      logger?.d("[STORAGE] store key=\(key.rawValue) dest=userDefaults")
      UserDefaults.standard.set(data, forKey: key.rawValue)
    }
  }

  public func getObject<T: Decodable>(forKey key: Prefs.Key, as type: T.Type) -> T? {
    guard let data = UserDefaults.standard.data(forKey: key.rawValue) else {
        return nil
    }
    return try? JSONDecoder().decode(T.self, from: data)
  }
}

public struct Prefs {}

public extension Prefs {
  enum Key: String {
    case biometryEnabled
    case cachedDeepLink
    case runAtLeastOnce
    case language
    case invalidPinResponse
    case mdvmInstallationIdentifier = "mdvm_installation_identifier"
    case featureFlagsPayload = "feature_flags_payload"
    case featureFlagsLastUpdate = "feature_flags_last_update"
    case isPinInitialized
    case hasSeenRevocationCode
    case walletRevoked = "wallet_revoked"
  }
}
