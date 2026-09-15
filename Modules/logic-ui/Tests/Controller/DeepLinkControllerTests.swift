//
//  DeepLinkControllerTests.swift
//  DeepLinkControllerTests
//
//  Created by Tamas Dancsi  on 05.05.26.
//

import XCTest
import Cuckoo
import logic_business
@testable import logic_ui

final class DeepLinkControllerTests: XCTestCase {

  private var prefsController: MockPrefsController!
  private var urlSchemaController: MockUrlSchemaController!
  private var walletKitController: MockWalletKitController!
  private var sut: DeepLinkControllerImpl!

  override func setUp() {
    super.setUp()

    prefsController = MockPrefsController()
    urlSchemaController = MockUrlSchemaController()
    walletKitController = MockWalletKitController()
    sut = DeepLinkControllerImpl(
      prefsController: prefsController,
      urlSchemaController: urlSchemaController,
      walletKitController: walletKitController
    )

    stubDeepLinkSchemas()
  }

  override func tearDown() {
    sut = nil
    walletKitController = nil
    urlSchemaController = nil
    prefsController = nil

    super.tearDown()
  }

  func testHasDeepLink_WhenURLUsesOpenID4VPScheme_ThenReturnsOpenID4VPAction() throws {
    let executable = try XCTUnwrap(sut.hasDeepLink(url: makeURL(scheme: "openid4vp")))

    XCTAssertEqual(executable.action, .openid4vp)
    XCTAssertTrue(executable.requiresCoordinator)
  }

  func testHasDeepLink_WhenURLUsesCredentialOfferScheme_ThenReturnsCredentialOfferAction() throws {
    let executable = try XCTUnwrap(sut.hasDeepLink(url: makeURL(scheme: "credential-offer")))

    XCTAssertEqual(executable.action, .credential_offer)
    XCTAssertFalse(executable.requiresCoordinator)
  }

  func testHasDeepLink_WhenURLUsesUnknownScheme_ThenReturnsExternalAction() throws {
    let executable = try XCTUnwrap(sut.hasDeepLink(url: makeURL(scheme: "https")))

    XCTAssertEqual(executable.action, .external)
    XCTAssertFalse(executable.requiresCoordinator)
  }

  func testGetPendingDeepLinkAction_WhenCachedURLExists_ThenReturnsExecutable() throws {
    stub(prefsController) { mock in
      when(mock.getString(forKey: equal(to: .cachedDeepLink)))
        .thenReturn(makeURL(scheme: "openid4vp").absoluteString)
    }

    let executable = try XCTUnwrap(sut.getPendingDeepLinkAction())

    XCTAssertEqual(executable.action, .openid4vp)
    verify(prefsController).getString(forKey: equal(to: .cachedDeepLink))
  }

  // MARK: - handleDeepLinkAction cold-start deferral

  /// Regression guard: a presentation deep link that arrives while the
  /// wallet is still on the startup/splash screen must be cached and deferred, not driven
  /// against the not-yet-loaded wallet. It is replayed later from the dashboard.
  @MainActor
  func testHandleDeepLinkAction_WhenPresentationAndOnStartupScreen_ThenCachesAndDoesNotNavigate() throws {
    let mockRouter = MockRouterHost()
    stub(mockRouter) { mock in
      when(mock.isScreenForeground(with: any())).thenReturn(true)
    }
    stub(prefsController) { mock in
      when(mock.setValue(any(), forKey: any())).thenDoNothing()
    }
    sut.setDeeplinkFlowFlag(false)

    let executable = try XCTUnwrap(sut.hasDeepLink(url: makeURL(scheme: "openid4vp")))

    sut.handleDeepLinkAction(
      routerHost: mockRouter,
      deepLinkExecutable: executable,
      remoteSessionCoordinator: nil
    )

    verify(prefsController).setValue(any(), forKey: equal(to: .cachedDeepLink))
    verify(mockRouter, never()).push(with: any())
    XCTAssertFalse(sut.isDeeplinkFlowActive())
  }

  private func stubDeepLinkSchemas() {
    stub(urlSchemaController) { mock in
      when(mock.retrieveSchemas(with: equal(to: "openid4vp"))).thenReturn(["openid4vp"])
      when(mock.retrieveSchemas(with: equal(to: "haip-vp"))).thenReturn(["haip-vp"])
      when(mock.retrieveSchemas(with: equal(to: "credential-offer"))).thenReturn(["credential-offer"])
      when(mock.retrieveSchemas(with: equal(to: "haip-vci"))).thenReturn(["haip-vci"])
    }
  }

  private func makeURL(scheme: String) -> URL {
    URL(string: "\(scheme)://authorize?request_uri=https%3A%2F%2Fverifier.example%2Frequest")!
  }
}
