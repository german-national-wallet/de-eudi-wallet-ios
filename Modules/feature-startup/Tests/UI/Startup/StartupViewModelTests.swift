//
//  StartupViewModelTests.swift
//  feature-startup
//

import XCTest
import Cuckoo
import logic_api
import logic_resources
import logic_ui
import wallet_backend
@testable import feature_common
@testable import feature_startup
@testable import feature_test

@MainActor
final class StartupViewModelTests: XCTestCase {

  private var router: MockRouterHost!
  private var interactor: MockStartupInteractor!
  private var walletRegistrationInteractor: FakeWalletRegistrationInteractor!
  private var walletRevocationInteractor: MockWalletRevocationInteractor!
  private var sut: StartupViewModel<MockRouterHost>!

  override func setUp() {
    super.setUp()
    router = MockRouterHost()
    interactor = MockStartupInteractor()
    walletRegistrationInteractor = FakeWalletRegistrationInteractor(error: NetworkError.noInternet)
    walletRevocationInteractor = MockWalletRevocationInteractor()
    stub(interactor) { mock in
      when(mock.initializeAppFlow(with: any())).thenReturn(.featureDashboardModule(.dashboard))
    }
    stub(walletRevocationInteractor) { mock in
      when(mock.isWalletRevoked.get).thenReturn(false)
    }
    sut = StartupViewModel(
      router: router,
      interactor: interactor,
      walletRegistrationInteractor: walletRegistrationInteractor,
      pnsAccountInteractor: MockPNSAccountInteractor(),
      walletRevocationInteractor: walletRevocationInteractor,
      deepLinkController: MockDeepLinkController(),
      connectivityMonitor: MockNetworkConnectivityMonitor.stubbed(),
      logger: nil,
      splashDuration: 0
    )
  }

  override func tearDown() {
    sut = nil
    walletRevocationInteractor = nil
    walletRegistrationInteractor = nil
    interactor = nil
    router = nil
    super.tearDown()
  }

  func testRegisterWallet_WhenOffline_ThenShowsNoInternetDialogInsteadOfErrorPopup() async {
    await sut.registerWallet()

    XCTAssertTrue(sut.noInternetDialog.isPresented)
    XCTAssertFalse(sut.isErrorPopupVisible)
  }

  func testRegisterWallet_WhenOfflineAndRetryTapped_ThenRegistersAgainWithoutRestartingTheAppFlow() async {
    await sut.registerWallet()
    let registeredAgain = expectation(description: "registration requested again")
    walletRegistrationInteractor.onRegister = { registeredAgain.fulfill() }

    sut.noInternetDialog.retry()
    await fulfillment(of: [registeredAgain], timeout: 5)

    XCTAssertEqual(walletRegistrationInteractor.registerCount, 2)
    verify(interactor, times(1)).initializeAppFlow(with: any())
  }

  func testRegisterWallet_WhenOfflineAndCancelTapped_ThenShowsTheExistingErrorPopup() async {
    await sut.registerWallet()

    sut.noInternetDialog.cancel()

    XCTAssertTrue(sut.isErrorPopupVisible)
  }

  func testRegisterWallet_WhenRegistrationFailsOnline_ThenShowsTheExistingErrorPopup() async {
    walletRegistrationInteractor.error = BackendError.invalidResponse

    await sut.registerWallet()

    XCTAssertFalse(sut.noInternetDialog.isPresented)
    XCTAssertTrue(sut.isErrorPopupVisible)
  }

  // MARK: - Timeouts and rate limits (transport failures while online)

  func testRegisterWallet_WhenBackendTimesOut_ThenSlowInternetPopupOffersRetry() async {
    walletRegistrationInteractor.error = NetworkError.internetFailure(URLError(.timedOut))

    await sut.registerWallet()

    XCTAssertFalse(sut.noInternetDialog.isPresented)
    XCTAssertTrue(sut.isErrorPopupVisible)
    XCTAssertEqual(sut.errorPopupViewModel.title, LocalizableStringKey.globalTimeoutSlowInternetErrorTitle.toString)
    XCTAssertEqual(
      sut.errorPopupViewModel.primaryButtontitle,
      LocalizableStringKey.globalTimeoutSlowInternetErrorPrimButton.toString
    )
    XCTAssertNil(sut.errorPopupViewModel.secondaryButtontitle)
    XCTAssertEqual(walletRegistrationInteractor.registerCount, 1)
  }

  func testRegisterWallet_WhenTimeoutRetryTapped_ThenRegistrationRunsAgain() async {
    walletRegistrationInteractor.error = NetworkError.internetFailure(URLError(.timedOut))
    await sut.registerWallet()
    let registeredAgain = expectation(description: "registration requested again")
    walletRegistrationInteractor.onRegister = { registeredAgain.fulfill() }

    sut.errorPopupViewModel.onConfirm()
    await fulfillment(of: [registeredAgain], timeout: 5)

    XCTAssertEqual(walletRegistrationInteractor.registerCount, 2)
  }

  func testRegisterWallet_WhenGatewayTimesOut_ThenSlowInternetPopup() async {
    walletRegistrationInteractor.error = NetworkError.httpError(code: 504, data: nil, headers: nil)

    await sut.registerWallet()

    XCTAssertTrue(sut.isErrorPopupVisible)
    XCTAssertEqual(sut.errorPopupViewModel.title, LocalizableStringKey.globalTimeoutSlowInternetErrorTitle.toString)
  }

  func testRegisterWallet_WhenRateLimited_ThenGotItLeavesWithoutRetrying() async {
    stub(router) { mock in
      when(mock.popTo(with: any())).thenDoNothing()
    }
    walletRegistrationInteractor.error = NetworkError.httpError(code: 429, data: nil, headers: ["Retry-After": "60"])
    await sut.registerWallet()

    XCTAssertTrue(sut.isErrorPopupVisible)
    XCTAssertEqual(sut.errorPopupViewModel.title, LocalizableStringKey.globalTimeoutTooManyRequestsTitle.toString)
    XCTAssertEqual(
      sut.errorPopupViewModel.primaryButtontitle,
      LocalizableStringKey.globalNoInternetErrorPrimButton.toString
    )

    sut.errorPopupViewModel.onConfirm()

    XCTAssertFalse(sut.isErrorPopupVisible)
    XCTAssertEqual(walletRegistrationInteractor.registerCount, 1)
    verify(router).popTo(with: any())
  }

  func testRegisterWallet_WhenBackendErrorIsNotTransport_ThenGenericBackendPopup() async {
    walletRegistrationInteractor.error = BackendError.unknown

    await sut.registerWallet()

    XCTAssertTrue(sut.isErrorPopupVisible)
    XCTAssertEqual(sut.errorPopupViewModel.title, LocalizableStringKey.globalErrorTitle.toString)
    XCTAssertEqual(
      sut.errorPopupViewModel.primaryButtontitle,
      LocalizableStringKey.globalErrorPrimaryButtonTitle.toString
    )
  }

  func testRegisterWallet_WhenWalletRevoked_ThenNoPopupForTimeout() async {
    stub(walletRevocationInteractor) { mock in
      when(mock.isWalletRevoked.get).thenReturn(true)
    }
    walletRegistrationInteractor.error = NetworkError.internetFailure(URLError(.timedOut))

    await sut.registerWallet()

    XCTAssertFalse(sut.isErrorPopupVisible)
    XCTAssertEqual(walletRegistrationInteractor.registerCount, 0, "a revoked wallet skips registration")
  }
}

private final class FakeWalletRegistrationInteractor: WalletRegistrationInteractor {
  var error: Error
  var registerCount = 0
  var onRegister: (() -> Void)?

  init(error: Error) {
    self.error = error
  }

  func registerWalletInstance() async throws -> String {
    registerCount += 1
    onRegister?()
    throw error
  }
}
