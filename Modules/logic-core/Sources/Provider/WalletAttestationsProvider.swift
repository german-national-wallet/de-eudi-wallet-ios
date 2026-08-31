//
//  WalletKitAttestationProvider.swift
//  logic-core
//

@preconcurrency import logic_api
import JOSESwift
import OpenID4VCI
import Foundation
import logic_business
import MdocDataModel18013

final class WalletAttestationProviderImpl: WalletAttestationsProviderForWalletAppCompatibility {
  private let wiaIssuanceService: WIAIssuanceService
  private let secureEnclaveController: SecureEnclaveController

  init(
    wiaIssuanceService: WIAIssuanceService,
    secureEnclaveController: SecureEnclaveController
  ) {
    self.wiaIssuanceService = wiaIssuanceService
    self.secureEnclaveController = secureEnclaveController
  }

  func getWalletAttestation(signingKey: SigningKeyProxy) async throws -> String {
    guard case let .secKey(privateKey) = signingKey else {
      throw SecureAreaError("Unsupported signing key type: wallet attestation requires a SecKey-backed signing key")
    }
    let wia = try await wiaIssuanceService.issueWIA(wiaPrivateKey: privateKey)
    return wia
  }

  func getKeysAttestation(keys: [any JWK], nonce: String?) async throws -> String {
    guard let firstKey = keys.first as? ECPublicKey else {
      throw SecureAreaError("Key attestation requires at least one EC public key")
    }
    let keyTag = SecureEnclaveKeys.custom(RemoteWSCAService.wteKeychainTag(forKeyX: firstKey.x))
    guard let wte = secureEnclaveController.retrieveStringFromKeychain(keyTag: keyTag), !wte.isEmpty else {
      throw SecureAreaError("No key attestation (WTE) found for the requested keys")
    }
    return wte
  }

  func getKeysAttestation(docType: String) async throws -> String? {
    let wte = secureEnclaveController.retrieveStringFromKeychain(keyTag: .custom(docType))
    secureEnclaveController.deleteKeychainItem(keyTag: .custom(docType))
    return wte
  }
}
