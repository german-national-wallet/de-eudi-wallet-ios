//
//  DocumentOfferInteractorTests.swift
//  DocumentOfferInteractorTests
//
//  Created by Tamas Dancsi  on 05.05.26.
//

import XCTest
import Cuckoo
import feature_common
@testable import logic_core
@testable import feature_issuance
@testable import EudiWalletKit

final class DocumentOfferInteractorTests: XCTestCase {

  private var walletController: MockWalletKitController!
  private var sut: DocumentOfferInteractorImpl!

  override func setUp() {
    super.setUp()

    walletController = MockWalletKitController()
    sut = DocumentOfferInteractorImpl(walletController: walletController)
  }

  override func tearDown() {
    sut = nil
    walletController = nil

    super.tearDown()
  }

  func testIssueDocuments_WhenWalletReturnsNoDocuments_ThenReturnsFailure() async {
    stub(walletController) { mock in
      when(mock.issueDocumentsByOfferUrl(
        offerUri: equal(to: "openid-credential-offer://credential-offer"),
        docTypes: any(),
        txCodeValue: any()
      ))
      .thenReturn([])
    }

    let result = await sut.issueDocuments(
      with: "openid-credential-offer://credential-offer",
      issuerName: "Issuer",
      docOffers: [],
      successNavigation: .push(.featureDashboardModule(.dashboard)),
      txCodeValue: nil
    )

    guard case .failure = result else {
      return XCTFail("Expected issue documents failure")
    }
    verify(walletController).issueDocumentsByOfferUrl(
      offerUri: equal(to: "openid-credential-offer://credential-offer"),
      docTypes: any(),
      txCodeValue: any()
    )
  }

  func testFetchStoredDocuments_WhenWalletReturnsNoDocuments_ThenReturnsFailure() async {
    stub(walletController) { mock in
      when(mock.fetchDocuments(with: equal(to: ["document-id"]))).thenReturn([])
    }

    let result = await sut.fetchStoredDocuments(documentIds: ["document-id"])

    guard case .failure = result else {
      return XCTFail("Expected stored document fetch failure")
    }
    verify(walletController).fetchDocuments(with: equal(to: ["document-id"]))
  }

  // MARK: - Replace-on-reissuance (same issuer + same type)

  private let issuerA = "https://issuer-a.example"
  private let issuerB = "https://issuer-b.example"
  private let typeA = "type-a"
  private let typeB = "type-b"

  /// A freshly issued document returned by `issueDocumentsByOfferUrl`. Status `.issued` with empty
  /// data keeps it non-deferred and without an `authorizePresentationUrl`, so it hits the final
  /// success branch that runs the replacement.
  private func makeWalletDoc(id: String) -> WalletStorage.Document {
    WalletStorage.Document(
      id: id,
      docType: "anyType",
      docDataFormat: .cbor,
      data: Data(),
      docKeyInfo: nil,
      createdAt: nil,
      metadata: nil,
      displayName: "New Doc",
      status: .issued
    )
  }

  /// A stored, decoded credential (`DocClaimsDecodable`) as returned by `fetchIssuedDocuments()` /
  /// `fetchDocuments(with:)`.
  private func makeClaims(id: String, docType: String, issuer: String?) -> DeferrredDocument {
    DeferrredDocument(
      statusIdentifier: nil,
      secureAreaName: nil,
      credentialsUsageCounts: nil,
      credentialPolicy: .oneTimeUse,
      id: id,
      createdAt: Date(),
      modifiedAt: nil,
      displayName: id,
      docType: docType,
      docClaims: [],
      docDataFormat: .cbor,
      ageOverXX: [:],
      display: nil,
      issuerDisplay: nil,
      credentialIssuerIdentifier: issuer,
      configurationIdentifier: nil,
      validFrom: nil,
      validUntil: nil
    )
  }

  /// Stubs the offer-issuance success path. `newlyIssued` are re-read via `fetchDocuments(with:)`;
  /// `allIssued` is what `fetchIssuedDocuments()` returns after the new docs are stored.
  private func stubIssuance(
    newlyIssued newIds: [String],
    newClaims: [DeferrredDocument],
    allIssued: [DeferrredDocument]
  ) {
    stub(walletController) { mock in
      when(mock.issueDocumentsByOfferUrl(offerUri: any(), docTypes: any(), txCodeValue: any()))
        .thenReturn(newIds.map { makeWalletDoc(id: $0) })
      when(mock.fetchDocuments(with: any())).thenReturn(newClaims)
      when(mock.fetchIssuedDocuments()).thenReturn(allIssued)
      when(mock.deleteDocument(with: any(), status: any())).thenDoNothing()
    }
  }

  private func runIssuance() async {
    _ = await sut.issueDocuments(
      with: "openid-credential-offer://credential-offer",
      issuerName: "Issuer",
      docOffers: [],
      successNavigation: .push(.featureDashboardModule(.dashboard)),
      txCodeValue: nil
    )
  }

  func testIssueDocuments_WhenSameIssuerAndType_ThenDeletesPreExisting() async {
    let newClaims = makeClaims(id: "new-id", docType: typeA, issuer: issuerA)
    let oldClaims = makeClaims(id: "old-id", docType: typeA, issuer: issuerA)
    stubIssuance(newlyIssued: ["new-id"], newClaims: [newClaims], allIssued: [oldClaims, newClaims])

    await runIssuance()

    verify(walletController).deleteDocument(with: equal(to: "old-id"), status: any())
    verify(walletController, times(0)).deleteDocument(with: equal(to: "new-id"), status: any())
  }

  func testIssueDocuments_WhenDifferentIssuer_ThenDeletesNothing() async {
    let newClaims = makeClaims(id: "new-id", docType: typeA, issuer: issuerA)
    let oldClaims = makeClaims(id: "old-id", docType: typeA, issuer: issuerB)
    stubIssuance(newlyIssued: ["new-id"], newClaims: [newClaims], allIssued: [oldClaims, newClaims])

    await runIssuance()

    verify(walletController, times(0)).deleteDocument(with: any(), status: any())
  }

  func testIssueDocuments_WhenDifferentType_ThenDeletesNothing() async {
    let newClaims = makeClaims(id: "new-id", docType: typeA, issuer: issuerA)
    let oldClaims = makeClaims(id: "old-id", docType: typeB, issuer: issuerA)
    stubIssuance(newlyIssued: ["new-id"], newClaims: [newClaims], allIssued: [oldClaims, newClaims])

    await runIssuance()

    verify(walletController, times(0)).deleteDocument(with: any(), status: any())
  }

  func testIssueDocuments_WhenNewDocHasNilIssuer_ThenDeletesNothing() async {
    let newClaims = makeClaims(id: "new-id", docType: typeA, issuer: nil)
    let oldClaims = makeClaims(id: "old-id", docType: typeA, issuer: issuerA)
    stubIssuance(newlyIssued: ["new-id"], newClaims: [newClaims], allIssued: [oldClaims, newClaims])

    await runIssuance()

    verify(walletController, times(0)).deleteDocument(with: any(), status: any())
  }

  func testIssueDocuments_WhenPidType_ThenDeletesNothing() async {
    // PID is out of scope for this replacement: it must be torn down via its own lifecycle, never
    // via a plain document delete here — even if issuer + type match.
    let pidType = DocumentTypeIdentifier.mDocPid.rawValue
    let newClaims = makeClaims(id: "new-id", docType: pidType, issuer: issuerA)
    let oldClaims = makeClaims(id: "old-id", docType: pidType, issuer: issuerA)
    stubIssuance(newlyIssued: ["new-id"], newClaims: [newClaims], allIssued: [oldClaims, newClaims])

    await runIssuance()

    verify(walletController, times(0)).deleteDocument(with: any(), status: any())
  }

  func testIssueDocuments_WhenBatchOfferTwoTypes_ThenDeletesOnlyMatching() async {
    let newA = makeClaims(id: "new-A", docType: typeA, issuer: issuerA)
    let newB = makeClaims(id: "new-B", docType: typeB, issuer: issuerA)
    let oldA = makeClaims(id: "old-A", docType: typeA, issuer: issuerA)
    let oldB = makeClaims(id: "old-B", docType: typeB, issuer: issuerA)
    let oldC = makeClaims(id: "old-C", docType: "type-c", issuer: issuerA)
    stubIssuance(
      newlyIssued: ["new-A", "new-B"],
      newClaims: [newA, newB],
      allIssued: [oldA, oldB, oldC, newA, newB]
    )

    await runIssuance()

    verify(walletController).deleteDocument(with: equal(to: "old-A"), status: any())
    verify(walletController).deleteDocument(with: equal(to: "old-B"), status: any())
    verify(walletController, times(0)).deleteDocument(with: equal(to: "old-C"), status: any())
  }
}
