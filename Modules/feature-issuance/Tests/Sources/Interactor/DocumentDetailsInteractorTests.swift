//
//  DocumentDetailsInteractorTests.swift
//  DocumentDetailsInteractorTests
//
//  Created by Tamas Dancsi  on 05.05.26.
//

import XCTest
import Cuckoo
import logic_core
import OpenID4VCI
import MdocDataModel18013
@testable import feature_issuance

final class DocumentDetailsInteractorTests: XCTestCase {

  private var walletController: MockWalletKitController!
  private var sut: DocumentDetailsInteractorImpl!

  override func setUp() {
    super.setUp()

    walletController = MockWalletKitController()
    sut = DocumentDetailsInteractorImpl(walletController: walletController)
  }

  override func tearDown() {
    sut = nil
    walletController = nil

    super.tearDown()
  }

  func testFetchStoredDocument_WhenDocumentExists_ThenReturnsDocumentDetails() async {
    stub(walletController) { mock in
      when(mock.fetchDocument(with: equal(to: "document-id"))).thenReturn(MockDocClaimsDecodable())
    }

    let result = await sut.fetchStoredDocument(documentId: "document-id")

    guard case .success(let document) = result else {
      return XCTFail("Expected successful document details result")
    }
    XCTAssertEqual(document.id, "document-id")
    XCTAssertEqual(document.documentName, "Document")
    verify(walletController).fetchDocument(with: equal(to: "document-id"))
  }

  func testFetchStoredDocument_WhenDocumentDoesNotExist_ThenReturnsFailure() async {
    stub(walletController) { mock in
      when(mock.fetchDocument(with: equal(to: "missing-document-id"))).thenReturn(nil)
    }

    let result = await sut.fetchStoredDocument(documentId: "missing-document-id")

    guard case .failure = result else {
      return XCTFail("Expected document details failure")
    }
    verify(walletController).fetchDocument(with: equal(to: "missing-document-id"))
  }

  func testDeleteDocument_WhenDeletingOnlyPID_ThenClearsAllDocumentsAndRequiresReboot() async {
    stub(walletController) { mock in
      when(mock.fetchIssuedDocuments(with: any())).thenReturn([MockDocClaimsDecodable()])
      when(mock.fetchMainPidDocument()).thenReturn(MockDocClaimsDecodable())
      when(mock.clearAllDocuments()).thenDoNothing()
    }

    let result = await sut.deleteDocument(with: "document-id", and: .mDocPid)

    guard case .success(let shouldReboot) = result else {
      return XCTFail("Expected successful PID deletion")
    }
    XCTAssertTrue(shouldReboot)
    verify(walletController).clearAllDocuments()
    verify(walletController, never()).deleteDocument(with: any(), status: any())
  }

  func testDeleteDocument_WhenDeletingAdditionalDocument_ThenDeletesDocumentWithoutReboot() async {
    stub(walletController) { mock in
      when(mock.deleteDocument(with: equal(to: "document-id"), status: any())).thenDoNothing()
    }

    let result = await sut.deleteDocument(with: "document-id", and: .other(formatType: "org.iso.18013.5.1.mDL"))

    guard case .success(let shouldReboot) = result else {
      return XCTFail("Expected successful additional document deletion")
    }
    XCTAssertFalse(shouldReboot)
    verify(walletController).deleteDocument(with: equal(to: "document-id"), status: any())
    verify(walletController, never()).clearAllDocuments()
  }
}

private struct MockDocClaimsDecodable: DocClaimsDecodable {
  var id: String = "document-id"
  var createdAt: Date = Date()
  var modifiedAt: Date? = nil
  var displayName: String? = "Document"
  var display: [DisplayMetadata]? = [DisplayMetadata(name: "Document")]
  var issuerDisplay: [DisplayMetadata]? = [DisplayMetadata(name: "Issuer")]
  var credentialIssuerIdentifier: String? = "issuer-id"
  var configurationIdentifier: String? = "configuration-id"
  var docType: String = DocumentTypeIdentifier.mDocPid.rawValue
  var docClaims: [DocClaim] = [DocClaim(name: "given_name", dataValue: .string("Tamas"), stringValue: "Tamas")]
  var docDataFormat: DocDataFormat = .sdjwt
  var validFrom: Date? = Date()
  var validUntil: Date? = Calendar.current.date(byAdding: .year, value: 1, to: Date())
  var statusIdentifier: MdocDataModel18013.StatusIdentifier?
  var secureAreaName: String?
  var credentialsUsageCounts: MdocDataModel18013.CredentialsUsageCounts?
  var credentialPolicy: MdocDataModel18013.CredentialPolicy = .oneTimeUse
  var ageOverXX: [Int: Bool] = [:]

  func getValue(for claim: String) -> String? {
    nil
  }

  func getValueAsDate(for claim: String) -> Date? {
    nil
  }

  func getValueAsImage(for claim: String) -> Data? {
    nil
  }

  func hasExpired() -> Bool {
    false
  }
}
