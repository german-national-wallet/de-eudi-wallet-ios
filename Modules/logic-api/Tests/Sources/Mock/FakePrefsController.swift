//
//  FakePrefsController.swift
//  logic-api
//
//  Created by Tamas Dancsi on 19.02.26.
//

import Foundation

@testable import logic_business

final class FakePrefsController: PrefsController, @unchecked Sendable {
  private var storage: [String: Any] = [:]

  func setValue(_ value: Any?, forKey: Prefs.Key) {
    storage[forKey.rawValue] = value
  }

  func getString(forKey: Prefs.Key) -> String? {
    storage[forKey.rawValue] as? String
  }

  func getOptionalString(forKey: Prefs.Key) -> String {
    getString(forKey: forKey) ?? ""
  }

  func getBool(forKey: Prefs.Key) -> Bool {
    storage[forKey.rawValue] as? Bool ?? false
  }

  func getFloat(forKey: Prefs.Key) -> Float {
    storage[forKey.rawValue] as? Float ?? 0
  }

  func getInt(forKey: Prefs.Key) -> Int {
    storage[forKey.rawValue] as? Int ?? 0
  }

  func remove(forKey: Prefs.Key) {
    storage.removeValue(forKey: forKey.rawValue)
  }

  func getValue(forKey: Prefs.Key) -> Any? {
    storage[forKey.rawValue]
  }

  func getUserLocale() -> String {
    "en_GB"
  }

  func fetchAndDeleteValue(forKey key: Prefs.Key) -> Any? {
    let value = storage[key.rawValue]
    storage.removeValue(forKey: key.rawValue)
    return value
  }

  func saveObject<T: Encodable>(_ object: T, forKey key: Prefs.Key) {
    storage[key.rawValue] = object
  }

  func getObject<T: Decodable>(forKey key: Prefs.Key, as type: T.Type) -> T? {
    storage[key.rawValue] as? T
  }
}
