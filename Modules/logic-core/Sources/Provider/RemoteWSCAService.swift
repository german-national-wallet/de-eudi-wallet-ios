//
//  RemoteWSCAService.swift
//  logic-core
//

import Foundation
import CryptoKit
import JOSESwift
import Security
import MdocDataModel18013
import logic_business
import OpenID4VCI
import logic_api

public actor RemoteWSCAService: SecureArea {

  var storage: any SecureKeyStorage
  private var secureEnclaveController: SecureEnclaveController?
  private var rwscaInteractor: RWSCAInteractor?
  private var nonceRepository: NonceRepository?
  private var config: ConfigLogic?

  public init(
    storage: any SecureKeyStorage,
  ) {
    self.storage = storage
  }

  public init(
    secureEnclaveController: SecureEnclaveController?,
    rwscaInteractor: RWSCAInteractor?,
    nonceRepository: NonceRepository?,
    storage: any SecureKeyStorage,
    config: ConfigLogic?,
  ) {
    self.secureEnclaveController = secureEnclaveController
    self.rwscaInteractor = rwscaInteractor
    self.nonceRepository = nonceRepository
    self.storage = storage
    self.config = config
  }

  public static var name: String = "RemoteWSCAService"

  public static var supportedEcCurves: [MdocDataModel18013.CoseEcCurve] = [.P256]

  public static func create(storage: any MdocDataModel18013.SecureKeyStorage) -> RemoteWSCAService {
    RemoteWSCAService(storage: storage)
  }

  public func createKeyBatch(id: String, credentialOptions: MdocDataModel18013.CredentialOptions, keyOptions: MdocDataModel18013.KeyOptions?) async throws -> [MdocDataModel18013.CoseKey] {

    guard let vciIssuerURL = config?.vciIssuerURL,
          let wteNonce = try await nonceRepository?.fetchNonce(baseURL: vciIssuerURL) else {
      throw SecureAreaError("Failed to retrieve nonce from nonce endpoint")
    }
    
    let createResponse = try await rwscaInteractor?.createKeys(
      numberOfKeys: credentialOptions.batchSize,
      ppCNonce: wteNonce
    )

    let wte = createResponse?.rwscaWTE ?? ""
    let docType = keyOptions?.additionalOptions.flatMap { String(data: $0, encoding: .utf8) }

    if let docType {
      _ = secureEnclaveController?.storeStringInKeychain(value: wte, keyTag: SecureEnclaveKeys.custom(docType))
    }

    guard let rwscaWIKeys = createResponse?.rwscaWIKeys else {
      throw SecureAreaError("Failed to retrieve response object")
    }
    var coseKeys: [CoseKey] = []
    var keyMetaDataList: [KeyMetaData] = []

    for rwscaWIKey in rwscaWIKeys {
      if let coseKey = try? getCOSKey(publicKey: rwscaWIKey.rwscdWIPubk) {
        let keyMetaData = KeyMetaData(
          wrappedPrivKey: rwscaWIKey.rwscaWIWrappedPrvk,
          keyPurposes: keyOptions?.keyPurposes ?? [],
          publicKey: coseKey
        )
        keyMetaDataList.append(keyMetaData)
        coseKeys.append(coseKey)
      }
    }
    if docType == nil, let firstKey = coseKeys.first, !wte.isEmpty {
      _ = secureEnclaveController?.storeStringInKeychain(value: wte, keyTag: .custom(Self.wteKeychainTag(for: firstKey)))
    }
    try await storeKeyMetaData(id: id, keyMetaDatas: keyMetaDataList, keyOptions: keyOptions ?? KeyOptions(), credentialOptions: credentialOptions)
    return coseKeys
  }

  static func wteKeychainTag(forKeyX x: String) -> String {
    "rwsca_wte_\(x)"
  }

  private static func wteKeychainTag(for key: CoseKey) -> String {
    wteKeychainTag(forKeyX: Data(key.x).base64URLEncodedString())
  }

  public func getPublicKey(id: String, index: Int, curve: MdocDataModel18013.CoseEcCurve) async throws -> MdocDataModel18013.CoseKey {
    try await getKeyMetaData(for: id, index: index).publicKey
  }

  public func deleteKeyBatch(id: String, startIndex: Int, batchSize: Int) async throws {
    await deleteStoredWTEs(id: id, startIndex: startIndex, batchSize: batchSize)
    try await storage.deleteKeyBatch(id: id, startIndex: startIndex, batchSize: batchSize)
  }

  public func deleteKeyInfo(id: String) async throws {
    try await storage.deleteKeyInfo(id: id)
  }

  private func deleteStoredWTEs(id: String, startIndex: Int, batchSize: Int) async {
    guard batchSize > 0 else { return }
    for index in startIndex..<(startIndex + batchSize) {
      guard let publicKey = try? await getKeyMetaData(for: id, index: index).publicKey else { continue }
      secureEnclaveController?.deleteKeychainItem(keyTag: .custom(Self.wteKeychainTag(for: publicKey)))
    }
  }

  public func signature(id: String, index: Int, algorithm: MdocDataModel18013.SigningAlgorithm, dataToSign: Data, unlockData: Data?) async throws -> Data {
    let keyMetaData = try await getKeyMetaData(for: id, index: index)

    guard let pinSessionToken = secureEnclaveController?.retrieveStringFromKeychain(keyTag: .pinSessionToken) else {
      throw SecureAreaError("PIN session token is required for signing")
    }

    let result = try await rwscaInteractor?.signData(
      wrappedPrivateKey: keyMetaData.wrappedPrivKey,
      keyBindingData: dataToSign,
      pinSessionToken: pinSessionToken
    )
    guard let rwscdKeyBindingSignature = result?.rwscdKeyBindingSignature, let signatureDER = Data(base64Encoded: rwscdKeyBindingSignature) else {
      throw SecureAreaError("Invalid Base64 signature format")
    }

    let rawSignature = try convertDERSignatureToRaw(signatureDER)
    return rawSignature
  }

  public func keyAgreement(id: String, index: Int, publicKey: MdocDataModel18013.CoseKey, unlockData: Data?) async throws -> SharedSecret {
    throw SecureAreaError("Not implemented")
  }

  public func getStorage() async -> any MdocDataModel18013.SecureKeyStorage {
    storage
  }

  private func convertDERSignatureToRaw(_ derSignature: Data) throws -> Data {
    let derBytes = [UInt8](derSignature)

    guard derBytes.count > 6, derBytes[0] == 0x30 else {
      throw SecureAreaError("Invalid DER signature format")
    }

    let totalLength = Int(derBytes[1])
    guard totalLength + 2 == derBytes.count else {
      throw SecureAreaError("Invalid DER length")
    }

    var index = 2
    guard derBytes[index] == 0x02 else { throw SecureAreaError("Invalid r value format") }
    index += 1
    let rLength = Int(derBytes[index])
    index += 1
    guard index + rLength <= derBytes.count else { throw SecureAreaError("Invalid r length") }
    var rBytes = Array(derBytes[index..<(index + rLength)])
    index += rLength

    guard derBytes[index] == 0x02 else { throw SecureAreaError("Invalid s value format") }
    index += 1
    let sLength = Int(derBytes[index])
    index += 1
    guard index + sLength == derBytes.count else { throw SecureAreaError("Invalid s length") }
    var sBytes = Array(derBytes[index..<(index + sLength)])

    // Trim leading zeros if necessary
    while rBytes.count > 32 && rBytes.first == 0x00 { rBytes.removeFirst() }
    while sBytes.count > 32 && sBytes.first == 0x00 { sBytes.removeFirst() }

    // Pad to 32 bytes
    rBytes = Array(repeating: 0, count: max(0, 32 - rBytes.count)) + rBytes
    sBytes = Array(repeating: 0, count: max(0, 32 - sBytes.count)) + sBytes

    return Data(rBytes + sBytes)
  }

  private func getKeyMetaData(for id: String, index: Int) async throws -> KeyMetaData {
    let keyDataDict = try await storage.readKeyData(id: id, index: index)
    guard let jsonData = keyDataDict[kSecValueData as String] else {
      throw SecureAreaError("Key mapping not found")
    }
    guard let mappingData = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else {
      throw SecureAreaError("Invalid key mapping format")
    }

    guard let wrappedPrivKey = mappingData[Key.wrapped_priv_key.rawValue] as? String,
          let keyPurposeStrings = mappingData[Key.key_purpose.rawValue] as? [String],
          let coseKeyDict = mappingData[Key.public_key.rawValue] as? [String: Any],
          let x963Base64 = coseKeyDict[Key.x963Representation.rawValue] as? String,
          let x963Representation = Data(base64Encoded: x963Base64) else {
      throw SecureAreaError("Invalid key mapping structure")
    }

    let coseKey = CoseKey(crv: .P256, x963Representation: x963Representation)
    let keyPurposes = keyPurposeStrings.compactMap { KeyPurpose(rawValue: $0) }

    return KeyMetaData(
      wrappedPrivKey: wrappedPrivKey,
      keyPurposes: keyPurposes,
      publicKey: coseKey
    )
  }

  private func storeKeyMetaData(
    id: String,
    keyMetaDatas: [KeyMetaData],
    keyOptions: KeyOptions,
    credentialOptions: CredentialOptions
  ) async throws {
    var dicts: [[String: Data]] = []

    for keyMetaData in keyMetaDatas {
      let coseKeyDict: [String: Any] = [
        Key.x963Representation.rawValue: keyMetaData.publicKey.x963Representation.base64EncodedString()
      ]
      let mappingData: [String: Any] = [
        Key.wrapped_priv_key.rawValue: keyMetaData.wrappedPrivKey,
        Key.key_purpose.rawValue: keyMetaData.keyPurposes.map { $0.rawValue },
        Key.public_key.rawValue: coseKeyDict
      ]

      let jsonData = try JSONSerialization.data(withJSONObject: mappingData)
      dicts.append([
        kSecValueData as String: jsonData
      ])
    }
    let kbi = KeyBatchInfo(secureAreaName: Self.name, crv: .P256, usedCounts: Array(repeating: 0, count: credentialOptions.batchSize), credentialPolicy: credentialOptions.credentialPolicy)
    if let data = kbi.toData() {
      try await storage.writeKeyInfo(id: id, dict: [kSecValueData as String: data, kSecAttrDescription as String: Self.defaultEcCurve.jwkName.data(using: .utf8)!])
    }
    try await storage.writeKeyDataBatch(id: id, startIndex: 0, dicts: dicts, keyOptions: keyOptions)
  }

  private func getCOSKey(publicKey: String) throws -> CoseKey? {
    guard let derData = Data(base64URLEncoded: publicKey) else {
      throw SecureAreaError("Invalid Base64URL encoding")
    }
    let x963Representation = try getX963Representation(from: derData)

    return CoseKey(crv: .P256, x963Representation: x963Representation)
  }

  private func getX963Representation(from publicKeyData: Data) throws -> Data {
    guard publicKeyData.count >= 91,
          publicKeyData[0] == 0x30,
          publicKeyData[23] == 0x03,
          publicKeyData[25] == 0x00,
          publicKeyData[26] == 0x04 else {
      throw SecureAreaError("Invalid public key format")
    }

    return publicKeyData.suffix(from: 26)
  }

  private struct KeyMetaData {
    let wrappedPrivKey: String
    let keyPurposes: [KeyPurpose]
    let publicKey: CoseKey
  }

  private enum Key: String {
    case public_key = "publicKey"
    case wrapped_priv_key = "wrappedPrivateKey"
    case key_purpose = "keyPurpose"
    case x963Representation = "x963Representation"
  }
}
