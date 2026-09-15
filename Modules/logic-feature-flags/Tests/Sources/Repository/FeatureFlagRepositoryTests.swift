//
//  FeatureFlagRepositoryTests.swift
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

struct FeatureFlagRepositoryTests {

  private struct Context {
    let sut: FeatureFlagRepositoryImpl
    let prefs: MockPrefsController
    let networkManager: FakeNetworkManager
  }

  private let isoDateFormatter: ISO8601DateFormatter = {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    return formatter
  }()

  private let testFlag = FeatureFlag<Bool>(key: "test_feature", defaultValue: false)

  private let mdocFallback = "pid-mso-mdoc-xcconfig"

  @Test
  func getFlagValue_ReturnsCachedValue_WhenPayloadWasRestored() async {
    let context = makeContext(cachedPayload: payloadWithBooleanTrue, payloadFromApi: payloadWithBooleanTrue)
    let value = await context.sut.getFlagValue(testFlag)
    #expect(value == true)
  }

  @Test
  func refreshFlagsIfNeeded_RefreshesAndPersists_WhenFirstRun() async {
    let context = makeContext(cachedPayload: "", payloadFromApi: payloadWithBooleanTrue)

    await context.sut.refreshFlagsIfNeeded()

    #expect(context.networkManager.executeCallCount == 1)
    verify(context.prefs, times(1)).setValue(any(), forKey: equal(to: Prefs.Key.featureFlagsPayload))
    verify(context.prefs, times(1)).setValue(any(), forKey: equal(to: Prefs.Key.featureFlagsLastUpdate))

    let value = await context.sut.getFlagValue(testFlag)
    #expect(value == true)
  }

  @Test
  func flagUpdateFlow_ReturnsCached_RefreshesAfterStale_ReturnsUpdated() async {
    let context = makeContext(
      cachedPayload: payloadWithBooleanFalse,
      lastUpdate: isoDateFormatter.string(from: Date().addingTimeInterval(-48 * 3600)),
      payloadFromApi: payloadWithBooleanTrue
    )

    let cachedValue = await context.sut.getFlagValue(testFlag)
    #expect(cachedValue == false)

    await context.sut.refreshFlagsIfNeeded()

    let refreshedValue = await context.sut.getFlagValue(testFlag)
    #expect(refreshedValue == true)
  }

  @Test
  func getNonBlankStringValue_PrefersServerValue_WhenPresentAndNonBlank() async {
    let context = makeContext(cachedPayload: mdocConfigPayload(value: "pid-mso-mdoc-server"), payloadFromApi: "")
    let value = await context.sut.getNonBlankStringValue(.pidMsoMdocConfigId(fallback: mdocFallback))
    #expect(value == "pid-mso-mdoc-server")
  }

  @Test
  func getNonBlankStringValue_UsesFallback_WhenKeyAbsent() async {
    let context = makeContext(cachedPayload: payloadWithBooleanTrue, payloadFromApi: "")
    let value = await context.sut.getNonBlankStringValue(.pidMsoMdocConfigId(fallback: mdocFallback))
    #expect(value == mdocFallback)
  }

  @Test
  func getNonBlankStringValue_UsesFallback_WhenValueIsBlank() async {
    let context = makeContext(cachedPayload: mdocConfigPayload(value: ""), payloadFromApi: "")
    let value = await context.sut.getNonBlankStringValue(.pidMsoMdocConfigId(fallback: mdocFallback))
    #expect(value == mdocFallback)
  }

  @Test
  func getNonBlankStringValue_UsesFallback_WhenValueIsWhitespaceOnly() async {
    let context = makeContext(cachedPayload: mdocConfigPayload(value: "   "), payloadFromApi: "")
    let value = await context.sut.getNonBlankStringValue(.pidMsoMdocConfigId(fallback: mdocFallback))
    #expect(value == mdocFallback)
  }

  private func makeContext(cachedPayload: String, lastUpdate: String = "", payloadFromApi: String) -> Context {
    let prefs = MockPrefsController()
    let logger = MockLogging()
    let networkManager = FakeNetworkManager()

    stub(prefs) { stub in
      when(stub.getOptionalString(forKey: equal(to: Prefs.Key.featureFlagsPayload))).thenReturn(cachedPayload)
      when(stub.getOptionalString(forKey: equal(to: Prefs.Key.featureFlagsLastUpdate))).thenReturn(lastUpdate)
      when(stub.setValue(any(), forKey: any())).thenDoNothing()
      when(stub.remove(forKey: any())).thenDoNothing()
    }
    stub(logger) { stub in
      when(stub.d(any(), file: any(), function: any(), line: any())).thenDoNothing()
      when(stub.e(any(), file: any(), function: any(), line: any())).thenDoNothing()
    }
    networkManager.mockResponse = NetworkResponse(data: Data(payloadFromApi.utf8), headers: nil)

    let sut = FeatureFlagRepositoryImpl(
      prefsController: prefs,
      logger: logger,
      networkManager: networkManager
    )
    return Context(sut: sut, prefs: prefs, networkManager: networkManager)
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

  private func mdocConfigPayload(value: String) -> String {
    """
    [
      {
        "id": "env-id",
        "features": [
          {
            "id": "1",
            "key": "credential_configuration_id_mdoc",
            "l": false,
            "version": 1,
            "type": "STRING",
            "value": "\(value)",
            "strategies": []
          }
        ]
      }
    ]
    """
  }

  private let payloadWithBooleanFalse = """
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
          "value": false,
          "strategies": []
        }
      ]
    }
  ]
  """
}
