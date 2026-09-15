//
//  WalletAttestationInteractor.swift
//  feature-common
//

import Foundation
import CryptoKit
import logic_core
import logic_business
import JOSESwift
import wallet_backend

public protocol PARInteractor: AnyObject {
  func fetchPushAuthorisationRequest() async throws -> WalletStorage.Document?
  func removePendingDocs(of docId: String) async throws
  func removeAllPendingDocs() async
  func issuePAR() async throws -> WalletStorage.Document
}

final class PARInteractorImpl: PARInteractor {
  private let walletPoPInteractor: WalletPoPController
  private let walletKitController: WalletKitController
  private let secureEnclaveController: SecureEnclaveController
  private let parExpirationTime: TimeInterval
  private let logger: Logging?

  init(
    walletPoPInteractor: WalletPoPController,
    walletKitController: WalletKitController,
    parExpirationTime: TimeInterval = TimeInterval(5 * 60),
    secureEnclaveController: SecureEnclaveController,
    logger: Logging? = nil
  ) {
    self.walletPoPInteractor = walletPoPInteractor
    self.walletKitController = walletKitController
    self.parExpirationTime = parExpirationTime
    self.secureEnclaveController = secureEnclaveController
    self.logger = logger
  }

  func fetchPushAuthorisationRequest() async throws -> WalletStorage.Document? {
    await removeAllPendingDocs()
    return try await issuePAR()
  }

  func issuePAR() async throws -> WalletStorage.Document {
    guard let pendingDoc = try await walletKitController.issuePAR() else {
        throw PARGenerationError.wiaParCreationFailed
     }
    return pendingDoc
  }
  
  func removePendingDocs(of docID: String) async throws {
    if let pendingDoc = walletKitController.wallet.storage.pendingDocuments.first(where: {
      $0.id == docID || $0.authorizePresentationUrl == docID
    }) {
      try await walletKitController.deleteDocument(with: pendingDoc.id, status: .pending)
    }

    if let deferredDoc = walletKitController.wallet.storage.deferredDocuments.first(where: {
      $0.id == docID
    }) {
      try await walletKitController.deleteDocument(with: deferredDoc.id, status: .deferred)
    }
  }

  func removeAllPendingDocs() async {
    for pendingDoc in walletKitController.wallet.storage.pendingDocuments {
      do {
        try await walletKitController.deleteDocument(with: pendingDoc.id, status: .pending)
      } catch {
        logger?.d("PARInteractor:: pending doc \(pendingDoc.id) was already gone: \(error.localizedDescription)")
      }
    }
  }

  private func getDPopConstructorParameters(_ wia: String, _ privateKey: SecKey?) throws -> IssuerDPoPConstructorParam? {
    do {
      guard let privateKey = privateKey else { throw PoPGenerationError.keyGenerationFailed }

      guard let serializedJWT = try walletPoPInteractor.getSerializedJWT(serializedString: wia, privateKey: privateKey) else { throw PoPGenerationError.invalidJWT }

      guard let publicKeyJWK = try walletPoPInteractor.getPublicKeyJWK(algo: SignatureAlgorithm.ES256.rawValue, privateKey: privateKey, kid: nil) else { throw  PoPGenerationError.invalidJWT }

      return IssuerDPoPConstructorParam(clientID: serializedJWT.sub, expirationDuration: parExpirationTime, aud: serializedJWT.iss, jti: UUID().uuidString, jwk: publicKeyJWK, privateKey: privateKey)
    }
  }
  
  private func getWiaPar(_ wia: String, _ privateKey: SecKey?) throws -> IssuerDPoPConstructorParam? {
      do {
        guard let privateKey = privateKey else { throw PoPGenerationError.keyGenerationFailed }

        guard let serializedJWT = try walletPoPInteractor.getSerializedJWT(serializedString: wia, privateKey: privateKey) else { throw PoPGenerationError.invalidJWT }

        guard let publicKeyJWK = try walletPoPInteractor.getPublicKeyJWK(algo: SignatureAlgorithm.ES256.rawValue, privateKey: privateKey, kid: nil) else { throw  PoPGenerationError.invalidJWT }

        return IssuerDPoPConstructorParam(clientID: serializedJWT.sub, expirationDuration: parExpirationTime, aud: serializedJWT.iss, jti: UUID().uuidString, jwk: publicKeyJWK, privateKey: privateKey)
      }
    }
}
public enum PARGenerationError: LocalizedError, Equatable {
  case walletInstanceIDNotFound
  case attestationKeyCreationFailed
  case attestationNotGenerated
  case wiaParCreationFailed
}
