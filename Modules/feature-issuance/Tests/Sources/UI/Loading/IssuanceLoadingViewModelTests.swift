//
//  IssuanceLoadingViewModelTests.swift
//  IssuanceLoadingViewModelTests
//
//  Created by Tamas Dancsi  on 05.05.26.
//

import XCTest
import Cuckoo
import feature_common
import logic_api
import logic_core
import feature_test
@testable import feature_issuance

@MainActor
final class IssuanceLoadingViewModelTests: XCTestCase {

  func testPerformWalletRegistration_WhenPrivateKeyCannotBeCreated_ThenDoesNotRequestCredentials() async {
    let secureEnclaveController = MockSecureEnclaveController()
    let addDocumentInteractor = MockAddDocumentInteractor()
    let analyticsController = MockAnalyticsController()
    let pinSessionInteractor = MockPinSessionInteractor()
    let sut = makeSUT(
      secureEnclaveController: secureEnclaveController,
      addDocumentInteractor: addDocumentInteractor,
      analyticsController: analyticsController,
      pinSessionInteractor: pinSessionInteractor
    )
    stub(secureEnclaveController) { mock in
      when(mock.createPrivateKey(with: equal(to: .credentialPrivKey))).thenReturn(nil)
    }
    stub(analyticsController) { mock in
      when(mock.endTrace(finalAttributes: any(), errorDescription: any())).thenReturn("trace-id")
    }
    stub(pinSessionInteractor) { mock in
      when(mock.clear()).thenDoNothing()
    }

    await sut.issueCredentials()

    verify(secureEnclaveController).createPrivateKey(with: equal(to: .credentialPrivKey))
    verify(addDocumentInteractor, never()).getCredentials(docTypeIdentifier: any(), any(), privateKey: any())
    verify(pinSessionInteractor).clear()
    verify(analyticsController).endTrace(finalAttributes: any(), errorDescription: notNil())
  }

  func testConfigureErrorPopupViewModel_WhenCalled_ThenShowsPopup() {
    let sut = makeSUT()

    sut.configureErrorPopupViewModel(error: .invalidResponse)

    XCTAssertTrue(sut.errorPopupViewModel.isVisible)
  }

  func testPerformWalletRegistration_WhenCredentialsAreIssued_ThenClearsPinSession() async throws {
    let secureEnclaveController = MockSecureEnclaveController()
    let addDocumentInteractor = MockAddDocumentInteractor()
    let analyticsController = MockAnalyticsController()
    let pinSessionInteractor = MockPinSessionInteractor()
    let router = MockRouterHost()
    let privateKey = SecKeyMock.generateFakePrivateKey()
    let sut = makeSUT(
      router: router,
      secureEnclaveController: secureEnclaveController,
      addDocumentInteractor: addDocumentInteractor,
      analyticsController: analyticsController,
      pinSessionInteractor: pinSessionInteractor
    )
    stub(secureEnclaveController) { mock in
      when(mock.createPrivateKey(with: equal(to: .credentialPrivKey))).thenReturn(privateKey)
      when(mock.storePrivateKey(any(), with: equal(to: .credentialPrivKey))).thenReturn(true)
    }
    stub(addDocumentInteractor) { mock in
      when(mock.getCredentials(docTypeIdentifier: any(), any(), privateKey: any())).thenReturn(true)
    }
    stub(analyticsController) { mock in
      when(mock.endTrace(finalAttributes: any(), errorDescription: any())).thenReturn("trace-id")
    }
    stub(pinSessionInteractor) { mock in
      when(mock.clear()).thenDoNothing()
    }
    stub(router) { mock in
      when(mock.push(with: any())).thenDoNothing()
    }

    await sut.issueCredentials()

    verify(pinSessionInteractor).clear()
    verify(analyticsController).endTrace(finalAttributes: equal(to: [:]), errorDescription: isNil())
    XCTAssertTrue(sut.isIssued)
    verifyNoMoreInteractions(router)
  }

  func testSuccessAnimationFinished_WhenCalledTwice_ThenLeavesTheFlowOnce() {
    let router = MockRouterHost()
    let sut = makeSUT(router: router)
    stub(router) { mock in
      when(mock.popTo(with: any())).thenDoNothing()
    }

    sut.successAnimationFinished()
    sut.successAnimationFinished()

    verify(router, times(1)).popTo(with: any())
  }

  func testPerformWalletRegistration_WhenIssuanceFails_ThenEndsTraceWithErrorAndShowsTraceIdInPopup() async {
    let secureEnclaveController = MockSecureEnclaveController()
    let addDocumentInteractor = MockAddDocumentInteractor()
    let analyticsController = MockAnalyticsController()
    let pinSessionInteractor = MockPinSessionInteractor()
    let privateKey = SecKeyMock.generateFakePrivateKey()
    let sut = makeSUT(
      secureEnclaveController: secureEnclaveController,
      addDocumentInteractor: addDocumentInteractor,
      analyticsController: analyticsController,
      pinSessionInteractor: pinSessionInteractor
    )
    stub(secureEnclaveController) { mock in
      when(mock.createPrivateKey(with: equal(to: .credentialPrivKey))).thenReturn(privateKey)
      when(mock.storePrivateKey(any(), with: equal(to: .credentialPrivKey))).thenReturn(true)
    }
    stub(addDocumentInteractor) { mock in
      when(mock.getCredentials(docTypeIdentifier: any(), any(), privateKey: any()))
        .thenThrow(RWSCARepositoryError.invalidResponse)
    }
    stub(analyticsController) { mock in
      when(mock.currentTraceID.get).thenReturn("trace-id")
      when(mock.endTrace(finalAttributes: any(), errorDescription: any())).thenReturn("trace-id")
    }
    stub(pinSessionInteractor) { mock in
      when(mock.clear()).thenDoNothing()
    }

    await sut.issueCredentials()

    verify(pinSessionInteractor).clear()
    verify(analyticsController).endTrace(finalAttributes: any(), errorDescription: notNil())
    XCTAssertTrue(sut.isErrorPopupVisible)
    XCTAssertEqual(sut.errorPopupViewModel.traceId, "trace-id")
  }

  private func makeSUT(
    router: MockRouterHost = MockRouterHost(),
    secureEnclaveController: MockSecureEnclaveController = MockSecureEnclaveController(),
    addDocumentInteractor: MockAddDocumentInteractor = MockAddDocumentInteractor(),
    analyticsController: MockAnalyticsController = MockAnalyticsController(),
    pinSessionInteractor: MockPinSessionInteractor = MockPinSessionInteractor()
  ) -> IssuanceLoadingViewModel<MockRouterHost> {
    IssuanceLoadingViewModel(
      router: router,
      config: UIConfig.IssuanceLoadingUiConfig(
        finishAuthorizationResponse: .init(
          nonce: "nonce",
          code: "code",
          state: nil,
          location: "https://issuer.example/callback"
        )
      ),
      secureEnclaveController: secureEnclaveController,
      addDocumentInteractor: addDocumentInteractor,
      analyticsController: analyticsController,
      mdvmInteractor: MockMDVMInteractor(),
      rwscaInteractor: MockRWSCAInteractor(),
      pinSessionInteractor: pinSessionInteractor,
      logger: nil
    )
  }
}
