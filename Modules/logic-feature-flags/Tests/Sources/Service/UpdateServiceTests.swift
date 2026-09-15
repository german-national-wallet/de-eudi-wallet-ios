//
//  UpdateServiceTests.swift
//  logic-feature-flag
//
//  Created by Tamas Dancsi on 25.02.26.
//

import Foundation
import Testing
import logic_business
@testable import logic_api
@testable import logic_feature_flags
@testable import logic_test

struct UpdateServiceTests {

  @Test
  func refreshFlagsIfNeeded_WhenStoreIsStale_FetchesAndReplacesFlags() async {
    let context = makeContext(stale: true, payloadFromApi: payloadWithBooleanTrue)

    await context.service.refreshFlagsIfNeeded()

    #expect(context.networkManager.executeCallCount == 1)
    verify(context.store, times(1)).replaceFlags(from: equal(to: payloadWithBooleanTrue))
  }

  @Test
  func refreshFlagsIfNeeded_WhenStoreIsFresh_DoesNotFetch() async {
    let context = makeContext(stale: false, payloadFromApi: payloadWithBooleanTrue)

    await context.service.refreshFlagsIfNeeded()

    #expect(context.networkManager.executeCallCount == 0)
    verify(context.store, times(0)).replaceFlags(from: any())
  }

  @Test
  func refreshFlagsIfNeeded_AsksTheStoreForADayOldCache() async {
    let context = makeContext(stale: false, payloadFromApi: payloadWithBooleanTrue)

    await context.service.refreshFlagsIfNeeded()

    verify(context.store, times(1)).isStale(maxAgeHours: equal(to: 24))
  }

  @Test
  func refreshFlagsIfNeeded_WhenFetchFails_KeepsFlagsUnchanged() async {
    let context = makeContext(stale: true, payloadFromApi: payloadWithBooleanTrue)
    context.networkManager.error = NetworkError.invalidResponse

    await context.service.refreshFlagsIfNeeded()

    verify(context.store, times(0)).replaceFlags(from: any())
  }

  private struct Context {
    let service: UpdateServiceImpl
    let store: MockFlagStore
    let networkManager: FakeNetworkManager
  }

  private func makeContext(stale: Bool, payloadFromApi: String) -> Context {
    let logger = MockLogging()
    let networkManager = FakeNetworkManager()
    let store = MockFlagStore()

    stub(store) { stub in
      when(stub.isStale(maxAgeHours: any())).thenReturn(stale)
      when(stub.replaceFlags(from: any())).thenDoNothing()
    }
    stub(logger) { stub in
      when(stub.d(any(), file: any(), function: any(), line: any())).thenDoNothing()
      when(stub.e(any(), file: any(), function: any(), line: any())).thenDoNothing()
    }
    networkManager.mockResponse = NetworkResponse(data: Data(payloadFromApi.utf8), headers: nil)

    let service = UpdateServiceImpl(
      logger: logger,
      networkManager: networkManager,
      store: store
    )
    return Context(service: service, store: store, networkManager: networkManager)
  }

  private let payloadWithBooleanTrue = """
  [
    {
      "id": "env-id",
      "features": [
        {
          "id": "1",
          "key": "test_feature",
          "l": false,
          "version": 1,
          "type": "BOOLEAN",
          "value": true,
          "strategies": []
        }
      ]
    }
  ]
  """
}
