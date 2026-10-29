//
//  ActivitiesInteractorTests.swift
//  feature-dashboard
//
//  Created by Pankaj Sachdeva on 02.10.26.
//

import Foundation
import Testing
import Cuckoo
import logic_core
import logic_resources

@testable import feature_dashboard

struct ActivitiesInteractorTests {

  @Test
  func fetchActivities_WhenLogHasEntries_ThenGroupsVisibleEntriesNewestFirst() async throws {
    let now = Date()
    let sut = ActivitiesInteractorImpl(
      transactionLogController: FakeTransactionLogController(entries: [
        .presentation(makePresentation(id: "today-old", time: now.addingTimeInterval(-60))),
        .presentation(makePresentation(id: "today-new", time: now)),
        .credentialDeletion(makeDeletion(id: "last-month", time: now.addingTimeInterval(-20 * 86_400)))
      ]),
      walletKitController: makeWalletKitController()
    )

    guard case .success(let sections) = await sut.fetchActivities() else {
      Issue.record("Expected the activities to load")
      return
    }

    #expect(sections.map(\.category) == [.today, .previous30Days])
    #expect(sections.first?.items.map(\.id) == ["today-new", "today-old"])
  }

  @Test
  func fetchActivities_WhenLogHasBackgroundReissuance_ThenItIsNotListed() async throws {
    let sut = ActivitiesInteractorImpl(
      transactionLogController: FakeTransactionLogController(entries: [
        .credentialReissuance(
          .init(
            transactionIdentifier: "refresh",
            time: Date(),
            transactionResult: .completed,
            details: .init(credentialNumberRequested: 10, credentialNumberIssued: 10, credentialIdentifier: ["urn:eudi:pid:de:1"])
          )
        )
      ]),
      walletKitController: makeWalletKitController()
    )

    guard case .success(let sections) = await sut.fetchActivities() else {
      Issue.record("Expected the activities to load")
      return
    }

    #expect(sections.isEmpty)
  }

  @Test
  func fetchActivities_WhenLogCannotBeRead_ThenReturnsFailure() async {
    let sut = ActivitiesInteractorImpl(transactionLogController: FakeTransactionLogController(error: TestError()), walletKitController: makeWalletKitController())

    guard case .failure = await sut.fetchActivities() else {
      Issue.record("Expected a failure")
      return
    }
  }

  @Test
  func fetchActivity_WhenEntryExists_ThenReturnsItsDetail() async {
    let sut = ActivitiesInteractorImpl(
      transactionLogController: FakeTransactionLogController(entries: [
        .presentation(makePresentation(id: "presentation-1", time: Date()))
      ]),
      walletKitController: makeWalletKitController()
    )

    guard case .success(let detail) = await sut.fetchActivity(with: "presentation-1") else {
      Issue.record("Expected the activity to load")
      return
    }

    #expect(detail.presentation?.serviceName == "Example Verifier")
  }

  @Test
  func deleteAllActivities_WhenCalled_ThenDeletesTheWholeLog() async throws {
    let controller = FakeTransactionLogController(entries: [.presentation(makePresentation(id: "p", time: Date()))])
    let sut = ActivitiesInteractorImpl(transactionLogController: controller, walletKitController: makeWalletKitController())

    try await sut.deleteAllActivities()

    #expect(await controller.deleteAllCount == 1)
  }

  @Test
  func fetchActivities_WhenAnEaaWasIssued_ThenLooksUpItsStoredCredentialForTheLogo() async throws {
    let walletKitController = makeWalletKitController()
    let sut = ActivitiesInteractorImpl(
      transactionLogController: FakeTransactionLogController(entries: [
        .credentialIssuance(
          .init(
            transactionIdentifier: "issuance:doc-1",
            time: Date(),
            transactionResult: .completed,
            details: .init(
              credentialNumberRequested: 1,
              credentialNumberIssued: 1,
              credentialIdentifier: ["eu.europa.ec.eudi.por.1"],
              interactingPartyName: MultiLangString(lang: "en", content: "Stadt Köln")
            )
          )
        )
      ]),
      walletKitController: walletKitController
    )

    guard case .success(let sections) = await sut.fetchActivities() else {
      Issue.record("Expected the activities to load")
      return
    }

    verify(walletKitController).fetchDocument(with: equal(to: "doc-1"))
    // No stored credential has a logo here, so the issuer's initials are shown
    #expect(sections.first?.items.first?.leading == .initials("ST"))
  }

  private func makeWalletKitController() -> MockWalletKitController {
    let mock = MockWalletKitController()
    stub(mock) { stub in
      when(stub.fetchDocument(with: any())).thenReturn(nil)
      when(stub.fetchIssuedDocuments()).thenReturn([])
    }
    return mock
  }

  private func makePresentation(id: String, time: Date) -> TransactionEntry.Presentation {
    .init(
      transactionIdentifier: id,
      time: time,
      transactionResult: .completed,
      listOfClaimsRequested: [],
      listOfClaimsPresented: [],
      interactingPartyName: MultiLangString(lang: "en", content: "Example Verifier")
    )
  }

  @Test
  func deleteActivity_WhenTheRowMergesBothPidFormats_ThenDeletesBothEntries() async throws {
    let mdoc = makePidIssuance(id: "issuance:mdoc", time: Date(timeIntervalSince1970: 1_790_000_000), type: "eu.europa.ec.eudi.pid.1")
    let sdJwt = makePidIssuance(id: "issuance:sdjwt", time: Date(timeIntervalSince1970: 1_790_000_005), type: "urn:eudi:pid:de:1")
    let controller = FakeTransactionLogController(entries: [mdoc, sdJwt])
    let sut = ActivitiesInteractorImpl(transactionLogController: controller, walletKitController: makeWalletKitController())

    try await sut.deleteActivity(with: "issuance:mdoc")

    #expect(await controller.deletedIdentifiers == ["issuance:mdoc", "issuance:sdjwt"])
  }

  @Test
  func deleteActivity_WhenTheRowIsASingleEntry_ThenDeletesOnlyIt() async throws {
    let controller = FakeTransactionLogController(entries: [
      .presentation(makePresentation(id: "p1", time: Date())),
      .presentation(makePresentation(id: "p2", time: Date()))
    ])
    let sut = ActivitiesInteractorImpl(transactionLogController: controller, walletKitController: makeWalletKitController())

    try await sut.deleteActivity(with: "p1")

    #expect(await controller.deletedIdentifiers == ["p1"])
  }

  @Test
  func fetchActivity_WhenTheIssuedCredentialWasDeleted_ThenUsesTheIssuanceSnapshot() async throws {
    let entry = TransactionEntry.credentialIssuance(
      .init(
        transactionIdentifier: "issuance:doc-1",
        time: Date(),
        transactionResult: .completed,
        details: .init(credentialNumberRequested: 1, credentialNumberIssued: 1, credentialIdentifier: ["urn:eudi:eaa:loyalty-card:1"])
      )
    )
    let snapshot = IssuanceSnapshot(
      transactionIdentifier: "issuance:doc-1",
      time: Date(),
      credentialIdentifier: "urn:eudi:eaa:loyalty-card:1",
      display: [DisplayMetadata(name: "FitLife Membership", localeIdentifier: "en-US")],
      issuerDisplay: [DisplayMetadata(name: "Playground", localeIdentifier: "en-US")],
      claims: [IssuanceSnapshot.Claim(path: ["member_id"], displayName: "Member ID")],
      registration: .init(privacyPolicy: "https://issuer.example/privacy", supportURI: nil, infoURI: "https://issuer.example/info")
    )
    let sut = ActivitiesInteractorImpl(
      transactionLogController: FakeTransactionLogController(entries: [entry], snapshots: [snapshot]),
      walletKitController: makeWalletKitController()
    )

    guard case .success(let detail) = await sut.fetchActivity(with: "issuance:doc-1") else {
      Issue.record("Expected the activity to load")
      return
    }
    let issuance = try #require(detail.issuance)

    #expect(issuance.title == LocalizableStringKey.activitiesLogCredentialCreated(["FitLife Membership"]).toString)
    #expect(issuance.card.issuer == "Playground")
    #expect(issuance.card.claimNames == ["Member ID"])
    #expect(issuance.issuerLinks == [
      .init(kind: .dataPolicy, value: "https://issuer.example/privacy"),
      .init(kind: .website, value: "https://issuer.example/info")
    ])
  }

  @Test
  func fetchActivity_WhenADeclinedRequestAskedForADeletedCredential_ThenUsesItsSnapshotDisplay() async throws {
    let presentation = TransactionEntry.presentation(
      .init(
        transactionIdentifier: "p",
        time: Date(),
        transactionResult: .notCompleted,
        reasonOfNoncompletion: "access_denied",
        listOfClaimsRequested: [
          ClaimInfo(credentialIdentifier: "urn:eudi:eaa:loyalty-card:1", claims: [ClaimPath([.claim(name: "member_id")])])
        ],
        listOfClaimsPresented: []
      )
    )
    let display = [DisplayMetadata(name: "FitLife Membership", localeIdentifier: "en-US")]
    let snapshot = IssuanceSnapshot(
      transactionIdentifier: "issuance:doc-1",
      time: Date(),
      credentialIdentifier: "urn:eudi:eaa:loyalty-card:1",
      display: display,
      issuerDisplay: nil,
      claims: [IssuanceSnapshot.Claim(path: ["member_id"], displayName: "Member ID")],
      registration: nil
    )
    let sut = ActivitiesInteractorImpl(
      transactionLogController: FakeTransactionLogController(entries: [presentation], snapshots: [snapshot]),
      walletKitController: makeWalletKitController()
    )

    guard case .success(let detail) = await sut.fetchActivity(with: "p") else {
      Issue.record("Expected the activity to load")
      return
    }
    let credential = try #require(detail.presentation?.credentials.first)

    #expect(credential.name == "FitLife Membership")
    #expect(credential.display == display)
    #expect(credential.sharedClaims == ["Member ID"])
    #expect(!credential.isShared)
  }

  private func makePidIssuance(id: String, time: Date, type: String) -> TransactionEntry {
    .credentialIssuance(
      .init(
        transactionIdentifier: id,
        time: time,
        transactionResult: .completed,
        details: .init(credentialNumberRequested: 1, credentialNumberIssued: 1, credentialIdentifier: [type])
      )
    )
  }

  private func makeDeletion(id: String, time: Date) -> TransactionEntry.CredentialDeletion {
    .init(transactionIdentifier: id, time: time, transactionResult: .completed, credentialIdentifier: "urn:eudi:pid:de:1")
  }
}

private struct TestError: Error {}

private actor FakeTransactionLogController: TransactionLogController {

  let entries: [TransactionEntry]
  let snapshots: [IssuanceSnapshot]
  let error: Error?
  private(set) var deleteAllCount = 0
  private(set) var deletedIdentifiers: [String] = []

  init(entries: [TransactionEntry] = [], snapshots: [IssuanceSnapshot] = [], error: Error? = nil) {
    self.entries = entries
    self.snapshots = snapshots
    self.error = error
  }

  func saveIssuanceSnapshot(_ snapshot: IssuanceSnapshot) async throws {}

  func fetchIssuanceSnapshots() async throws -> [IssuanceSnapshot] {
    if let error { throw error }
    return snapshots
  }

  func deleteTransactionLogs(with identifiers: [String]) async throws {
    deletedIdentifiers.append(contentsOf: identifiers)
  }

  func deleteAllTransactionLogs() async throws {
    deleteAllCount += 1
  }

  func fetchTransactionLogs() async throws -> [TransactionEntry] {
    if let error { throw error }
    return entries
  }

  func fetchTransactionLog(with identifier: String) async throws -> TransactionEntry {
    if let error { throw error }
    guard let entry = entries.first(where: { $0.transactionIdentifier == identifier }) else { throw TestError() }
    return entry
  }
}
