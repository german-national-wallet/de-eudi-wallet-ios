//
//  ActivityUIModelTests.swift
//  feature-dashboard
//
//  Created by Pankaj Sachdeva on 02.10.26.
//

import Foundation
import Testing
import logic_core
import logic_resources

@testable import feature_dashboard

struct ActivityUIModelTests {

  private let calendar = Calendar(identifier: .gregorian)
  private let now = Date(timeIntervalSince1970: 1_790_000_000)

  @Test(arguments: [
    (0, ActivityCategory.today),
    (1, .yesterday),
    (2, .previous7Days),
    (7, .previous7Days),
    (8, .previous30Days),
    (30, .previous30Days)
  ])
  func category_WhenEntryIsDaysOld_ThenGroupsIt(daysAgo: Int, expected: ActivityCategory) throws {
    let date = try #require(calendar.date(byAdding: .day, value: -daysAgo, to: now))

    #expect(ActivityCategory(date: date, now: now, calendar: calendar) == expected)
  }

  @Test
  func category_WhenEntryIsOlderThan30Days_ThenGroupsItByMonth() throws {
    let date = try #require(calendar.date(byAdding: .day, value: -45, to: now))
    let components = calendar.dateComponents([.year, .month], from: date)

    #expect(
      ActivityCategory(date: date, now: now, calendar: calendar)
        == .month(year: try #require(components.year), month: try #require(components.month))
    )
  }

  @Test
  func categories_WhenSorted_ThenListTheRangesAndThenTheNewestMonthFirst() {
    let unsorted: [ActivityCategory] = [
      .month(year: 2025, month: 12), .today, .month(year: 2026, month: 1), .previous30Days, .yesterday, .previous7Days
    ]

    #expect(unsorted.sorted() == [
      .today, .yesterday, .previous7Days, .previous30Days, .month(year: 2026, month: 1), .month(year: 2025, month: 12)
    ])
  }

  @Test
  func title_WhenMonth_ThenShowsTheMonthAndYear() {
    #expect(ActivityCategory.month(year: 2026, month: 9).title(calendar: calendar).toString == "September 2026")
  }

  @Test
  func toListItem_WhenPresentationHasNoPartyName_ThenUsesUnknownParty() {
    let entry = TransactionEntry.presentation(
      .init(transactionIdentifier: "p", time: now, transactionResult: .completed, listOfClaimsRequested: [], listOfClaimsPresented: [])
    )

    #expect(entry.toListItem(now: now).title == LocalizableStringKey.activitiesLogUnknownParty.toString)
  }

  @Test
  func toListItem_WhenTransactionDidNotComplete_ThenMarksIt() {
    let entry = TransactionEntry.presentation(
      .init(transactionIdentifier: "p", time: now, transactionResult: .notCompleted, listOfClaimsRequested: [], listOfClaimsPresented: [])
    )

    let item = entry.toListItem(now: now)

    #expect(!item.isCompleted)
    #expect(item.subtitle.contains(LocalizableStringKey.activitiesLogStatusNotCompleted.toString))
  }

  @Test
  func toListItem_WhenPresentationIsFromToday_ThenShowsInitialsCredentialAndTime() {
    let entry = TransactionEntry.presentation(
      .init(
        transactionIdentifier: "p",
        time: now,
        transactionResult: .completed,
        listOfClaimsRequested: [],
        listOfClaimsPresented: [ClaimInfo(credentialIdentifier: "urn:eudi:pid:de:1", claims: [])],
        interactingPartyName: MultiLangString(lang: "en", content: "DeineBank.de")
      )
    )

    let item = entry.toListItem(now: now, calendar: calendar)
    let time = ActivityDateFormatter.time(now)

    #expect(item.leading == .initials("DE"))
    #expect(item.title == "DeineBank.de")
    #expect(item.subtitle == "\(LocalizableStringKey.dashboardCardTitle.toString) · \(time)")
  }

  @Test
  func toListItem_WhenPresentationSharedSeveralCredentials_ThenSaysMultipleCredentials() {
    let entry = TransactionEntry.presentation(
      .init(
        transactionIdentifier: "p",
        time: now,
        transactionResult: .completed,
        listOfClaimsRequested: [],
        listOfClaimsPresented: [
          ClaimInfo(credentialIdentifier: "urn:eudi:pid:de:1", claims: []),
          ClaimInfo(credentialIdentifier: "eu.europa.ec.eudi.por.1", claims: [])
        ]
      )
    )

    #expect(entry.toListItem(now: now, calendar: calendar).subtitle.hasPrefix(LocalizableStringKey.activitiesLogMultipleCredentials.toString))
  }

  @Test
  func toListItem_WhenPidWasIssuedOnAnEarlierDay_ThenShowsLogoIssuerAndDate() throws {
    let issued = try #require(calendar.date(byAdding: .day, value: -3, to: now))
    let entry = TransactionEntry.credentialIssuance(
      .init(
        transactionIdentifier: "i",
        time: issued,
        transactionResult: .completed,
        details: .init(
          credentialNumberRequested: 10,
          credentialNumberIssued: 10,
          credentialIdentifier: ["eu.europa.ec.eudi.pid.1"],
          interactingPartyName: MultiLangString(lang: "en", content: "BMI")
        )
      )
    )

    let item = entry.toListItem(now: now, calendar: calendar)

    #expect(item.leading == .pidLogo)
    #expect(item.title == LocalizableStringKey.activitiesLogCredentialCreated([LocalizableStringKey.dashboardCardTitle.toString]).toString)
    #expect(item.subtitle == "BMI · \(ActivityDateFormatter.date(issued))")
  }

  @Test
  func toListItem_WhenEaaIssuerHasALogo_ThenShowsTheLogoWithInitialsAsFallback() throws {
    let logo = try #require(URL(string: "https://issuer.example/logo.png"))
    let entry = TransactionEntry.credentialIssuance(
      .init(
        transactionIdentifier: "issuance:doc-1",
        time: now,
        transactionResult: .completed,
        details: .init(
          credentialNumberRequested: 1,
          credentialNumberIssued: 1,
          credentialIdentifier: ["eu.europa.ec.eudi.por.1"],
          interactingPartyName: MultiLangString(lang: "en", content: "Stadt Köln")
        )
      )
    )

    let listLogo = ActivityListLogo(url: logo, backgroundHex: "#FE5F22")
    #expect(entry.toListItem(now: now, calendar: calendar, logo: listLogo).leading == .logo(listLogo, initials: "ST"))
    #expect(entry.issuedDocumentId == "doc-1")
  }

  @Test
  func toDetail_WhenPresentationSharedClaims_ThenListsClaimNamesPerCredential() throws {
    let entry = TransactionEntry.presentation(
      .init(
        transactionIdentifier: "p",
        time: now,
        transactionResult: .completed,
        listOfClaimsRequested: [],
        listOfClaimsPresented: [
          ClaimInfo(
            credentialIdentifier: "eu.europa.ec.eudi.pid.1",
            claims: [
              ClaimPath([.claim(name: "eu.europa.ec.eudi.pid.1"), .claim(name: "family_name")]),
              ClaimPath([.claim(name: "eu.europa.ec.eudi.pid.1"), .claim(name: "birth_date")])
            ]
          )
        ],
        interactingPartyName: MultiLangString(lang: "en", content: "Example Verifier"),
        purpose: [MultiLangString(lang: "en", content: "Age verification")],
        privacyPolicy: [Policy(type: Policy.privacyPolicy, policyURI: "https://verifier.example/privacy")]
      )
    )

    let detail = try #require(entry.toDetail(totalClaimCounts: ["eu.europa.ec.eudi.pid.1": 14]).presentation)
    let credential = try #require(detail.credentials.first)

    #expect(detail.serviceName == "Example Verifier")
    #expect(credential.name == LocalizableStringKey.dashboardCardTitle.toString)
    #expect(credential.isPid)
    #expect(credential.sharedClaims == ["family_name", "birth_date"])
    #expect(credential.totalClaimCount == 14)
    #expect(detail.services == [.init(kind: .dataPolicy, value: "https://verifier.example/privacy")])
  }

  @Test
  func toDetail_WhenPresentationHasContacts_ThenMapsSupportAndWebsite() throws {
    let entry = TransactionEntry.presentation(
      .init(
        transactionIdentifier: "p",
        time: now,
        transactionResult: .completed,
        listOfClaimsRequested: [],
        listOfClaimsPresented: [],
        interactingPartyName: MultiLangString(lang: "en", content: "Example Verifier"),
        interactingPartyContact: ["DE", "support@verifier.example", "+49 221 123456", "https://verifier.example"]
      )
    )

    let detail = try #require(entry.toDetail().presentation)

    #expect(detail.services == [
      .init(kind: .support, value: "support@verifier.example"),
      .init(kind: .website, value: "https://verifier.example")
    ])
  }

  @Test
  func toDetail_WhenPidWasDeleted_ThenShowsTheDeletionWithThePidCard() throws {
    let entry = TransactionEntry.credentialDeletion(
      .init(
        transactionIdentifier: "d",
        time: now,
        transactionResult: .completed,
        credentialIdentifier: "urn:eudi:pid:de:1"
      )
    )

    let detail = try #require(entry.toDetail().issuance)

    #expect(detail.kind == .deleted)
    #expect(detail.dateLabel == .activitiesDetailDeletedOn)
    #expect(detail.cardLabel == .activitiesDetailIdDeleted)
    #expect(detail.card.isPid)
    #expect(detail.title == LocalizableStringKey.activitiesLogCredentialDeleted([LocalizableStringKey.dashboardCardTitle.toString]).toString)
  }

  @Test
  func toDetail_WhenCredentialWasIssued_ThenShowsTheCredentialCardAndIssuerLinks() throws {
    let entry = TransactionEntry.credentialIssuance(
      .init(
        transactionIdentifier: "issuance:doc-1",
        time: now,
        transactionResult: .completed,
        details: .init(
          credentialNumberRequested: 1,
          credentialNumberIssued: 1,
          credentialIdentifier: ["urn:eudi:eaa:loyalty-card:1"],
          interactingPartyName: MultiLangString(lang: "en", content: "EUDI Wallet dev"),
          interactingPartyContact: ["DE", "https://issuer.example/support", "https://issuer.example"]
        )
      )
    )

    let detail = try #require(
      entry.toDetail(
        credentialNames: ["urn:eudi:eaa:loyalty-card:1": "FitLife Membership"],
        storedCredential: ActivityStoredCredential(
          documentId: "doc-1",
          issuerName: "Playground",
          issuerLogoURL: "https://issuer.example/logo.png",
          display: nil,
          claimNames: ["Member ID", "Membership Tier"],
          privacyPolicy: nil,
          supportURI: nil,
          infoURI: nil
        )
      ).issuance
    )

    #expect(detail.kind == .added)
    #expect(detail.cardLabel == .activitiesDetailCredentialCreated)
    #expect(detail.title == LocalizableStringKey.activitiesLogCredentialCreated(["FitLife Membership"]).toString)
    #expect(detail.card == ActivityCredentialCardUIModel(
      documentId: "doc-1",
      title: "FitLife Membership",
      issuer: "EUDI Wallet dev",
      isPid: false,
      display: nil,
      issuerLogoURL: "https://issuer.example/logo.png",
      claimNames: ["Member ID", "Membership Tier"]
    ))
    #expect(detail.issuerLinks == [.init(kind: .website, value: "https://issuer.example")])
  }

  @Test
  func toDetail_WhenTheSnapshotHasRegistrationLinks_ThenShowsTheDataPolicyAndWebsite() throws {
    let entry = TransactionEntry.credentialIssuance(
      .init(
        transactionIdentifier: "issuance:doc-1",
        time: now,
        transactionResult: .completed,
        details: .init(credentialNumberRequested: 1, credentialNumberIssued: 1, credentialIdentifier: ["urn:eudi:eaa:loyalty-card:1"])
      )
    )
    let stored = ActivityStoredCredential(
      documentId: "doc-1",
      issuerName: "Playground",
      issuerLogoURL: nil,
      display: nil,
      claimNames: [],
      privacyPolicy: "https://issuer.example/privacy",
      supportURI: nil,
      infoURI: "https://issuer.example/info"
    )

    let detail = try #require(entry.toDetail(storedCredential: stored).issuance)

    #expect(detail.issuerLinks == [
      .init(kind: .dataPolicy, value: "https://issuer.example/privacy"),
      .init(kind: .website, value: "https://issuer.example/info")
    ])
  }

  @Test
  func toDetail_WhenPresentationWasDeclined_ThenListsTheRequestedClaimsAsNotShared() throws {
    let entry = TransactionEntry.presentation(
      .init(
        transactionIdentifier: "p",
        time: now,
        transactionResult: .notCompleted,
        reasonOfNoncompletion: "access_denied",
        listOfClaimsRequested: [
          ClaimInfo(credentialIdentifier: "urn:eudi:pid:de:1", claims: [ClaimPath([.claim(name: "family_name")])])
        ],
        listOfClaimsPresented: [],
        interactingPartyName: MultiLangString(lang: "en", content: "DeineBank.de"),
        purpose: [MultiLangString(lang: "en", content: "To buy alcohol")],
        dpaContact: ["dpa@example.org", "+49 228 123456", "https://dpa.example.org/complaints"]
      )
    )

    let detail = try #require(entry.toDetail().presentation)

    #expect(detail.dateLabel == .activitiesDetailRejectedOn)
    #expect(detail.failureMessage == .activitiesDetailFailureDeclined)
    #expect(detail.purpose == "To buy alcohol")
    #expect(!detail.isShared)
    #expect(detail.credentialsLabel == .activitiesDetailNoDataShared)
    #expect(detail.credentials.map(\.sharedClaims) == [["family_name"]])
    #expect(detail.credentials.allSatisfy { !$0.isShared })
    #expect(detail.reportLink?.value == "https://dpa.example.org/complaints")
  }

  @Test
  func toDetail_WhenTheServiceRejectedASentResponse_ThenSaysSoWithoutClaimingNothingWasShared() throws {
    let entry = TransactionEntry.presentation(
      .init(
        transactionIdentifier: "p",
        time: now,
        transactionResult: .notCompleted,
        reasonOfNoncompletion: "Rejected",
        listOfClaimsRequested: [],
        listOfClaimsPresented: [
          ClaimInfo(credentialIdentifier: "urn:eudi:pid:de:1", claims: [ClaimPath([.claim(name: "family_name")])])
        ]
      )
    )

    let detail = try #require(entry.toDetail().presentation)

    #expect(detail.failureMessage == .activitiesDetailFailureServiceRejected)
    #expect(detail.isShared)
    #expect(detail.reportLink == nil)
  }

  @Test
  func toDetail_WhenTheReasonIsATechnicalError_ThenShowsTheGenericMessage() throws {
    let entry = TransactionEntry.presentation(
      .init(
        transactionIdentifier: "p",
        time: now,
        transactionResult: .notCompleted,
        reasonOfNoncompletion: "The operation couldn't be completed. (EudiWalletKit.WalletError error 1.)",
        listOfClaimsRequested: [],
        listOfClaimsPresented: []
      )
    )

    #expect(try #require(entry.toDetail().presentation).failureMessage == .activitiesDetailFailureGeneric)
  }

  @Test
  func toDetail_WhenPresentationCompleted_ThenHasNoFailureMessage() throws {
    let entry = TransactionEntry.presentation(
      .init(
        transactionIdentifier: "p",
        time: now,
        transactionResult: .completed,
        listOfClaimsRequested: [],
        listOfClaimsPresented: [ClaimInfo(credentialIdentifier: "urn:eudi:pid:de:1", claims: [])]
      )
    )

    let detail = try #require(entry.toDetail().presentation)

    #expect(detail.dateLabel == .activitiesDetailVerifiedOn)
    #expect(detail.failureMessage == nil)
    #expect(detail.credentialsLabel == .activitiesDetailCredentialAndDataShared)
  }

  @Test
  func toDetail_WhenIssuanceDidNotComplete_ThenShowsTheStatusInsteadOfACard() {
    let entry = TransactionEntry.credentialIssuance(
      .init(
        transactionIdentifier: "issuance:doc-1",
        time: now,
        transactionResult: .notCompleted,
        reasonOfNoncompletion: "invalid_grant",
        details: .init(credentialNumberRequested: 1, credentialNumberIssued: 0, credentialIdentifier: ["urn:eudi:eaa:loyalty-card:1"])
      )
    )

    let detail = entry.toDetail()

    #expect(detail.issuance == nil)
    #expect(detail.rows.contains {
      $0.title == .activitiesLogDetailStatus && $0.value == LocalizableStringKey.activitiesLogStatusNotCompleted.toString
    })
    #expect(!detail.rows.contains { $0.value == "invalid_grant" })
  }

  @Test
  func toDetail_WhenAnEAAWasDeleted_ThenLabelsTheCardAsADeletedCredential() throws {
    let entry = TransactionEntry.credentialDeletion(
      .init(transactionIdentifier: "d", time: now, transactionResult: .completed, credentialIdentifier: "urn:eudi:eaa:loyalty-card:1")
    )

    #expect(try #require(entry.toDetail().issuance).cardLabel == .activitiesDetailCredentialDeleted)
  }

  @Test
  func toDetail_WhenIssuerHasNoRegistration_ThenShowsNoIssuerLinks() throws {
    let entry = TransactionEntry.credentialIssuance(
      .init(
        transactionIdentifier: "issuance:doc-1",
        time: now,
        transactionResult: .completed,
        details: .init(credentialNumberRequested: 1, credentialNumberIssued: 1, credentialIdentifier: ["urn:eudi:eaa:loyalty-card:1"])
      )
    )

    let detail = try #require(entry.toDetail().issuance)

    #expect(detail.issuerLinks.isEmpty)
    #expect(detail.card.claimNames.isEmpty)
  }

  @Test
  func preparedForActivityLog_WhenPidIssuedInBothFormats_ThenMergesThemAndHidesThePlaceholder() {
    let issuer = MultiLangString(lang: "en", content: "Bundesdruckerei GmbH")
    let entries: [TransactionEntry] = [
      makeIssuance(id: "par", time: now, result: .notCompleted, identifiers: [], issuer: issuer),
      makeIssuance(id: "mdoc", time: now.addingTimeInterval(5), result: .completed, identifiers: ["eu.europa.ec.eudi.pid.1"], issuer: issuer),
      makeIssuance(id: "sdjwt", time: now.addingTimeInterval(6), result: .completed, identifiers: ["urn:eudi:pid:de:1"], issuer: issuer)
    ]

    let prepared = entries.preparedForActivityLog()

    #expect(prepared.count == 1)
    #expect(prepared.first?.transactionIdentifier == "issuance:mdoc")
    #expect(prepared.first?.transactionResult == .completed)
    #expect(prepared.first?.toListItem(now: now, calendar: calendar).title
      == LocalizableStringKey.activitiesLogCredentialCreated([LocalizableStringKey.dashboardCardTitle.toString]).toString)
  }

  @Test
  func preparedForActivityLog_WhenOnePidFormatFailed_ThenTheMergedEntryIsNotCompleted() {
    let entries: [TransactionEntry] = [
      makeIssuance(id: "mdoc", time: now, result: .completed, identifiers: ["eu.europa.ec.eudi.pid.1"]),
      makeIssuance(id: "sdjwt", time: now.addingTimeInterval(1), result: .notCompleted, identifiers: ["urn:eudi:pid:de:1"])
    ]

    #expect(entries.preparedForActivityLog().map(\.transactionResult) == [.notCompleted])
  }

  @Test
  func preparedForActivityLog_WhenPidIssuancesAreFarApart_ThenKeepsBoth() {
    let entries: [TransactionEntry] = [
      makeIssuance(id: "first", time: now, result: .completed, identifiers: ["eu.europa.ec.eudi.pid.1"]),
      makeIssuance(id: "second", time: now.addingTimeInterval(3600), result: .completed, identifiers: ["urn:eudi:pid:de:1"])
    ]

    #expect(entries.preparedForActivityLog().count == 2)
  }

  @Test
  func toDetail_WhenRegistrationHasSupportAndInfoLinks_ThenMapsThemInOrder() throws {
    let entry = TransactionEntry.presentation(
      .init(
        transactionIdentifier: "p",
        time: now,
        transactionResult: .completed,
        listOfClaimsRequested: [],
        listOfClaimsPresented: [],
        interactingPartyContact: ["DE", "https://verifier.example/support", "https://verifier.example"]
      )
    )

    let detail = try #require(entry.toDetail().presentation)

    #expect(detail.services == [
      .init(kind: .support, value: "https://verifier.example/support"),
      .init(kind: .website, value: "https://verifier.example")
    ])
  }

  @Test
  func toDetail_WhenStoredCredentialHasClaimDisplayNames_ThenUsesThemAndFallsBackToTheClaimName() throws {
    let entry = TransactionEntry.presentation(
      .init(
        transactionIdentifier: "p",
        time: now,
        transactionResult: .completed,
        listOfClaimsRequested: [],
        listOfClaimsPresented: [
          ClaimInfo(
            credentialIdentifier: "eu.europa.ec.eudi.pid.1",
            claims: [
              ClaimPath([.claim(name: "eu.europa.ec.eudi.pid.1"), .claim(name: "family_name")]),
              ClaimPath([.claim(name: "eu.europa.ec.eudi.pid.1"), .claim(name: "family_name")]),
              ClaimPath([.claim(name: "eu.europa.ec.eudi.pid.1"), .claim(name: "iat")])
            ]
          )
        ]
      )
    )

    let detail = try #require(
      entry.toDetail(claimNames: ["eu.europa.ec.eudi.pid.1": ["family_name": "Family name"]]).presentation
    )

    #expect(detail.credentials.first?.sharedClaims == ["Family name", "iat"])
  }

  @Test
  func toDetail_WhenCredentialWasDeleted_ThenTheTitleIsTheSameAsInTheList() {
    let entry = TransactionEntry.credentialDeletion(
      .init(transactionIdentifier: "d", time: now, transactionResult: .completed, credentialIdentifier: "urn:eudi:pid:de:1")
    )

    #expect(entry.toDetail().title == entry.toListItem(now: now, calendar: calendar).title)
    #expect(entry.toDetail().title
      == LocalizableStringKey.activitiesLogCredentialDeleted([LocalizableStringKey.dashboardCardTitle.toString]).toString)
  }

  @Test
  func time_WhenEnglish_ThenUsesTwelveHourClockAndWhenGerman_ThenTwentyFourHour() {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = .current
    let date = calendar.date(from: DateComponents(year: 2026, month: 3, day: 12, hour: 14, minute: 38))!

    #expect(ActivityDateFormatter.time(date, locale: Locale(identifier: "en")).contains("PM"))
    #expect(ActivityDateFormatter.time(date, locale: Locale(identifier: "de")).contains("14:38"))
    #expect(ActivityDateFormatter.date(date) == "12.03.2026")
  }

  @Test
  func url_WhenLinkIsHttpsMailOrPhone_ThenOpensItAndOtherwiseNot() {
    #expect(ActivityServiceLinkUIModel(kind: .website, value: "https://issuer.example/info").url?.absoluteString
      == "https://issuer.example/info")
    #expect(ActivityServiceLinkUIModel(kind: .support, value: "support@issuer.example").url?.absoluteString
      == "mailto:support@issuer.example")
    #expect(ActivityServiceLinkUIModel(kind: .support, value: "+49 221 123456").url?.absoluteString == "tel:+49221123456")
    #expect(ActivityServiceLinkUIModel(kind: .website, value: "http://issuer.example").url == nil)
    #expect(ActivityServiceLinkUIModel(kind: .website, value: "javascript:alert(1)").url == nil)
  }

  private func makeIssuance(
    id: String,
    time: Date,
    result: TransactionResult,
    identifiers: [String],
    issuer: MultiLangString? = nil
  ) -> TransactionEntry {
    .credentialIssuance(
      .init(
        transactionIdentifier: "issuance:\(id)",
        time: time,
        transactionResult: result,
        details: .init(
          credentialNumberRequested: 1,
          credentialNumberIssued: result == .completed ? 1 : 0,
          credentialIdentifier: identifiers,
          interactingPartyName: issuer
        )
      )
    )
  }
}
