//
//  RemoteSessionCoordinatorTests.swift
//  logic-core
//
//  Created by Ameen Qadri on 12.10.26.
//

import XCTest
@testable import EudiWalletKit
@testable import logic_core

final class RemoteSessionCoordinatorTests: XCTestCase {

  func testDeclineResponse_WhenVerifierReturnsRedirectURI_ThenReturnsIt() async throws {
    let redirectURL = try XCTUnwrap(URL(string: "https://verifier.example/cancelled?transaction=42"))
    let service = DecliningPresentationService(redirectURL: redirectURL)
    let sut = RemoteSessionCoordinatorImpl(session: makeSession(with: service))

    let result = try await sut.declineResponse()

    XCTAssertEqual(result, redirectURL)
  }

  func testDeclineResponse_WhenVerifierReturnsNoRedirectURI_ThenReturnsNil() async throws {
    let service = DecliningPresentationService(redirectURL: nil)
    let sut = RemoteSessionCoordinatorImpl(session: makeSession(with: service))

    let result = try await sut.declineResponse()

    XCTAssertNil(result)
  }

  func testDeclineResponse_ThenSendsNegativeConsentWithoutItems() async throws {
    let service = DecliningPresentationService(redirectURL: nil)
    let sut = RemoteSessionCoordinatorImpl(session: makeSession(with: service))

    _ = try await sut.declineResponse()

    XCTAssertEqual(service.recordedUserAccepted, [false])
    XCTAssertEqual(service.recordedItemCounts, [0])
  }

  func testDeclineResponse_WhenDispatchFails_ThenThrows() async {
    let service = DecliningPresentationService(redirectURL: nil, failure: DecliningPresentationService.DispatchFailure())
    let sut = RemoteSessionCoordinatorImpl(session: makeSession(with: service))

    do {
      _ = try await sut.declineResponse()
      XCTFail("Expected declineResponse to throw")
    } catch {
      XCTAssertTrue(error is DecliningPresentationService.DispatchFailure)
    }
  }

  private func makeSession(with service: DecliningPresentationService) -> PresentationSession {
    PresentationSession(
      presentationService: service,
      docIdToPresentInfo: [:],
      documentKeyIndexes: [:],
      userAuthenticationRequired: false,
      localAuthenticationContext: ThreadSafeAuthContext()
    )
  }
}

private final class DecliningPresentationService: PresentationService, @unchecked Sendable {

  struct DispatchFailure: Error {}

  private let redirectURL: URL?
  private let failure: Error?
  private(set) var recordedUserAccepted: [Bool] = []
  private(set) var recordedItemCounts: [Int] = []

  init(redirectURL: URL?, failure: Error? = nil) {
    self.redirectURL = redirectURL
    self.failure = failure
  }

  var flow: FlowType { .other }

  var transactionLog: MdocDataModel18013.TransactionEntry = .otherTransaction(
    .init(
      transactionIdentifier: UUID().uuidString,
      time: Date(),
      transactionResult: .notCompleted,
      description: ["declining"]
    )
  )

  var transactionLogger: (any MdocDataModel18013.TransactionLogger)?

  var zkpDocumentIds: [WalletStorage.Document.ID]? { nil }
  var wrpVerifierPolicy: WrpRegistrationPolicy? { nil }
  var wrpVerifierWarnings: [String: [PresentationPolicyViolation]]? { nil }

  func startQrEngagement(secureAreaName: String?, keyOptions: KeyOptions) async throws -> String {
    ""
  }

  func receiveRequest() async throws -> [MdocDataTransfer18013.UserRequestInfo] {
    []
  }

  func sendResponse(
    userAccepted: Bool,
    itemsToSend: EudiWalletKit.RequestItems,
    deviceNameSpacesToSend: RequestDeviceNameSpaces?,
    authenticationContext: ThreadSafeAuthContext,
    onSuccess: (@Sendable (URL?) -> Void)?
  ) async throws {
    recordedUserAccepted.append(userAccepted)
    recordedItemCounts.append(itemsToSend.count)
    if let failure {
      throw failure
    }
    onSuccess?(redirectURL)
  }

  func waitForDisconnect() async throws {}
}
