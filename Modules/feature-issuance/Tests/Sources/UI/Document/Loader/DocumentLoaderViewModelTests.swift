//
//  DocumentLoaderViewModelTests.swift
//  DocumentLoaderViewModelTests
//
//  Created by Pankaj Sachdeva on 18.08.26.
//

import XCTest
import Cuckoo
import logic_core
import logic_resources
import logic_ui
import feature_common
@testable import feature_test
@testable import feature_issuance

private final class FailureRecorder: @unchecked Sendable {
  private let lock = NSLock()
  private var count = 0

  func record() {
    lock.lock()
    count += 1
    lock.unlock()
  }

  var recordedCount: Int {
    lock.lock()
    defer { lock.unlock() }
    return count
  }
}

@MainActor
final class DocumentLoaderViewModelTests: XCTestCase {

  private var router: MockRouterHost!
  private var interactor: MockDocumentOfferInteractor!
  private var failureRecorder: FailureRecorder!
  private var sut: DocumentLoaderViewModel<MockRouterHost>!

  override func setUp() {
    super.setUp()

    router = MockRouterHost()
    interactor = MockDocumentOfferInteractor()
    failureRecorder = FailureRecorder()
    stub(interactor) { mock in
      when(mock.resumeDynamicIssuance(issuerName: any(), successNavigation: any()))
        .thenReturn(.noPending)
    }
    sut = makeSut()
  }

  override func tearDown() {
    sut = nil
    failureRecorder = nil
    interactor = nil
    router = nil

    super.tearDown()
  }

  func testIssueDocuments_WhenInteractorSucceeds_ThenConfirmsSuccessAndFollowsConfiguredNavigation() async {
    stub(interactor) { mock in
      when(mock.issueDocuments(
        with: any(),
        issuerName: any(),
        docOffers: any(),
        successNavigation: any(),
        txCodeValue: any()
      ))
      .thenReturn(.success(.featureDashboardModule(.dashboard)))
    }
    stub(router) { mock in
      when(mock.push(with: any())).thenDoNothing()
    }

    await sut.issueDocuments()

    verify(interactor).issueDocuments(
      with: equal(to: "openid-credential-offer://credential-offer"),
      issuerName: equal(to: "Issuer"),
      docOffers: any(),
      successNavigation: any(),
      txCodeValue: isNil()
    )
    XCTAssertEqual(sut.viewState.progress, .success)
    
    verify(router, never()).push(with: any())

    sut.successAnimationFinished()

    verify(router).push(with: equal(to: .featureDashboardModule(.dashboard)))
  }

  func testSuccessAnimationFinished_WhenCalledTwice_ThenFollowsTheNavigationOnce() {
    stub(router) { mock in
      when(mock.push(with: any())).thenDoNothing()
    }

    sut.successAnimationFinished()
    sut.successAnimationFinished()

    verify(router, times(1)).push(with: any())
  }

  func testIssueDocuments_WhenInteractorFails_ThenReportsFailureAndPops() async {
    stub(interactor) { mock in
      when(mock.issueDocuments(
        with: any(),
        issuerName: any(),
        docOffers: any(),
        successNavigation: any(),
        txCodeValue: any()
      ))
      .thenReturn(.failure(WalletCoreError.unableToIssueAndStore))
    }
    stub(router) { mock in
      when(mock.pop()).thenDoNothing()
    }

    await sut.issueDocuments()

    XCTAssertEqual(failureRecorder.recordedCount, 1)
    XCTAssertEqual(sut.viewState.progress, .loading)
    verify(router).pop()
    verify(router, never()).push(with: any())
  }

  func testIssueDocuments_WhenIssuanceIsDeferred_ThenPushesTheDeferredRoute() async {
    let deferredRoute = AppRoute.featureCommonModule(.genericSuccess(config: NoConfig()))
    stub(interactor) { mock in
      when(mock.issueDocuments(
        with: any(),
        issuerName: any(),
        docOffers: any(),
        successNavigation: any(),
        txCodeValue: any()
      ))
      .thenReturn(.deferredSuccess(deferredRoute))
    }
    stub(router) { mock in
      when(mock.push(with: any())).thenDoNothing()
    }

    await sut.issueDocuments()

    XCTAssertEqual(failureRecorder.recordedCount, 0)
    verify(router).push(with: equal(to: deferredRoute))
  }

  func testIssueDocuments_WhenAnIssuanceWasPending_ThenItIsResumedInsteadOfStartingANewOne() async {
    stub(interactor) { mock in
      when(mock.resumeDynamicIssuance(issuerName: any(), successNavigation: any()))
        .thenReturn(.success(.featureDashboardModule(.dashboard)))
    }
    stub(router) { mock in
      when(mock.push(with: any())).thenDoNothing()
    }

    await sut.issueDocuments()

    XCTAssertEqual(sut.viewState.progress, .success)
    verify(interactor, never()).issueDocuments(
      with: any(),
      issuerName: any(),
      docOffers: any(),
      successNavigation: any(),
      txCodeValue: any()
    )

    sut.successAnimationFinished()

    verify(router).push(with: equal(to: .featureDashboardModule(.dashboard)))
  }

  private func makeSut() -> DocumentLoaderViewModel<MockRouterHost> {
    .init(
      router: router,
      config: makeConfig(),
      interactor: interactor,
      onFailure: { [failureRecorder] in
        failureRecorder?.record()
      }
    )
  }

  private func makeConfig() -> DocumentLoaderUiConfig {
    .init(
      offerUri: "openid-credential-offer://credential-offer",
      issuerName: "Issuer",
      docOffers: [],
      successNavigation: .push(.featureDashboardModule(.dashboard)),
      navigationCancelType: .pop
    )
  }
}
