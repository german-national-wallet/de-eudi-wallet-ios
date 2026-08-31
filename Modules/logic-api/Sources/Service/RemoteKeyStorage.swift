//
//  RemoteKeyStorage.swift
//  logic-api
//

import Foundation
import MdocDataModel18013
import WalletStorage
import logic_business

public actor RemoteKeyStorage: SecureKeyStorage {
  public let serviceName: String
  public let accessGroup: String?
  var dict: [String: Data]?
  var keyOptions: KeyOptions?
  private let logger: Logging?

  public init(serviceName: String, accessGroup: String?, logger: Logging? = nil) {
    self.serviceName = serviceName
    self.accessGroup = accessGroup
    self.logger = logger
  }
  static func keyChainDataValue(key: String, value: Any) -> (String, Data)? {
    if let v = value as? String { (key, v.data(using: .utf8)!) } else if let v = value as? Data { (key, v) } else { nil }
  }

  public func readKeyInfo(id: String) throws -> [String: Data] {
    guard let dicts = try loadData(serviceName: serviceName, accessGroup: accessGroup, id: id, status: .issued, dataToLoadType: .keyInfo), !dicts.isEmpty else { return [:] }
    return Dictionary(uniqueKeysWithValues: dicts.first!.compactMap(Self.keyChainDataValue))
  }

  public func readKeyData(id: String, index: Int) throws -> [String: Data] {
    guard let dicts = try loadData(serviceName: serviceName, accessGroup: accessGroup, id: "\(id)_\(index)", status: .issued, dataToLoadType: .key), !dicts.isEmpty else { return [:] }
    return Dictionary(uniqueKeysWithValues: dicts.first!.compactMap(Self.keyChainDataValue))
  }

  // save key public info
  public func writeKeyInfo(id: String, dict: [String: Data]) throws {
    self.dict = dict
    logger?.d("[STORAGE] store key=\(id) dest=keychain")
    try KeyChainStorageService.saveDocumentData(serviceName: serviceName, accessGroup: accessGroup, id: id, status: .issued, dataType: .keyInfo, setDictValues: setDictValues1, allowOverwrite: true)
  }

  // save key batch info
  public func writeKeyDataBatch(id: String, startIndex: Int, dicts: [[String: Data]], keyOptions: MdocDataModel18013.KeyOptions?) async throws {
    guard dicts.count > 0 else { return }
    self.keyOptions = keyOptions
    for i in startIndex..<dicts.count+startIndex {
      self.dict = dicts[i]
      logger?.d("[STORAGE] store key=\(id)_\(i) dest=keychain")
      try KeyChainStorageService.saveDocumentData(serviceName: serviceName, accessGroup: accessGroup, id: "\(id)_\(i)", status: .issued, dataType: .key, setDictValues: setDictValues2, allowOverwrite: true)
    }
  }

  // delete key info and data
  public func deleteKeyBatch(id: String, startIndex: Int, batchSize: Int) throws {
    for index in startIndex..<batchSize+startIndex {
      logger?.d("[STORAGE] clear key=\(id)_\(index) dest=keychain")
      try? KeyChainStorageService.deleteDocumentData(serviceName: serviceName, accessGroup: accessGroup, id: "\(id)_\(index)", docStatus: .issued, dataType: .key)
    }
  }

  public func deleteKeyInfo(id: String) throws {
    logger?.d("[STORAGE] clear key=\(id) dest=keychain")
    try KeyChainStorageService.deleteDocumentData(serviceName: serviceName, accessGroup: accessGroup, id: id, docStatus: .issued, dataType: .keyInfo)
  }

  // helper function to convert generic data dictionary to keychain expected dictionary
  func setDictValues1(_ d: inout [String: Any]) {
    guard let dict else { return }
    for (k, v) in dict { d[k] = if k == kSecValueData as String { v } else { String(data: v, encoding: .utf8) ?? "" } }
    // Bind the key material to the device passcode so it is dropped when Platform Authentication is removed.
    d[kSecAttrAccessible as String] = kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly
  }

  // Helper function to convert generic data dictionary to keychain expected dictionary and bind the stored item to this device without requiring user presence for each item.
  func setDictValues2(_ d: inout [String: Any]) {
    guard let dict else { return }
    for (k, v) in dict { d[k] = if k == kSecValueData as String { v } else { String(data: v, encoding: .utf8) ?? "" } }
    // Bind the key material to the device passcode so it is dropped when Platform Authentication is removed.
    d[kSecAttrAccessible as String] = keyOptions?.accessProtection?.constant ?? kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly
  }

  func loadData(serviceName: String, accessGroup: String?, id: String?, status: DocumentStatus, dataToLoadType: SavedKeyChainDataType) throws -> [[String: Any]]? {
    let query = makeQuery(serviceName: serviceName, accessGroup: accessGroup, id: id, bForSave: false, status: status, dataType: dataToLoadType)
    var result: CFTypeRef?
    let status = SecItemCopyMatching(query as CFDictionary, &result)
    if status == errSecItemNotFound { return nil }
    guard status == errSecSuccess else {
      throw SecureAreaError("Invalid Base64URL encoding")
    }
    if let res = result as? [[String: Any]] { return res }
    if let res1 = result as? [String: Any] { return [res1] }
    return nil
  }

  func makeQuery(serviceName: String, accessGroup: String?, id: String?, bForSave: Bool, status: DocumentStatus, dataType: SavedKeyChainDataType) -> [String: Any] {
    let comps = [serviceName, dataType.rawValue, status.rawValue ]
    let queryValue = comps.joined(separator: ":")
    var query: [String: Any] = [kSecClass: kSecClassGenericPassword, kSecAttrService: queryValue, kSecUseDataProtectionKeychain: true] as [String: Any]
    if !bForSave {
      query[kSecReturnAttributes as String] = true
      query[kSecReturnData as String] = true
    }
    if let id { query[kSecAttrAccount as String] = id } else { query[kSecMatchLimit as String] = kSecMatchLimitAll }
    if let accessGroup, !accessGroup.isEmpty { query[kSecAttrAccessGroup as String] = accessGroup }
    return query
  }
}
