//
//  PresentationInteractorTests.swift
//  PresentationInteractorTests
//
//  Created by Tamas Dancsi  on 05.05.26.
//

import XCTest
import Cuckoo
import feature_common
import feature_issuance
import logic_core
import logic_ui
import JOSESwift
import Security
import MdocDataModel18013
@testable import feature_presentation
@testable import feature_test

final class PresentationInteractorTests: XCTestCase {

  private var walletKitController: MockWalletKitController!
  private var walletPoPController: MockWalletPoPController!
  private var secureEnclaveController: MockSecureEnclaveController!
  private var sessionCoordinatorHolder: MockSessionCoordinatorHolder!
  private var coordinator: MockRemoteSessionCoordinator!
  private var sut: PresentationInteractorImpl!

  override func setUp() {
    super.setUp()

    walletKitController = MockWalletKitController()
    walletPoPController = MockWalletPoPController()
    secureEnclaveController = MockSecureEnclaveController()
    sessionCoordinatorHolder = MockSessionCoordinatorHolder()
    coordinator = MockRemoteSessionCoordinator(session: Constants.mockPresentationSession)

    stub(sessionCoordinatorHolder) { mock in
      when(mock.setActiveRemoteCoordinator(any())).thenDoNothing()
      when(mock.getActiveRemoteCoordinator()).thenReturn(coordinator)
    }

    sut = PresentationInteractorImpl(
      with: coordinator,
      and: walletKitController,
      and: walletPoPController,
      and: secureEnclaveController,
      and: CredentialsInteractorImpl(
        walletKitController: walletKitController,
        walletPoPController: walletPoPController,
        secureEnclaveController: secureEnclaveController
      ),
      also: sessionCoordinatorHolder
    )
  }

  override func tearDown() {
    sut = nil
    coordinator = nil
    sessionCoordinatorHolder = nil
    secureEnclaveController = nil
    walletPoPController = nil
    walletKitController = nil

    super.tearDown()
  }

  func testOnResponsePrepare_WhenRequestItemsAreEmpty_ThenReturnsConversionFailure() async {
    let result = await sut.onResponsePrepare(requestItems: [])

    guard case .failure(let error as PresentationSessionError) = result else {
      XCTFail("Expected PresentationSessionError.conversionToRequestItemModel")
      return
    }
    guard case .conversionToRequestItemModel = error else {
      XCTFail("Expected PresentationSessionError.conversionToRequestItemModel")
      return
    }
  }

  func testOnResponsePrepare_WhenRequestItemsAreValid_ThenSetsResponseToSendState() async {
    let requestItem = makeSelectedRequestDataUIModel()
    stub(coordinator) { mock in
      when(mock.setState(presentationState: any())).thenDoNothing()
    }

    let result = await sut.onResponsePrepare(requestItems: [requestItem])

    guard case .success(let response) = result else {
      XCTFail("Expected response prepare success")
      return
    }
    XCTAssertFalse(response.asRequestItems().isEmpty)
    verify(coordinator).setState(presentationState: any())
  }

  func testOnSendResponse_WhenStateIsNotResponseToSend_ThenReturnsInvalidStateFailure() async {
    stub(coordinator) { mock in
      when(mock.getState()).thenReturn(.loading)
    }

    let result = await sut.onSendResponse()

    guard case .failure(let error as PresentationSessionError) = result else {
      XCTFail("Expected PresentationSessionError.invalidState")
      return
    }
    guard case .invalidState = error else {
      XCTFail("Expected PresentationSessionError.invalidState")
      return
    }
  }

  func testOnSendResponse_WhenCoordinatorSucceeds_ThenReturnsSent() async {
    let response = RequestItemsWrapper()
    stub(coordinator) { mock in
      when(mock.getState()).thenReturn(.responseToSend(response))
      when(mock.sendResponse(response: any())).thenDoNothing()
    }
    stub(walletKitController) { mock in
      when(mock.fetchIssuedDocuments()).thenReturn([])
      when(mock.batchRefreshThreshold.get).thenReturn(2)
    }

    let result = await sut.onSendResponse()

    guard case .sent = result else {
      XCTFail("Expected RemoteSentResponsePartialState.sent")
      return
    }
    verify(coordinator).sendResponse(response: any())
    verify(walletKitController).fetchIssuedDocuments()
  }

  func testOnSendResponse_WhenRemainingAtOrBelowThreshold_ThenTriggersRefresh() async throws {
    let response = RequestItemsWrapper()
    let privateKey = Self.makePrivateKey()
    let jwk = try Self.makeJWK(from: privateKey)
    stub(coordinator) { mock in
      when(mock.getState()).thenReturn(.responseToSend(response))
      when(mock.sendResponse(response: any())).thenDoNothing()
    }
    stub(walletKitController) { mock in
      when(mock.fetchIssuedDocuments()).thenReturn([makeLowCredentialDocument(remaining: 2)])
      when(mock.batchRefreshThreshold.get).thenReturn(2)
      when(mock.getCredentialsWithRefreshToken(credentialTypes: any(), issuerDPopConstructorParam: any())).thenReturn([])
    }
    stub(secureEnclaveController) { mock in
      when(mock.retrievePrivateKey(with: any())).thenReturn(privateKey)
    }
    stub(walletPoPController) { mock in
      when(mock.getPublicKeyJWK(algo: any(), privateKey: any(), kid: any())).thenReturn(jwk)
    }

    let result = await sut.onSendResponse()

    guard case .sent = result else {
      XCTFail("Expected RemoteSentResponsePartialState.sent")
      return
    }
    verify(walletKitController).getCredentialsWithRefreshToken(credentialTypes: any(), issuerDPopConstructorParam: any())
  }

  func testOnSendResponse_WhenRemainingAboveThreshold_ThenDoesNotRefresh() async {
    let response = RequestItemsWrapper()
    stub(coordinator) { mock in
      when(mock.getState()).thenReturn(.responseToSend(response))
      when(mock.sendResponse(response: any())).thenDoNothing()
    }
    stub(walletKitController) { mock in
      when(mock.fetchIssuedDocuments()).thenReturn([makeLowCredentialDocument(remaining: 9)])
      when(mock.batchRefreshThreshold.get).thenReturn(2)
    }

    let result = await sut.onSendResponse()

    guard case .sent = result else {
      XCTFail("Expected RemoteSentResponsePartialState.sent")
      return
    }
    verify(walletKitController, never()).getCredentialsWithRefreshToken(credentialTypes: any(), issuerDPopConstructorParam: any())
  }

  func testOnSendResponse_WhenMultipleCredentialsBelowThreshold_ThenRefreshesAllInOneCall() async throws {
    let response = RequestItemsWrapper()
    let privateKey = Self.makePrivateKey()
    let jwk = try Self.makeJWK(from: privateKey)
    stub(coordinator) { mock in
      when(mock.getState()).thenReturn(.responseToSend(response))
      when(mock.sendResponse(response: any())).thenDoNothing()
    }
    stub(walletKitController) { mock in
      when(mock.fetchIssuedDocuments()).thenReturn([
        makeLowCredentialDocument(remaining: 1, identifier: "pid-mso-mdoc"),
        makeLowCredentialDocument(remaining: 2, identifier: "mdl-mso-mdoc"),
        // Above threshold — must be excluded from the refresh batch.
        makeLowCredentialDocument(remaining: 9, identifier: "ehic-sd-jwt")
      ])
      when(mock.batchRefreshThreshold.get).thenReturn(2)
      when(mock.getCredentialsWithRefreshToken(credentialTypes: any(), issuerDPopConstructorParam: any())).thenReturn([])
    }
    stub(secureEnclaveController) { mock in
      when(mock.retrievePrivateKey(with: any())).thenReturn(privateKey)
    }
    stub(walletPoPController) { mock in
      when(mock.getPublicKeyJWK(algo: any(), privateKey: any(), kid: any())).thenReturn(jwk)
    }

    let result = await sut.onSendResponse()

    guard case .sent = result else {
      XCTFail("Expected RemoteSentResponsePartialState.sent")
      return
    }
    // Both low credentials must be refreshed together in a SINGLE batched call (no early break),
    // and the above-threshold credential must be excluded.
    let captor = ArgumentCaptor<[CredentialType]>()
    verify(walletKitController).getCredentialsWithRefreshToken(credentialTypes: captor.capture(), issuerDPopConstructorParam: any())
    XCTAssertEqual(captor.value?.count, 2)
  }

  func testStoreDynamicIssuancePendingURL_WhenCalled_ThenDelegatesToWalletKitController() throws {
    let url = try XCTUnwrap(URL(string: "https://issuer.example/pending"))
    stub(walletKitController) { mock in
      when(mock.storeDynamicIssuancePendingUrl(with: any())).thenDoNothing()
    }

    sut.storeDynamicIssuancePendingUrl(with: url)

    verify(walletKitController).storeDynamicIssuancePendingUrl(with: any())
  }

  func testIsPIDPresentation_WhenFetchedDocumentsContainPID_ThenReturnsTrue() {
    stub(walletKitController) { mock in
      when(mock.fetchDocuments(with: any())).thenReturn([Constants.euPidModel])
    }

    XCTAssertTrue(sut.isPIDPresentation(documentIDs: [Constants.euPidModelId]))
    verify(walletKitController).fetchDocuments(with: equal(to: [Constants.euPidModelId]))
  }

  func testGetClaimCount_WhenDocumentExists_ThenReturnsClaimCount() {
    stub(walletKitController) { mock in
      when(mock.fetchDocument(with: equal(to: Constants.euPidModelId))).thenReturn(Constants.euPidModel)
    }

    XCTAssertEqual(
      sut.getClaimCount(documentID: Constants.euPidModelId),
      Constants.euPidModel.docClaims.count
    )
    verify(walletKitController).fetchDocument(with: equal(to: Constants.euPidModelId))
  }

  private func makeSelectedRequestDataUIModel() -> RequestDataUiModel {
    let documentID = "document-id"
    let namespace = "namespace"
    let claim = DocumentElementClaim.primitive(
      id: "claim-given-name",
      title: "Given Name",
      documentId: documentID,
      nameSpace: namespace,
      path: [namespace, "given_name"],
      type: .mdoc,
      value: .string("Jane"),
      status: .available(isRequired: false)
    )
    let listItem: ExpandableListItem<DocumentElementClaim> = .single(
      .init(
        collapsed: ListItemData(
          mainText: .custom("Jane"),
          overlineText: .custom("Given Name"),
          trailingContent: .checkbox(true, true, { _ in })
        ),
        domainModel: claim
      )
    )

    return RequestDataUiModel(
      section: .init(
        id: documentID,
        title: "PID",
        listItems: [listItem]
      )
    )
  }

  private func makeLowCredentialDocument(remaining: Int, identifier: String = "pid-mso-mdoc") -> DeferrredDocument {
    var document = Constants.euPidModel
    document.configurationIdentifier = identifier
    document.docDataFormat = .cbor
    document.credentialsUsageCounts = try? CredentialsUsageCounts(total: 10, remaining: remaining)
    return document
  }

  private static func makePrivateKey() -> SecKey {
    let attributes: [String: Any] = [
      kSecAttrKeyType as String: kSecAttrKeyTypeECSECPrimeRandom,
      kSecAttrKeySizeInBits as String: 256
    ]
    var error: Unmanaged<CFError>?
    guard let key = SecKeyCreateRandomKey(attributes as CFDictionary, &error) else {
      fatalError("Failed to create key: \(String(describing: error))")
    }
    return key
  }

  private static func makeJWK(from privateKey: SecKey) throws -> JWK {
    guard let publicKey = SecKeyCopyPublicKey(privateKey) else {
      throw NSError(domain: "TestHelpers", code: -1)
    }
    return try ECPublicKey(publicKey: publicKey, additionalParameters: ["alg": "ES256", "use": "sig", "kid": "test-kid"])
  }
}
