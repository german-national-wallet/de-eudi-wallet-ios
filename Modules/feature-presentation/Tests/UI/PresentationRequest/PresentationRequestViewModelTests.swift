//
//  PresentationRequestViewModelTests.swift
//  PresentationRequestViewModelTests
//
//  Created by Tamas Dancsi  on 05.05.26.
//

import XCTest
import Cuckoo
import feature_common
import logic_core
@testable import feature_presentation
@testable import feature_test

@MainActor
final class PresentationRequestViewModelTests: XCTestCase {

  private var router: MockRouterHost!
  private var interactor: MockPresentationInteractor!
  private var pinSessionInteractor: MockPinSessionInteractor!
  private var sut: PresentationRequestViewModel<MockRouterHost>!

  override func setUp() {
    super.setUp()

    router = MockRouterHost()
    interactor = MockPresentationInteractor()
    pinSessionInteractor = MockPinSessionInteractor()
    sut = PresentationRequestViewModel(
      router: router,
      interactor: interactor,
      pinSessionInteractor: pinSessionInteractor,
      originator: .featureDashboardModule(.dashboard)
    )
  }

  override func tearDown() {
    sut = nil
    pinSessionInteractor = nil
    interactor = nil
    router = nil

    super.tearDown()
  }

  func testDoWork_WhenDeviceEngagementSucceeds_ThenShowsRequestedItems() async {
    let requestItem = makeSelectedRequestDataUIModel()
    stub(interactor) { mock in
      when(mock.onDeviceEngagement()).thenReturn(.success(
        .init(
          requestDataCells: [requestItem],
          relyingParty: "Verifier",
          dataRequestInfo: "Request info",
          isTrusted: true
        )
      ))
    }

    await sut.doWork()

    XCTAssertFalse(sut.viewState.isLoading)
    XCTAssertTrue(sut.viewState.initialized)
    XCTAssertTrue(sut.viewState.allowShare)
    XCTAssertEqual(sut.viewState.items.count, 1)
    XCTAssertTrue(sut.viewState.isTrusted)
    verify(interactor).onDeviceEngagement()
  }

  func testDoWork_WhenDeviceEngagementFails_ThenShowsEmptyRequest() async {
    stub(interactor) { mock in
      when(mock.onDeviceEngagement()).thenReturn(.failure(TestNSError.generic))
    }

    await sut.doWork()

    XCTAssertFalse(sut.viewState.isLoading)
    XCTAssertTrue(sut.viewState.initialized)
    XCTAssertTrue(sut.viewState.items.isEmpty)
    verify(interactor).onDeviceEngagement()
  }

  func testOnShare_WhenResponsePrepareSucceeds_ThenPushesBiometryRoute() async {
    let expectation = expectation(description: "Wait for biometry route push")
    let coordinator = MockRemoteSessionCoordinator(session: Constants.mockPresentationSession)
    stub(interactor) { mock in
      when(mock.onDeviceEngagement()).thenReturn(.success(
        .init(
          requestDataCells: [makeSelectedRequestDataUIModel()],
          relyingParty: "Verifier",
          dataRequestInfo: "Request info",
          isTrusted: true
        )
      ))
      when(mock.onResponsePrepare(requestItems: any())).thenReturn(.success(RequestItemsWrapper()))
      when(mock.getCoordinator()).thenReturn(.success(coordinator))
      when(mock.isPIDPresentation(documentIDs: any())).thenReturn(false)
    }
    stub(router) { mock in
      when(mock.push(with: any())).then { _ in
        expectation.fulfill()
      }
    }

    await sut.doWork()
    sut.onShare()

    await fulfillment(of: [expectation], timeout: 1)
    verify(interactor).onResponsePrepare(requestItems: any())
    verify(interactor).getCoordinator()
    verify(router).push(with: any())
  }

  func testOnShare_WhenPIDResponsePrepareSucceeds_ThenPushesPinRoute() async {
    let expectation = expectation(description: "Wait for PIN route push")
    let coordinator = MockRemoteSessionCoordinator(session: Constants.mockPresentationSession)
    stub(interactor) { mock in
      when(mock.onDeviceEngagement()).thenReturn(.success(
        .init(
          requestDataCells: [makeSelectedRequestDataUIModel()],
          relyingParty: "Verifier",
          dataRequestInfo: "Request info",
          isTrusted: true
        )
      ))
      when(mock.onResponsePrepare(requestItems: any())).thenReturn(.success(RequestItemsWrapper()))
      when(mock.getCoordinator()).thenReturn(.success(coordinator))
      when(mock.isPIDPresentation(documentIDs: any())).thenReturn(true)
    }
    stub(router) { mock in
      when(mock.push(with: any())).then { route in
        if case .featurePresentationModule(.showPinView) = route {
          expectation.fulfill()
        }
      }
    }

    await sut.doWork()
    sut.onShare()

    await fulfillment(of: [expectation], timeout: 1)
    verify(interactor).onResponsePrepare(requestItems: any())
    verify(interactor).getCoordinator()
    verify(router).push(with: any())
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
}

private enum TestNSError {
  static let generic = NSError(domain: "PresentationRequestViewModelTests", code: 1)
}
