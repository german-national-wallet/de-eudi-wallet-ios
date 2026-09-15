//
//  TestConsentViewModel.swift
//  feature-presentation
//

import XCTest

import feature_common
import logic_analytics
import logic_core
import logic_ui
@testable import feature_presentation
@testable import feature_test

@MainActor
final class TestConsentViewModel: XCTestCase {

  fileprivate var stubInteractor: ConsentPresentationInteractorStub!
  fileprivate var recordingRouter: RecordingRouterHost!
  var pinSessionInteractor: PinSessionInteractorStub!
  var analyticsController: AnalyticsControllerStub!

  override func setUp() {
    stubInteractor = ConsentPresentationInteractorStub()
    pinSessionInteractor = PinSessionInteractorStub()
    analyticsController = AnalyticsControllerStub()
    recordingRouter = RecordingRouterHost()
  }

  override func tearDown() {
    stubInteractor = nil
    analyticsController = nil
    recordingRouter = nil
    super.tearDown()
  }

  func testDoWork_WhenEngagementSucceeds_ThenPopulatesConsentItemsAndStopsLoading() async {
    let docId = "doc-pid-1"
    let requestCell = Self.makeRequestDataUiModel(
      sectionId: docId,
      credentialTitle: "PID",
      fieldKey: "first_name",
      value: "Jane",
      docId: docId
    )
    let success = OnlineAuthenticationRequestSuccessModel(
      requestDataCells: [requestCell],
      relyingParty: "Test RP",
      dataRequestInfo: "info",
      isTrusted: true
    )
    stubInteractor.deviceEngagementResult = .success(success)

    let viewModel = ConsentViewModel(
      router: recordingRouter,
      interactor: stubInteractor,
      pinSessionInteractor: pinSessionInteractor,
      analyticsController: analyticsController,
      originator: .featureDashboardModule(.dashboard),
      relyingParty: "Fallback RP"
    )

    await viewModel.doWork()

    XCTAssertEqual(viewModel.consentItemGroups.count, 1)
    XCTAssertEqual(viewModel.consentItemGroups.first?.credentialID, docId)
    XCTAssertEqual(viewModel.consentItemGroups.first?.credentialTitle, "PID")
    XCTAssertEqual(viewModel.consentItems.count, 1)
    XCTAssertEqual(viewModel.consentItems.first?.docId, docId)
    XCTAssertFalse(viewModel.viewState.isLoading)
    XCTAssertTrue(viewModel.viewState.initialized)
    XCTAssertTrue(viewModel.viewState.isTrusted)
    XCTAssertEqual(viewModel.viewState.items.count, 1)
  }

  func testDoWork_WhenNestedNationalities_ThenUsesLeafValueInsteadOfGroupTitle() async {
    let docId = "doc-pid-1"
    let requestCell = Self.makeNestedNationalitiesRequestDataUiModel(
      sectionId: docId,
      credentialTitle: "PID",
      docId: docId
    )
    let success = OnlineAuthenticationRequestSuccessModel(
      requestDataCells: [requestCell],
      relyingParty: "Test RP",
      dataRequestInfo: "info",
      isTrusted: true
    )
    stubInteractor.deviceEngagementResult = .success(success)

    let viewModel = ConsentViewModel(
      router: recordingRouter,
      interactor: stubInteractor,
      pinSessionInteractor: pinSessionInteractor,
      analyticsController: analyticsController,
      originator: .featureDashboardModule(.dashboard),
      relyingParty: "Fallback RP"
    )

    await viewModel.doWork()

    XCTAssertEqual(viewModel.consentItemGroups.count, 1)
    XCTAssertEqual(viewModel.consentItems.count, 1)
    XCTAssertEqual(viewModel.consentItems.first?.docId, docId)
    XCTAssertEqual(viewModel.consentItems.first?.description, "DE")
    XCTAssertNotEqual(viewModel.consentItems.first?.description.lowercased(), "nationality")
  }

  func testDoWork_WhenEngagementFails_ThenClearsItems() async {
    stubInteractor.deviceEngagementResult = .failure(TestNSError.generic)

    let viewModel = ConsentViewModel(
      router: recordingRouter,
      interactor: stubInteractor,
      pinSessionInteractor: pinSessionInteractor,
      analyticsController: analyticsController,
      originator: .featureDashboardModule(.dashboard),
      relyingParty: "RP"
    )

    await viewModel.doWork()

    XCTAssertTrue(viewModel.consentItemGroups.isEmpty)
    XCTAssertTrue(viewModel.consentItems.isEmpty)
    XCTAssertTrue(viewModel.viewState.items.isEmpty)
    XCTAssertFalse(viewModel.viewState.isLoading)
    XCTAssertTrue(viewModel.viewState.initialized)
  }

  func testOnDecline_ThenShowsConfirmationPopup() {
    let viewModel = ConsentViewModel(
      router: recordingRouter,
      interactor: stubInteractor,
      pinSessionInteractor: pinSessionInteractor,
      analyticsController: analyticsController,
      originator: .featureDashboardModule(.dashboard),
      relyingParty: "RP"
    )

    viewModel.onDecline()

    XCTAssertTrue(viewModel.isConfirmationPopupVisible)
    XCTAssertFalse(viewModel.confirmationPopupViewModel.title.isEmpty)
    XCTAssertFalse(viewModel.confirmationPopupViewModel.detail.isEmpty)
  }

  func testOnShare_WhenNonPIDAndPrepareSucceeds_ThenPushesPresentationLoader() async throws {
    let coordinator = RemoteSessionCoordinatorStub(session: Constants.mockPresentationSession)
    stubInteractor.coordinatorState = .success(coordinator)
    stubInteractor.pidPresentation = false
    stubInteractor.responsePrepareResult = .success(RequestItemsWrapper())

    let docId = "doc-mdl"
    let requestCell = Self.makeRequestDataUiModel(
      sectionId: docId,
      credentialTitle: "MDL",
      fieldKey: "family_name",
      value: "Doe",
      docId: docId
    )
    stubInteractor.deviceEngagementResult = .success(
      OnlineAuthenticationRequestSuccessModel(
        requestDataCells: [requestCell],
        relyingParty: "Verifier",
        dataRequestInfo: "",
        isTrusted: false
      )
    )

    let viewModel = ConsentViewModel(
      router: recordingRouter,
      interactor: stubInteractor,
      pinSessionInteractor: pinSessionInteractor,
      analyticsController: analyticsController,
      originator: .featureDashboardModule(.dashboard),
      relyingParty: "RP"
    )
    await viewModel.doWork()

    viewModel.onShare()
    try await Task.sleep(nanoseconds: 300_000_000)

    XCTAssertTrue(recordingRouter.didPush)
    if case .featurePresentationModule(let module) = recordingRouter.lastPushedRoute {
      if case .presentationLoader = module {
        XCTAssertTrue(true)
      } else {
        XCTFail("Expected presentationLoader, got \(module)")
      }
    } else {
      XCTFail("Expected presentation route")
    }
  }

  func testOnShare_WhenPIDRequest_ThenPushesPinRoute() async throws {
    let coordinator = RemoteSessionCoordinatorStub(session: Constants.mockPresentationSession)
    stubInteractor.coordinatorState = .success(coordinator)
    stubInteractor.pidPresentation = true
    stubInteractor.responsePrepareResult = .success(RequestItemsWrapper())

    let docId = DocumentTypeIdentifier.mDocPid.rawValue
    let requestCell = Self.makeRequestDataUiModel(
      sectionId: "section-1",
      credentialTitle: "PID",
      fieldKey: "last_name",
      value: "Smith",
      docId: docId
    )
    stubInteractor.deviceEngagementResult = .success(
      OnlineAuthenticationRequestSuccessModel(
        requestDataCells: [requestCell],
        relyingParty: "Verifier",
        dataRequestInfo: "",
        isTrusted: true
      )
    )

    let viewModel = ConsentViewModel(
      router: recordingRouter,
      interactor: stubInteractor,
      pinSessionInteractor: pinSessionInteractor,
      analyticsController: analyticsController,
      originator: .featureDashboardModule(.dashboard),
      relyingParty: "RP"
    )
    await viewModel.doWork()

    viewModel.onShare()
    try await Task.sleep(nanoseconds: 300_000_000)

    XCTAssertTrue(recordingRouter.didPush)
    if case .featurePresentationModule(let module) = recordingRouter.lastPushedRoute {
      if case .showPinView = module {
        XCTAssertTrue(true)
      } else {
        XCTFail("Expected showPinView, got \(module)")
      }
    } else {
      XCTFail("Expected presentation route")
    }
  }

  func testOnShare_WhenPrepareFails_ThenClearsPinSession() async throws {
    let pinSessionInteractor = RecordingPinSessionInteractor()
    stubInteractor.coordinatorState = .success(
      RemoteSessionCoordinatorStub(session: Constants.mockPresentationSession)
    )
    stubInteractor.pidPresentation = true
    stubInteractor.responsePrepareResult = .failure(TestNSError.generic)
    stubInteractor.deviceEngagementResult = .success(
      OnlineAuthenticationRequestSuccessModel(
        requestDataCells: [
          Self.makeRequestDataUiModel(
            sectionId: "section-1",
            credentialTitle: "PID",
            fieldKey: "name",
            value: "X",
            docId: DocumentTypeIdentifier.mDocPid.rawValue
          )
        ],
        relyingParty: "Verifier",
        dataRequestInfo: "",
        isTrusted: false
      )
    )

    let viewModel = ConsentViewModel(
      router: recordingRouter,
      interactor: stubInteractor,
      pinSessionInteractor: pinSessionInteractor,
      analyticsController: analyticsController,
      originator: .featureDashboardModule(.dashboard),
      relyingParty: "RP"
    )
    await viewModel.doWork()

    viewModel.onShare()
    try await Task.sleep(nanoseconds: 300_000_000)

    XCTAssertEqual(pinSessionInteractor.clearCallCount, 1)
    XCTAssertFalse(recordingRouter.didPush)
    XCTAssertNotNil(viewModel.viewState.error)
  }

  func testOnShare_WhenPrepareFails_ThenSetsErrorState() async throws {
    stubInteractor.coordinatorState = .success(
      RemoteSessionCoordinatorStub(session: Constants.mockPresentationSession)
    )
    stubInteractor.pidPresentation = false
    stubInteractor.responsePrepareResult = .failure(TestNSError.generic)

    let docId = "doc-1"
    let requestCell = Self.makeRequestDataUiModel(
      sectionId: docId,
      credentialTitle: "Doc",
      fieldKey: "name",
      value: "X",
      docId: docId
    )
    stubInteractor.deviceEngagementResult = .success(
      OnlineAuthenticationRequestSuccessModel(
        requestDataCells: [requestCell],
        relyingParty: "Verifier",
        dataRequestInfo: "",
        isTrusted: false
      )
    )

    let viewModel = ConsentViewModel(
      router: recordingRouter,
      interactor: stubInteractor,
      pinSessionInteractor: pinSessionInteractor,
      analyticsController: analyticsController,
      originator: .featureDashboardModule(.dashboard),
      relyingParty: "RP"
    )
    await viewModel.doWork()

    viewModel.onShare()
    try await Task.sleep(nanoseconds: 300_000_000)

    XCTAssertFalse(recordingRouter.didPush)
    XCTAssertNotNil(viewModel.viewState.error)
  }

  private static func makeRequestDataUiModel(
    sectionId: String,
    credentialTitle: String,
    fieldKey: String,
    value: String,
    docId: String
  ) -> RequestDataUiModel {
    let domain = DocumentElementClaim.primitive(
      id: "claim-\(fieldKey)",
      title: fieldKey,
      documentId: docId,
      nameSpace: "ns",
      path: [fieldKey],
      type: .mdoc,
      value: .string(value),
      status: .available(isRequired: false)
    )
    let listItem: ExpandableListItem<DocumentElementClaim> = .single(
      .init(
        collapsed: ListItemData(
          mainText: .custom(value),
          overlineText: .custom(fieldKey),
          trailingContent: .checkbox(true, true, { _ in })
        ),
        domainModel: domain
      )
    )
    return RequestDataUiModel(
      section: .init(
        id: sectionId,
        title: credentialTitle,
        listItems: [listItem]
      )
    )
  }

  private static func makeNestedNationalitiesRequestDataUiModel(
    sectionId: String,
    credentialTitle: String,
    docId: String
  ) -> RequestDataUiModel {
    let nationalityDomain = DocumentElementClaim.primitive(
      id: "claim-nationalities-0",
      title: "nationalities",
      documentId: docId,
      nameSpace: "ns",
      path: ["claims", "nationalities", "0"],
      type: .sdjwt,
      value: .string("DE"),
      status: .available(isRequired: false)
    )

    let nationalityLeaf: ExpandableListItem<DocumentElementClaim> = .single(
      .init(
        collapsed: ListItemData(
          mainText: .custom("DE"),
          overlineText: .custom("nationalities"),
          trailingContent: .checkbox(true, true, { _ in })
        ),
        domainModel: nationalityDomain
      )
    )

    let nationalitiesGroup: ExpandableListItem<DocumentElementClaim> = .nested(
      .init(
        collapsed: ListItemData(mainText: .custom("nationalities")),
        expanded: [nationalityLeaf],
        isExpanded: false
      )
    )

    return RequestDataUiModel(
      section: .init(
        id: sectionId,
        title: credentialTitle,
        listItems: [nationalitiesGroup]
      )
    )
  }
}

// MARK: - Test doubles

private enum TestNSError {
  static let generic = NSError(domain: "ConsentViewModelTests", code: 1)
}

private final class ConsentPresentationInteractorStub: PresentationInteractor, @unchecked Sendable {

  var deviceEngagementResult: Result<OnlineAuthenticationRequestSuccessModel, Error> = .failure(TestNSError.generic)
  var responsePrepareResult: Result<RequestItemConvertible, Error> = .success(RequestItemsWrapper())
  var coordinatorState: PresentationCoordinatorPartialState = .failure(TestNSError.generic)
  var pidPresentation: Bool = false

  func getSessionStatePublisher() -> RemotePublisherPartialState {
    .failure(TestNSError.generic)
  }

  func getCoordinator() -> PresentationCoordinatorPartialState {
    coordinatorState
  }

  func onDeviceEngagement() async -> Result<OnlineAuthenticationRequestSuccessModel, Error> {
    deviceEngagementResult
  }

  func onResponsePrepare(requestItems: [RequestDataUiModel]) async -> Result<RequestItemConvertible, Error> {
    responsePrepareResult
  }

  func onSendResponse() async -> RemoteSentResponsePartialState {
    .failure(TestNSError.generic)
  }

  func updatePresentationCoordinator(with coordinator: RemoteSessionCoordinator) {}

  func storeDynamicIssuancePendingUrl(with url: URL) {}

  func stopPresentation() {}

  func isPIDPresentation(documentIDs: [String]) -> Bool {
    pidPresentation
  }

  func getClaimCount(documentID: String) -> Int {
    0
  }
}

private final class RecordingPinSessionInteractor: PinSessionInteractor {
  private(set) var clearCallCount = 0

  func set(pin: String) async throws {}

  func clear() {
    clearCallCount += 1
  }
}

@MainActor
private final class RecordingRouterHost: RouterHost {

  private(set) var didPush = false
  private(set) var lastPushedRoute: AppRoute?

  func push(with route: AppRoute) {
    didPush = true
    lastPushedRoute = route
  }

  func popTo(with route: AppRoute, inclusive: Bool, animated: Bool) {}

  func popTo(with route: AppRoute, inclusive: Bool) {}

  func popTo(with route: AppRoute) {}

  func pop(animated: Bool) {}

  func pop() {}

  func composeApplication() -> AnyView {
    EmptyView().eraseToAnyView()
  }

  func getCurrentScreen() -> AppRoute? { nil }

  func getToolbarConfig() -> UIConfig.ToolBar {
    .init(.clear)
  }

  func userIsLoggedInWithDocuments() -> Bool { true }

  func userIsLoggedInWithNoDocuments() -> Bool { false }

  func isScreenForeground(with route: AppRoute) -> Bool { false }

  func isScreenOnBackStack(with route: AppRoute) -> Bool { true }
}
