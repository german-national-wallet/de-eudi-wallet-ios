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
@preconcurrency import logic_core
import logic_business
import logic_api
@preconcurrency import feature_common
import JOSESwift
import feature_issuance

public struct OnlineAuthenticationRequestSuccessModel: Sendable {
  var requestDataCells: [RequestDataUiModel]
  var relyingParty: String
  var dataRequestInfo: String
  var isTrusted: Bool
}

public enum PresentationCoordinatorPartialState: Sendable {
  case success(RemoteSessionCoordinator)
  case failure(Error)
}

public enum RemotePublisherPartialState: Sendable {
  case success(AsyncStream<PresentationState>)
  case failure(Error)
}

public enum RemoteSentResponsePartialState: Sendable {
  case sent
  case failure(Error)
}

public protocol PresentationInteractor: Sendable {
    func getSessionStatePublisher() -> RemotePublisherPartialState
    func getCoordinator() -> PresentationCoordinatorPartialState
    func onDeviceEngagement() async -> Result<OnlineAuthenticationRequestSuccessModel, Error>
    func onResponsePrepare(requestItems: [RequestDataUiModel]) async -> Result<RequestItemConvertible, Error>
    func onSendResponse() async -> RemoteSentResponsePartialState
    func updatePresentationCoordinator(with coordinator: RemoteSessionCoordinator)
    func storeDynamicIssuancePendingUrl(with url: URL)
    func stopPresentation()
    func isPIDPresentation(documentIDs: [String]) -> Bool
    func getClaimCount(documentID: String) -> Int
}

final class PresentationInteractorImpl: PresentationInteractor {

  private let sessionCoordinatorHolder: SessionCoordinatorHolder
  private let walletKitController: WalletKitController
  private let walletPoPController: WalletPoPController
  private let secureEnclaveController: SecureEnclaveController
  private let credentialsInteractor: CredentialsInteractor
  private let logger: Logging?
  var requestStartTime: Date?

  init(
    with presentationCoordinator: RemoteSessionCoordinator,
    and walletKitController: WalletKitController,
    and walletPoPController: WalletPoPController,
    and secureEnclaveController: SecureEnclaveController,
    and credentialsInteractor: CredentialsInteractor,
    also sessionCoordinatorHolder: SessionCoordinatorHolder,
    logger: Logging? = nil
  ) {
    self.walletKitController = walletKitController
    self.walletPoPController = walletPoPController
    self.secureEnclaveController = secureEnclaveController
    self.credentialsInteractor = credentialsInteractor
    self.sessionCoordinatorHolder = sessionCoordinatorHolder
    self.logger = logger
    self.sessionCoordinatorHolder.setActiveRemoteCoordinator(presentationCoordinator)
  }
    public func isPIDPresentation(documentIDs: [String]) -> Bool {
      let pidDocTypes: Set<String> = [
        DocumentTypeIdentifier.mDocPid.rawValue,
        DocumentTypeIdentifier.sdJwtPid.rawValue
      ]
      return walletKitController.fetchDocuments(with: documentIDs).contains { doc in
        pidDocTypes.contains(doc.docType)
      }
    }
  
    public func getClaimCount(documentID: String) -> Int {
      return walletKitController.fetchDocument(with: documentID)?.docClaims.count ?? 0
    }

    public func getSessionStatePublisher() -> RemotePublisherPartialState {
      do {
        return .success(try self.sessionCoordinatorHolder.getActiveRemoteCoordinator().getStream())
      } catch {
        return .failure(error)
      }
    }

    public func getCoordinator() -> PresentationCoordinatorPartialState {
      do {
        return .success(try self.sessionCoordinatorHolder.getActiveRemoteCoordinator())
      } catch {
        return .failure(error)
      }
    }

    public func updatePresentationCoordinator(with coordinator: RemoteSessionCoordinator) {
      self.sessionCoordinatorHolder.setActiveRemoteCoordinator(coordinator)
    }

    public func onDeviceEngagement() async -> Result<OnlineAuthenticationRequestSuccessModel, Error> {
      try? await sessionCoordinatorHolder.getActiveRemoteCoordinator().initialize()
      return await onRequestReceived()
    }

    public func onRequestReceived() async -> Result<OnlineAuthenticationRequestSuccessModel, Error> {
      do {
        let response = try await sessionCoordinatorHolder.getActiveRemoteCoordinator().requestReceived()
        return .success(
          .init(
            requestDataCells: response.items.toUiModels(
              with: self.walletKitController
            ),
            relyingParty: response.relyingParty,
            dataRequestInfo: response.dataRequestInfo,
            isTrusted: response.isTrusted
          )
        )
      } catch {
        return .failure(error)
      }
    }

    public func onResponsePrepare(requestItems: [RequestDataUiModel]) async -> Result<RequestItemConvertible, Error> {

      let requestConvertible = requestItems.prepareRequest()

      guard requestConvertible.requestItems.isEmpty == false else {
        return .failure(PresentationSessionError.conversionToRequestItemModel)
      }

      do {
        try self.sessionCoordinatorHolder.getActiveRemoteCoordinator().setState(presentationState: .responseToSend(requestConvertible))
      } catch {
        return .failure(error)
      }

      return .success(requestConvertible.asRequestItems())
    }

  public func onSendResponse() async -> RemoteSentResponsePartialState {
    guard
      let state = try? await sessionCoordinatorHolder.getActiveRemoteCoordinator().getState(),
      case PresentationState.responseToSend(let responseItem) = state
    else {
      return .failure(PresentationSessionError.invalidState)
    }

    return await BackgroundTask.run(name: Constants.credentialRefreshTaskName) {
      do {
        self.requestStartTime = Date()
        try await self.sessionCoordinatorHolder.getActiveRemoteCoordinator().sendResponse(response: responseItem)
        /// Refresh must run here: it reuses the PIN session established for this presentation (cleared only after this method returns) and needs it to sign the new batch on the
        /// remote HSM. The background-task assertion keeps the app alive across the post-send redirect back to the verifier,
        /// which would otherwise let the OS suspend us and cancel the in-flight refresh request
        await self.refreshLowCredentialsIfNeeded()
        return .sent
      } catch {
        return .failure(error)
      }
    }
  }

  private func refreshLowCredentialsIfNeeded() async {
    let threshold = walletKitController.batchRefreshThreshold
    let documents = walletKitController.fetchIssuedDocuments()
    let lowDocuments = documents.filter { ($0.credentialsUsageCounts?.remaining ?? .max) <= threshold }
    logger?.d("RefreshToken: post-presentation check; \(lowDocuments.count)/\(documents.count) document(s) at/below threshold \(threshold)")
    guard !lowDocuments.isEmpty else { return }
    await refreshCredentialsSilently(for: lowDocuments)
  }

  private func refreshCredentialsSilently(for documents: [any DocClaimsDecodable]) async {
    guard let privateKey = secureEnclaveController.retrievePrivateKey(with: .credentialPrivKey) else {
      logger?.e("RefreshToken: silent refresh aborted, credentialPrivKey not found in secure enclave")
      return
    }
    let credentialTypes = documents.compactMap { document -> CredentialType? in
      guard let identifier = document.configurationIdentifier else { return nil }
      return CredentialType(
        documentType: nil,
        scope: ScopeValue.pid.rawValue,
        identifier: identifier,
        docDataFormat: document.docDataFormat
      )
    }
    guard !credentialTypes.isEmpty else {
      logger?.e("RefreshToken: silent refresh aborted, none of \(documents.count) low document(s) had a configuration identifier")
      return
    }
    do {
      let docs = try await credentialsInteractor.getCredentialsWithRefreshToken(credentialTypes, privateKey: privateKey)
      logger?.d("RefreshToken: silent refresh finished, \(docs.count) document(s) refreshed")
    } catch {
      logger?.e("RefreshToken: silent refresh failed: \(error.logDescriptor)")
    }
  }

  public func storeDynamicIssuancePendingUrl(with url: URL) {
    walletKitController.storeDynamicIssuancePendingUrl(with: url)
  }

  public func stopPresentation() {
    walletKitController.stopPresentation()
    try? sessionCoordinatorHolder.getActiveRemoteCoordinator().stopPresentation()
  }
}
