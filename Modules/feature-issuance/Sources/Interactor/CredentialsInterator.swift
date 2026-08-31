//
//  CredentialsInterator.swift
//  feature-issuance
//
import Foundation
import logic_business
import JOSESwift
import logic_core

public protocol CredentialsInteractor: Sendable {
  func getCredentialsWithRefreshToken(_ credentialTypes: [CredentialType], privateKey: SecKey) async throws -> [WalletStorage.Document]
}

public final class CredentialsInteractorImpl: CredentialsInteractor {
    private let walletKitController: WalletKitController
    private let walletPoPController: WalletPoPController
    private let secureEnclaveController: SecureEnclaveController
    private let logger: Logging?

    public init(
        walletKitController: WalletKitController,
        walletPoPController: WalletPoPController,
        secureEnclaveController: SecureEnclaveController,
        logger: Logging? = nil
    ) {
        self.walletKitController = walletKitController
        self.walletPoPController = walletPoPController
        self.secureEnclaveController = secureEnclaveController
        self.logger = logger
    }

  public func getCredentialsWithRefreshToken(_ credentialTypes: [CredentialType], privateKey: SecKey) async throws -> [WalletStorage.Document] {
    logger?.d("RefreshToken: interactor invoked for \(credentialTypes.count) credential type(s)")
    do {
      guard let jwk = try walletPoPController.getPublicKeyJWK(algo: SignatureAlgorithm.ES256.rawValue, privateKey: privateKey, kid: nil) else {
        logger?.e("RefreshToken: DPoP JWK generation returned nil; aborting")
        throw PoPGenerationError.keyGenerationFailed
      }
      let issuerDPopConstructorParam = IssuerDPoPConstructorParam(clientID: nil, expirationDuration: nil, aud: nil, jti: nil, jwk: jwk, privateKey: privateKey)

      let docs = try await walletKitController.getCredentialsWithRefreshToken(credentialTypes: credentialTypes, issuerDPopConstructorParam: issuerDPopConstructorParam)
      logger?.d("RefreshToken: interactor completed with \(docs.count) document(s)")
      return docs
    } catch {
      logger?.e("RefreshToken: interactor failed: \(error.logDescriptor)")
      throw error
    }
  }
}
