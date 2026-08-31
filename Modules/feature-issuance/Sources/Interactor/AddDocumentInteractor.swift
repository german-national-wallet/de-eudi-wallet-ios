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
import logic_ui
import logic_resources
import feature_common
import logic_business
import logic_core
import JOSESwift

public protocol AddDocumentInteractor: Sendable {
  func fetchScopedDocuments(with flow: IssuanceFlowUiConfig.Flow) async -> ScopedDocumentsPartialState
  func resumeDynamicIssuance() async -> IssueDynamicDocumentPartialState
  func getScopedDocument(configId: String) async throws -> ScopedDocument
  
  func getHoldersName(for documentIdentifier: String) -> String?
  func getDocumentSuccessCaption(for documentIdentifier: String) -> LocalizableStringKey?
  func fetchStoredDocuments(documentIds: [String]) async -> IssueDocumentsPartialState

  func getCredentials(docTypeIdentifier: [DocumentTypeIdentifier], _ finishAuthorization: FinishAuthorizationResponse, privateKey: SecKey) async throws -> Bool
}

final class AddDocumentInteractorImpl: AddDocumentInteractor {
  private let walletController: WalletKitController
  private let expirationTime = TimeInterval(5*60)
  private let secureEnclaveController: SecureEnclaveController
  
  init(
    walletController: WalletKitController,
    secureEnclaveController: SecureEnclaveController
  ) {
    self.walletController = walletController
    self.secureEnclaveController = secureEnclaveController
  }
  
  public func fetchScopedDocuments(with flow: IssuanceFlowUiConfig.Flow) async -> ScopedDocumentsPartialState {
      do {
        let documents: [AddDocumentUIModel] = try await walletController.getScopedDocuments().compactMap { doc in
          return .init(
            listItem: .init(mainText: .activity),
            isEnabled: true,
            configId: doc.configId,
            format: doc.docTypeIdentifier.rawValue,
            alias: doc.name
          )
        }.sorted(by: compare)
        return .success(documents)
      } catch {
        return .failure(error)
      }

      func compare(_ first: AddDocumentUIModel, _ second: AddDocumentUIModel) -> Bool {
        return first.listItem.mainText.toString.lowercased() < second.listItem.mainText.toString.lowercased()
      }
    }
  
  func resumeDynamicIssuance() async -> IssueDynamicDocumentPartialState {
    
    guard let pendingData = await walletController.getDynamicIssuancePendingData() else {
      return .noPending
    }
    
    do {
      
      let doc = try await walletController.resumePendingIssuance(
        pendingDoc: pendingData.pendingDoc,
        webUrl: pendingData.url
      )
      
      if doc.status == .deferred {
        return .deferredSuccess
      } else if doc.status == .issued {
        return .success(doc.id)
      } else {
        return .failure(WalletCoreError.unableToIssueAndStore)
      }
      
    } catch {
      return .failure(WalletCoreError.unableToIssueAndStore)
    }
  }
  
  func getScopedDocument(configId: String) async throws -> ScopedDocument {
    try await walletController.getScopedDocuments().first {
      $0.configId == configId
    } ?? ScopedDocument.empty()
  }
  
  public func getHoldersName(for documentIdentifier: String) -> String? {
    guard
      let bearerName = walletController.fetchDocument(with: documentIdentifier)?.getBearersName()
    else {
      return nil
    }
    return  "\(bearerName.first) \(bearerName.last)"
  }
  
  public func getDocumentSuccessCaption(for documentIdentifier: String) -> LocalizableStringKey? {
    guard
      let document = walletController.fetchDocument(with: documentIdentifier)
    else {
      return nil
    }
    return .issuanceSuccessCaption([document.displayName.orEmpty])
  }
  
  func fetchStoredDocuments(documentIds: [String]) async -> IssueDocumentsPartialState {
    let documents = walletController.fetchDocuments(with: documentIds)
    let documentsDetails = documents.compactMap {
      $0.transformToDocumentDetailsUi(isSensitive: false)
    }
    
    if documentsDetails.isEmpty {
      return .failure(WalletCoreError.unableFetchDocument)
    }
    return .success(documentsDetails)
  }
  
}

extension AddDocumentInteractorImpl {
  public func getCredentials(docTypeIdentifier: [DocumentTypeIdentifier], _ finishAuthorization: FinishAuthorizationResponse, privateKey: SecKey) async throws -> Bool {
    try await walletController.issuePendingDocument(documentTypeIdentifiers: docTypeIdentifier, authorizationCode: finishAuthorization.code, nonce: finishAuthorization.nonce) != nil
 }
}

public enum ScopedDocumentsPartialState: Sendable {
  case success([AddDocumentUIModel])
  case failure(Error)
}

public enum IssueResultPartialState: Sendable {
  case success(String)
  case deferredSuccess
  case dynamicIssuance(RemoteSessionCoordinator)
  case failure(Error)
}

public enum IssueDynamicDocumentPartialState: Sendable {
  case success(String)
  case noPending
  case deferredSuccess
  case failure(Error)
}

public enum IssueDocumentsPartialState: Sendable {
  case success([DocumentDetailsUIModel])
  case failure(Error)
}

public enum ScopeValue: String {
  case pid
}
