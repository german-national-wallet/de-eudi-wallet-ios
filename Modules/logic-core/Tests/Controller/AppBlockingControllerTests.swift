//
//  AppBlockingControllerTests.swift
//  logic-core
//
//  Created by Tamas Dancsi on 18.05.26.
//

import Foundation
import Testing

@testable import logic_business
@testable import logic_core
@testable import logic_feature_flags

struct AppBlockingControllerTests {

  @Test
  func blockingState_WhenCurrentVersionIsBelowMinimum_BlocksApp() async {
    let sut = makeSUT(appVersion: "1.0.0", minimumAppVersion: "1.0.1")

    let state = await sut.blockingState(for: [.minimumAppVersion])

    #expect(state == .minimumAppVersion)
  }

  @Test
  func blockingState_WhenCurrentVersionEqualsMinimum_AllowsApp() async {
    let sut = makeSUT(appVersion: "1.0.0", minimumAppVersion: "1.0.0")

    let state = await sut.blockingState(for: [.minimumAppVersion])

    #expect(state == nil)
  }

  @Test
  func blockingState_WhenCurrentVersionIsAboveMinimum_AllowsApp() async {
    let sut = makeSUT(appVersion: "1.0.1", minimumAppVersion: "1.0.0")

    let state = await sut.blockingState(for: [.minimumAppVersion])

    #expect(state == nil)
  }

  @Test
  func blockingState_WhenMinimumVersionIsInvalid_AllowsApp() async {
    let sut = makeSUT(appVersion: "1.0.0", minimumAppVersion: "latest")

    let state = await sut.blockingState(for: [.minimumAppVersion])

    #expect(state == nil)
  }

  @Test
  func blockingState_WhenMinimumVersionRuleIsNotRequested_AllowsApp() async {
    let sut = makeSUT(appVersion: "1.0.0", minimumAppVersion: "9.0.0")

    let state = await sut.blockingState(for: [])

    #expect(state == nil)
  }

  @Test
  func refreshFeatureFlagsIfNeeded_AsksRepositoryToRefresh() async {
    let repository = AppBlockingFeatureFlagRepositorySpy()
    let sut = makeSUT(featureFlagRepository: repository)

    await sut.refreshFeatureFlagsIfNeeded()

    #expect(repository.refreshCallCount == 1)
  }

  private func makeSUT(
    appVersion: String = "1.0.0",
    minimumAppVersion: String = "0.0.0",
    featureFlagRepository: AppBlockingFeatureFlagRepositorySpy? = nil
  ) -> AppBlockingControllerImpl {
    let repository = featureFlagRepository ?? AppBlockingFeatureFlagRepositorySpy()
    repository.minimumAppVersion = minimumAppVersion
    return AppBlockingControllerImpl(
      configLogic: AppBlockingConfigLogicStub(appVersion: appVersion),
      featureFlagRepository: repository,
      prefsController: PrefsControllerImpl()
    )
  }
}

private final class AppBlockingConfigLogicStub: ConfigLogic, @unchecked Sendable {

  let appVersion: String

  init(appVersion: String) {
    self.appVersion = appVersion
  }

  var walletHostUrl: String { "" }
  var appBuildType: AppBuildType { .DEBUG }
  var appBuildVariant: AppBuildVariant { .DEV }
  var changelogUrl: URL? { nil }
  var vciIssuerName: String? { nil }
  var vciIssuerURL: String? { nil }
  var walletOTLPURL: String { "" }
  var pidMsoMdocConfigId: String { "pid-mso-mdoc" }
  var pidSdJwtConfigId: String { "pid-sd-jwt" }
}

private final class AppBlockingFeatureFlagRepositorySpy: FeatureFlagRepository, @unchecked Sendable {

  var minimumAppVersion = "0.0.0"
  private(set) var refreshCallCount = 0

  func getFlagValue<T>(_ flag: FeatureFlag<T>) async -> T {
    if flag.key == FeatureFlag<String>.minimumAppVersion.key,
       let value = minimumAppVersion as? T {
      return value
    }
    return flag.defaultValue
  }

  func refreshFlagsIfNeeded() async {
    refreshCallCount += 1
  }
}
