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
import Combine
import logic_resources
import logic_business
import SwiftUI
import CryptoKit
import logic_api
import logic_feature_flags
import EudiWalletKit

private enum KeyIdentifier: String, KeyChainWrapper {
  public var value: String {
    self.rawValue
  }
  case dynamicIssuancePendingUrl
}

public protocol WalletKitController: Sendable {
  
  var wallet: EudiWallet { get }

  /// Minimum number of remaining credentials at or below which a silent refresh should be triggered.
  var batchRefreshThreshold: Int { get }

  func startProximityPresentation() async -> ProximitySessionCoordinator
  func startSameDevicePresentation(deepLink: URLComponents) async -> RemoteSessionCoordinator
  func startCrossDevicePresentation(urlString: String) async -> RemoteSessionCoordinator
  func stopPresentation()
  
  func fetchAllDocuments() -> [DocClaimsDecodable]
  func fetchDeferredDocuments() -> [WalletStorage.Document]
  func fetchIssuedDocuments() -> [DocClaimsDecodable]
  func fetchIssuedDocuments(with types: [DocumentTypeIdentifier]) -> [DocClaimsDecodable]
  func fetchIssuedDocuments(excluded: [DocumentTypeIdentifier]) -> [DocClaimsDecodable]
  func fetchMainPidDocument() -> DocClaimsDecodable?
  func fetchAdditionalDocuments() -> [DocClaimsDecodable]?
  func fetchDocument(with id: String) -> DocClaimsDecodable?
  func fetchDocuments(with ids: [String]) -> [DocClaimsDecodable]
  
  func clearAllDocuments() async
  func clearDocuments(status: DocumentStatus) async throws
  func deleteDocument(with id: String, status: DocumentStatus) async throws
  func loadDocuments() async throws
  
  func issueDocuments(issuerId: String, identifier: String, docTypeIdentifier: DocumentTypeIdentifier) async throws -> [WalletStorage.Document]
  func requestDeferredIssuance(with doc: WalletStorage.Document) async throws -> DocClaimsDecodable
  func resolveOfferUrlDocTypes(offerUri: String) async throws -> OfferedIssuanceModel
  func issueDocumentsByOfferUrl(
    offerUri: String,
    docTypes: [OfferedDocModel],
    txCodeValue: String?
  ) async throws -> [WalletStorage.Document]
  func parseDocClaim(
    docId: String,
    groupId: String,
    docClaim: DocClaim,
    type: DocumentElementType,
    parser: (String) -> String
  ) -> [DocumentElementClaim]
  func retrieveLogFileUrl() -> URL?
  func resumePendingIssuance(pendingDoc: WalletStorage.Document, webUrl: URL?) async throws -> WalletStorage.Document
  func storeDynamicIssuancePendingUrl(with url: URL)
  func getDynamicIssuancePendingData() async -> DynamicIssuancePendingData?
  func getScopedDocuments() async throws -> [ScopedDocument]
  func getDocumentCategories() -> DocumentCategories
  
  func issuePAR() async throws -> WalletStorage.Document?
  func issuePendingDocument(documentTypeIdentifiers: [DocumentTypeIdentifier], authorizationCode: String, nonce: String?) async throws -> WalletStorage.Document?
  func getCredentialsWithRefreshToken(credentialTypes: [CredentialType], issuerDPopConstructorParam: IssuerDPoPConstructorParam) async throws -> [WalletStorage.Document]
}

final class WalletKitControllerImpl: WalletKitController {
  let wallet: EudiWallet
  var batchRefreshThreshold: Int { configLogic.batchRefreshThreshold }
  private let sessionCoordinatorHolder: SessionCoordinatorHolder
  private let secureAreas: [any SecureArea]
  private let configLogic: WalletKitConfig
  private let keyChainController: KeyChainController
  private let featureFlagRepository: FeatureFlagRepository
  private let logger: Logging?
  private var wia: IssuerDPoPConstructorParam?

  init(
    configLogic: WalletKitConfig,
    keyChainController: KeyChainController,
    featureFlagRepository: FeatureFlagRepository,
    sessionCoordinatorHolder: SessionCoordinatorHolder,
    secureAreas: [SecureArea],
    networking: any NetworkingProtocol,
    logger: Logging? = nil
  ) {
    self.configLogic = configLogic
    self.keyChainController = keyChainController
    self.featureFlagRepository = featureFlagRepository
    self.logger = logger
    self.sessionCoordinatorHolder = sessionCoordinatorHolder
    self.secureAreas = secureAreas

    let storageService = KeyChainStorageService(serviceName: configLogic.documentStorageServiceName)

    // TODO: Switch to `.hardFail` to enforce reader-cert CRL revocation once a
    // reliable reader-cert CRL endpoint is available. Using `.warning` (optional) for now.
    let crlRevocationPolicy: RevocationPolicy = .warning
    let eudiWalletConfig = EudiWalletConfiguration(
      serviceName: configLogic.documentStorageServiceName,
      userAuthenticationRequired: configLogic.userAuthenticationRequired,
      trustedReaderRootCertificates: configLogic.readerConfig.trustedRootCertificates,
      uiCulture: Locale.current.systemLanguageCode,
      logFileName: configLogic.logFileName,
      crlRevocationPolicy: crlRevocationPolicy
    )

    guard let walletKit = try? EudiWallet(
      eudiWalletConfig: eudiWalletConfig,
      storageService: storageService,
      openID4VpConfig: configLogic.vpConfig,
      openID4VciConfigurations: configLogic.vciConfig,
      networking: networking,
      secureAreas: secureAreas
    ) else {
      fatalError("Unable to Initialize WalletKit")
    }

    wallet = walletKit
  }

  func resolveOfferUrlDocTypes(offerUri: String) async throws -> OfferedIssuanceModel {
    let authFlowRedirectionURI = configLogic.getBundleValue(key: "VCI_REDIRECT_URI")
    return try await wallet.resolveOfferUrlDocTypes(offerUri: offerUri, authFlowRedirectionURI: URL(string: authFlowRedirectionURI))
  }
  
  func issueDocumentsByOfferUrl(
    offerUri: String,
    docTypes: [OfferedDocModel],
    txCodeValue: String?
  ) async throws -> [WalletStorage.Document] {
    let docTypes = docTypes.map { docType in
      let rule = configLogic.documentIssuanceConfig.rule(for: docType.documentTypeIdentifier)
      let credentialOptions: CredentialOptions = .init(
        credentialPolicy: rule.policy,
        batchSize: rule.numberOfCredentials
      )
      let keyOptions = KeyOptions(
              curve: .P256,
              secureAreaName: getSecureAreaName(for: docType.documentTypeIdentifier),
              accessControl: .requireUserPresence
      )
      return docType.copy(credentialOptions: credentialOptions, keyOptions: keyOptions)
    }

    return try await wallet.issueDocumentsByOfferUrl(
      offerUri: offerUri,
      docTypes: docTypes,
      txCodeValue: txCodeValue
    )
  }
  
  /// This function handles the logic of returning name of the secure area on based of the doc type identifier.
  private func getSecureAreaName(for docTypeIdentifier: DocumentTypeIdentifier) -> String {
    if docTypeIdentifier == .mDocPid || docTypeIdentifier == .sdJwtPid {
      return RemoteWSCAService.name
    }
    return SoftwareSecureArea.name
  }
  
  func fetchAdditionalDocuments() -> [DocClaimsDecodable]? {
    fetchIssuedDocuments(excluded: [DocumentTypeIdentifier.mDocPid, DocumentTypeIdentifier.sdJwtPid])
  }
  
  func clearAllDocuments() async {
    try? await wallet.deleteAllDocuments()
    for status in DocumentStatus.allCases {
      try? await wallet.deleteDocuments(status: status)
    }
  }
  
  func clearDocuments(status: DocumentStatus) async throws {
    return try await wallet.deleteDocuments(status: status)
  }
  
  func deleteDocument(with id: String, status: DocumentStatus) async throws {
    return try await wallet.deleteDocument(id: id, status: status)
  }
  
  func loadDocuments() async throws {
    _ = try await wallet.loadAllDocuments()
  }
  
  func startProximityPresentation() async -> ProximitySessionCoordinator {
    self.stopPresentation()
    let session = await wallet.beginPresentation(flow: .ble)
    let proximitySessionCoordinator = DIGraph.resolver.force(
      ProximitySessionCoordinator.self,
      argument: session
    )
    self.sessionCoordinatorHolder.setActiveProximityCoordinator(proximitySessionCoordinator)
    return proximitySessionCoordinator
  }
  
  func startSameDevicePresentation(deepLink: URLComponents) async -> RemoteSessionCoordinator {
    await self.startRemotePresentation(
      urlString: decodeDeeplink(
        link: deepLink
      ) ?? ""
    )
  }
  
  func startCrossDevicePresentation(urlString: String) async -> RemoteSessionCoordinator {
    await self.startRemotePresentation(urlString: urlString)
  }
  
  func stopPresentation() {
    self.sessionCoordinatorHolder.clear()
  }
  
  func fetchAllDocuments() -> [DocClaimsDecodable] {
    return fetchIssuedDocuments() + fetchDeferredDocuments().transformToDeferredDecodables()
  }
  
  func fetchDeferredDocuments() -> [WalletStorage.Document] {
    return wallet.storage.deferredDocuments
  }
  
  func fetchIssuedDocuments() -> [DocClaimsDecodable] {
    return wallet.storage.docModels
  }
  
  func fetchIssuedDocuments(with types: [DocumentTypeIdentifier]) -> [DocClaimsDecodable] {
    return wallet.storage.docModels
      .filter({ types.map { $0.rawValue }.contains($0.docType) })
  }
  
  func fetchMainPidDocument() -> DocClaimsDecodable? {
    return fetchIssuedDocuments(with: [DocumentTypeIdentifier.mDocPid, DocumentTypeIdentifier.sdJwtPid])
      .sorted { $0.createdAt > $1.createdAt }.last
  }
  
  func fetchIssuedDocuments(excluded: [DocumentTypeIdentifier]) -> [DocClaimsDecodable] {
    let excludedRawValues = excluded.map { $0.rawValue }
    return fetchIssuedDocuments().filter { !excludedRawValues.contains($0.docType) }
  }
  
  func fetchDocument(with id: String) -> DocClaimsDecodable? {
    wallet.storage.getDocumentModel(id: id)
  }
  
  func fetchDocuments(with ids: [String]) -> [DocClaimsDecodable] {
    fetchIssuedDocuments().filter { ids.contains($0.id) }
  }
  
  func issueDocuments(issuerId: String, identifier: String, docTypeIdentifier: DocumentTypeIdentifier) async throws -> [WalletStorage.Document] {
    let rule = configLogic.documentIssuanceConfig.rule(for: docTypeIdentifier)
    return try await wallet.issueDocuments(
      issuerName: issuerId,
      docTypeIdentifiers: [.identifier(identifier)],
      credentialOptions: .init(
        credentialPolicy: rule.policy,
        batchSize: rule.numberOfCredentials
      )
    )
  }
  
  func requestDeferredIssuance(with doc: WalletStorage.Document) async throws -> DocClaimsDecodable {
    guard
      let metadata = DocMetadata(from: doc.metadata)
    else {
      throw WalletCoreError.missingMetadata
    }
    let rule = configLogic.documentIssuanceConfig.rule(for: doc.documentTypeIdentifier)
    let result = try await wallet.requestDeferredIssuance(
      issuerName: metadata.credentialIssuerIdentifier,
      deferredDoc: doc,
      credentialOptions: .init(
        credentialPolicy: rule.policy,
        batchSize: rule.numberOfCredentials
      )
    )
    if result.isDeferred {
      return result.transformToDeferredDecodable()
    } else if let doc = fetchDocument(with: result.id) {
      return doc
    } else {
      throw WalletCoreError.unableFetchDocument
    }
  }
  
  func retrieveLogFileUrl() -> URL? {
    guard
      let logFileName = configLogic.logFileName,
      let url = try? EudiWallet.getLogFileURL(logFileName)
    else {
      return nil
    }
    return url
  }
  
  func resumePendingIssuance(pendingDoc: WalletStorage.Document, webUrl: URL?) async throws -> WalletStorage.Document {
    guard
      let metadata = DocMetadata(from: pendingDoc.metadata)
    else {
      throw WalletCoreError.missingMetadata
    }
    let rule = configLogic.documentIssuanceConfig.rule(for: pendingDoc.documentTypeIdentifier)
    return try await wallet.resumePendingIssuance(
      issuerName: metadata.credentialIssuerIdentifier,
      pendingDoc: pendingDoc,
      webUrl: webUrl,
      credentialOptions: .init(
        credentialPolicy: rule.policy,
        batchSize: rule.numberOfCredentials
      )
    )
  }
  
  func storeDynamicIssuancePendingUrl(with url: URL) {
    keyChainController.storeValue(
      key: KeyIdentifier.dynamicIssuancePendingUrl,
      value: url.absoluteString
    )
  }
  
  func getDynamicIssuancePendingData() async -> DynamicIssuancePendingData? {
    
    guard
      let urlString = keyChainController.getValue(key: KeyIdentifier.dynamicIssuancePendingUrl),
      let url = urlString.toCompatibleUrl()
    else {
      return nil
    }
    
    keyChainController.removeObject(
      key: KeyIdentifier.dynamicIssuancePendingUrl
    )
    
    guard let pendingDoc = wallet.storage.pendingDocuments.last else {
      return nil
    }
    
    return .init(pendingDoc: pendingDoc, url: url)
  }
  
  func getScopedDocuments() async throws -> [ScopedDocument] {
    guard let vciConfig = configLogic.vciConfig else {
      throw NSError(domain: "unable to get vciConfig", code: 1, userInfo: nil)
    }
    return try await withThrowingTaskGroup(of: [ScopedDocument].self) { group in
      for issuerName in vciConfig.keys {
        group.addTask {
          let metadata = try await self.wallet.getIssuerMetadata(issuerName: issuerName)
          return metadata.credentialsSupported.compactMap { credential in
            switch credential.value {
            case .msoMdoc(let config):
              let id = DocumentTypeIdentifier(rawValue: config.docType)
              return ScopedDocument(
                name: config.credentialMetadata?.display.getName(fallback: credential.key.value) ?? credential.key.value,
                issuer: metadata.credentialIssuerIdentifier.url.host.ifNilOrEmpty { issuerName },
                configId: credential.key.value,
                isPid: id == .mDocPid,
                docTypeIdentifier: id
              )

            case .sdJwtVc(let config):
              guard let vct = config.vct else { return nil }
              let id = DocumentTypeIdentifier(rawValue: vct)
              return ScopedDocument(
                name: config.credentialMetadata?.display.getName(fallback: credential.key.value) ?? credential.key.value,
                issuer: metadata.credentialIssuerIdentifier.url.host.ifNilOrEmpty { issuerName },
                configId: credential.key.value,
                isPid: id == .sdJwtPid,
                docTypeIdentifier: id
              )

            default:
              return nil
            }
          }
        }
      }

      var documents: [ScopedDocument] = []
      for try await docs in group {
        documents.append(contentsOf: docs)
      }
      return documents
    }
  }
  
  func getDocumentCategories() -> DocumentCategories {
    let sorted = configLogic.documentsCategories.sorted { $0.key.order < $1.key.order }
    return DocumentCategories(uniqueKeysWithValues: sorted)
  }
}

private extension WalletKitControllerImpl {
  
  func decodeDeeplink(link: URLComponents) -> String? {
    // Handling requests of the form
    //    mdoc-openid4vp://https://eudi.netcompany-intrasoft.com?client_id=Verifier&request_uri=https://eudi.netcompany-intrasoft.com/wallet/request.jwt/OWB1_xVU7ndoHmirBn7S2JpcC5fFPzAXGCY1fTLxDjczVATjzQvre_w4yEcMB4FO5KwuyYXXw-JottarKgEvRQ
    // so we need to drop scheme and forward slashes and keep the rest of the url in order to
    // pass to wallet
    
    return link.removeSchemeFromComponents()?.string
  }
  
  func startRemotePresentation(urlString: String) async -> RemoteSessionCoordinator {
    self.stopPresentation()
    
    let data = urlString.data(using: .utf8) ?? Data()
    
    let session = await wallet.beginPresentation(flow: .openid4vp(qrCode: data))
    let remoteSessionCoordinator = DIGraph.resolver.force(
      RemoteSessionCoordinator.self,
      argument: session
    )
    self.sessionCoordinatorHolder.setActiveRemoteCoordinator(remoteSessionCoordinator)
    return remoteSessionCoordinator
  }
}

extension WalletKitController {
  
  private func parseChildren(
    docId: String,
    groupId: String,
    docClaims: [DocClaim],
    type: DocumentElementType,
    parser: (String) -> String,
    claims: inout [DocumentElementClaim]
  ) {
    docClaims.forEach { claim in
      let docElementClaim = parseDocClaim(
        docId: docId,
        groupId: groupId,
        docClaim: claim,
        type: type,
        parser: parser
      )
      claims.append(contentsOf: docElementClaim)
    }
  }
  
  public func parseDocClaim(
    docId: String,
    groupId: String,
    docClaim: DocClaim,
    type: DocumentElementType,
    parser: (String) -> String
  ) -> [DocumentElementClaim] {
    
    if let children = docClaim.children, !children.isEmpty {
      
      let title = docClaim.displayName.ifNilOrEmpty { docClaim.name }
      var childClaims: [DocumentElementClaim] = []
      
      parseChildren(
        docId: docId,
        groupId: groupId,
        docClaims: children,
        type: type,
        parser: parser,
        claims: &childClaims
      )
      
      return if title.isEmpty {
        childClaims.sortByName()
      } else {
        [
          .group(
            id: UUID().uuidString,
            title: docClaim.displayName.ifNilOrEmpty { docClaim.name },
            items: childClaims.sortByName()
          )
        ]
      }
    }
    
    var value: DocumentElementValue {
      if let image = docClaim.dataValue.image {
        return .image(Image(uiImage: image))
      } else {
        
        let claim = docClaim
          .parseDate(parser: parser)
          .parseUserPseudonym()
        
        return .string(claim.stringValue)
      }
    }
    
    var groupIdentifier: String {
      return switch type {
      case .mdoc:
        groupId
      case .sdjwt:
        if docClaim.path.last?.isEmpty == true {
          groupId
        } else {
          UUID().uuidString
        }
      }
    }
    
    return [
      .primitive(
        id: groupIdentifier,
        title: docClaim.displayName.ifNilOrEmpty { docClaim.name },
        documentId: docId,
        nameSpace: docClaim.namespace,
        path: docClaim.path,
        type: type,
        value: value,
        status: .available(isRequired: false)
      )
    ]
  }
}

extension WalletKitControllerImpl {

  private func resolvePidMsoMdocConfigId() async -> String {
    await featureFlagRepository.getNonBlankStringValue(.pidMsoMdocConfigId(fallback: configLogic.pidMsoMdocConfigId))
  }

  private func resolvePidSdJwtConfigId() async -> String {
    await featureFlagRepository.getNonBlankStringValue(.pidSdJwtConfigId(fallback: configLogic.pidSdJwtConfigId))
  }

  public func issuePAR() async throws -> WalletStorage.Document? {
    let rule = configLogic.documentIssuanceConfig.rule(for: .mDocPid)
    let credentialOptions = CredentialOptions(credentialPolicy: rule.policy, batchSize: rule.numberOfCredentials)
    let mdocConfigId = await resolvePidMsoMdocConfigId()
    return try await wallet.issuePAR(issuerName: configLogic.pidIssuerName, docTypeIdentifier: DocTypeIdentifier.identifier(mdocConfigId), credentialOptions: credentialOptions)
  }

  public func issuePendingDocument(documentTypeIdentifiers: [DocumentTypeIdentifier], authorizationCode: String, nonce: String?) async throws -> WalletStorage.Document? {
    let rule = configLogic.documentIssuanceConfig.rule(for: documentTypeIdentifiers.first)
    let keyOptions = KeyOptions(
      curve: .P256, secureAreaName: RemoteWSCAService.name, accessControl: .requireUserPresence
    )
    let credentialOptions = CredentialOptions(credentialPolicy: rule.policy, batchSize: rule.numberOfCredentials)
    let identifiers = [DocTypeIdentifier.identifier(await resolvePidMsoMdocConfigId()), DocTypeIdentifier.identifier(await resolvePidSdJwtConfigId())]
    if let pendingDoc = wallet.storage.pendingDocuments.last {
      let issuedDoc = try await wallet.resumePendingIssuanceDocuments(
        issuerName: configLogic.pidIssuerName,
        pendingDoc: pendingDoc,
        authorizationCode: authorizationCode,
        nonce: nonce,
        docTypeIdentifiers: identifiers,
        credentialOptions: credentialOptions,
        keyOptions: keyOptions
      )
      return issuedDoc.first
    }
    throw WalletCoreError.unableToIssueAndStore
  }

  public func getCredentialsWithRefreshToken(credentialTypes: [CredentialType], issuerDPopConstructorParam: IssuerDPoPConstructorParam) async throws -> [WalletStorage.Document] {
    let requestedIds = credentialTypes.map { $0.identifier }
    logger?.d("RefreshToken: start; requested types=\(requestedIds)")
    let issued = fetchIssuedDocuments()
    // Map each requested credential type to its stored document (skip any that aren't installed).
    let matched = credentialTypes.compactMap { type in
      issued.first(where: { $0.configurationIdentifier == type.identifier }).map { (type: type, document: $0) }
    }
    logger?.d("RefreshToken: matched \(matched.count)/\(credentialTypes.count) requested type(s) to \(issued.count) issued document(s)")
    // The batch shares one authorization, so the refresh token / DPoP key come from any of its documents.
    guard let anchor = matched.first else {
      logger?.e("RefreshToken: aborting, no issued document matches requested types \(requestedIds); returning empty")
      return []
    }
    logger?.d("RefreshToken: anchor docId=\(anchor.document.id) docType=\(anchor.document.docType)")
    do {
      guard let authorizedRequestParams = try await wallet.storedAuthorizedRequestParams(docId: anchor.document.id) else {
        logger?.e("RefreshToken: aborting, no stored authorized request params (refresh token) for docId=\(anchor.document.id); returning empty")
        return []
      }
      let rule = configLogic.documentIssuanceConfig.rule(for: DocumentTypeIdentifier(rawValue: anchor.document.docType))
      let credentialOptions = CredentialOptions(credentialPolicy: rule.policy, batchSize: rule.numberOfCredentials)
      let keyOptions = KeyOptions(
        curve: .P256, secureAreaName: RemoteWSCAService.name, accessControl: .requireUserPresence
      )
      logger?.d("RefreshToken: requesting new credentials from issuer=\(configLogic.pidIssuerName) for \(matched.count) doc(s), batchSize=\(rule.numberOfCredentials)")
      let (newDocuments, _) = try await wallet.getCredentialsWithRefreshToken(
        issuerName: configLogic.pidIssuerName,
        docTypeIdentifiers: matched.map { DocTypeIdentifier.identifier($0.type.identifier) },
        authorizedRequestParams: authorizedRequestParams,
        issuerDPopConstructorParam: issuerDPopConstructorParam,
        docIds: matched.map { $0.document.id },
        credentialOptions: credentialOptions,
        keyOptions: keyOptions,
        forceRefreshToken: true
      )
      logger?.d("RefreshToken: success, received \(newDocuments.count) new document(s), each holding a batch of \(rule.numberOfCredentials) credential(s)")
      return newDocuments
    } catch {
      logger?.e("RefreshToken: failed for docId=\(anchor.document.id): \(error.logDescriptor)")
      throw error
    }
  }
}
public struct CredentialType {
  let documentType: String?
  let scope: String
  let identifier: String
  let docDataFormat: DocDataFormat
  
  public init(documentType: String?, scope: String, identifier: String, docDataFormat: DocDataFormat) {
    self.documentType = documentType
    self.scope = scope
    self.identifier = identifier
    self.docDataFormat = docDataFormat
  }
}
