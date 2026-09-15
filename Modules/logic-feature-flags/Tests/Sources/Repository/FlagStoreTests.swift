//
//  FlagStoreTests.swift
//  logic-feature-flag
//
//  Created by Tamas Dancsi on 25.02.26.
//

import Foundation
import Testing
import logic_business
@testable import logic_feature_flags
@testable import logic_test

struct FlagStoreTests {

  private let testFlag = FeatureFlag<Bool>(key: "test_feature", defaultValue: false)

  private let isoDateFormatter: ISO8601DateFormatter = {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    return formatter
  }()

  @Test
  func getFlagValue_ReturnsDefault_WhenCacheIsEmpty() async {
    let context = makeContext(payload: "")
    let value = await context.sut.getFlagValue(testFlag)
    #expect(value == false)
  }

  @Test
  func getFlagValue_ReturnsCachedValue_WhenCacheIsValid() async {
    let context = makeContext(payload: payloadWithBooleanTrue)
    let value = await context.sut.getFlagValue(testFlag)
    #expect(value == true)
  }

  @Test
  func getFlagValue_ReturnsDefault_WhenCacheHasDuplicateKey() async {
    let context = makeContext(payload: payloadWithDuplicateKey)
    let value = await context.sut.getFlagValue(testFlag)
    #expect(value == false)
  }

  @Test
  func isStale_ReturnsTrue_WhenNothingWasFetchedYet() async {
    let context = makeContext(payload: "", lastUpdate: "")
    #expect(await context.sut.isStale(maxAgeHours: 24) == true)
  }

  @Test
  func isStale_ReturnsFalse_WhenLastFetchIsWithinMaxAge() async {
    let context = makeContext(payload: "", lastUpdate: isoDateFormatter.string(from: Date()))
    #expect(await context.sut.isStale(maxAgeHours: 24) == false)
  }

  @Test
  func isStale_ReturnsTrue_WhenLastFetchIsOlderThanMaxAge() async {
    let context = makeContext(
      payload: "",
      lastUpdate: isoDateFormatter.string(from: Date().addingTimeInterval(-25 * 3600))
    )
    #expect(await context.sut.isStale(maxAgeHours: 24) == true)
  }

  @Test
  func replaceFlags_StoresPayloadAndTimestamp_AndServesTheNewValues() async throws {
    let context = makeContext(payload: "")

    try await context.sut.replaceFlags(from: payloadWithBooleanTrue)

    #expect(await context.sut.getFlagValue(testFlag) == true)
    verify(context.prefs, times(1)).setValue(string(payloadWithBooleanTrue), forKey: equal(to: Prefs.Key.featureFlagsPayload))
    verify(context.prefs, times(1)).setValue(any(), forKey: equal(to: Prefs.Key.featureFlagsLastUpdate))
  }

  @Test
  func replaceFlags_WithEmptyFeatureList_RemovesCachedPayloadButKeepsTimestamp() async throws {
    let context = makeContext(payload: payloadWithBooleanTrue)

    try await context.sut.replaceFlags(from: "[]")

    #expect(await context.sut.getFlagValue(testFlag) == false)
    verify(context.prefs, times(1)).remove(forKey: equal(to: Prefs.Key.featureFlagsPayload))
    verify(context.prefs, times(1)).setValue(any(), forKey: equal(to: Prefs.Key.featureFlagsLastUpdate))
  }

  @Test
  func replaceFlags_WithInvalidPayload_ThrowsAndKeepsCachedValues() async {
    let context = makeContext(payload: payloadWithBooleanTrue)

    await #expect(throws: FlagError.invalidPayload) {
      try await context.sut.replaceFlags(from: "not json")
    }

    #expect(await context.sut.getFlagValue(testFlag) == true)
    verify(context.prefs, times(0)).setValue(any(), forKey: any())
  }

  private struct Context {
    let sut: FlagStoreImpl
    let prefs: MockPrefsController
  }

  /// `setValue` takes `Any?`, which Cuckoo's `equal(to:)` cannot match.
  private func string(_ expected: String) -> ParameterMatcher<Any?> {
    ParameterMatcher { ($0 as? String) == expected }
  }

  private func makeContext(payload: String, lastUpdate: String = "") -> Context {
    let prefs = MockPrefsController()
    let logger = MockLogging()

    stub(prefs) { stub in
      when(stub.getOptionalString(forKey: equal(to: Prefs.Key.featureFlagsPayload))).thenReturn(payload)
      when(stub.getOptionalString(forKey: equal(to: Prefs.Key.featureFlagsLastUpdate))).thenReturn(lastUpdate)
      when(stub.setValue(any(), forKey: any())).thenDoNothing()
      when(stub.remove(forKey: any())).thenDoNothing()
    }
    stub(logger) { stub in
      when(stub.d(any(), file: any(), function: any(), line: any())).thenDoNothing()
      when(stub.e(any(), file: any(), function: any(), line: any())).thenDoNothing()
    }

    return Context(sut: FlagStoreImpl(prefsController: prefs, logger: logger), prefs: prefs)
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

  private let payloadWithDuplicateKey = """
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
        },
        {
          "id": "2",
          "key": "test_feature",
          "l": false,
          "version": 1,
          "type": "BOOLEAN",
          "value": false,
          "strategies": []
        }
      ]
    }
  ]
  """
}
