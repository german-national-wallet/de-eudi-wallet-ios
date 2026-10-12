/*
 * Copyright (c) 2023 European Commission
 *
 * Licensed under the EUPL, Version 1.2 or - as soon they will be approved by the European
 * Commission - subsequent versions of the EUPL (the "Licence"); You may not use this work
 * except in compliance with the Licence.
 *
 * You may obtain a copy of the Licence at:
 * https://joinup.ec.europa.eu/software/page/eupl
 *
 * Unless required by applicable law or agreed to in writing, software distributed under
 * the Licence is distributed on an "AS IS" basis, WITHOUT WARRANTIES OR CONDITIONS OF
 * ANY KIND, either express or implied. See the Licence for the specific language
 * governing permissions and limitations under the Licence.
 */
import Foundation
import UIKit
import logic_ui
import logic_core
import logic_business
import logic_resources
import feature_common

@Copyable
struct SettingsTabViewState: ViewState {
  let sections: [SettingsTabSectionUIModel]
  let appVersion: String
  let logsUrl: URL?
  let changelogUrl: URL?
  let presentedWebLink: SettingsWebLink?
}

final class SettingsTabViewModel<Router: RouterHost>: ViewModel<Router, SettingsTabViewState> {

  private let interactor: SettingsTabInteractor
  private let configLogic: ConfigLogic

  init(
    router: Router,
    interactor: SettingsTabInteractor,
    configLogic: ConfigLogic
  ) {
    self.interactor = interactor
    self.configLogic = configLogic

    super.init(
      router: router,
      initialState: .init(
        sections: [],
        appVersion: "Version: \(interactor.getAppVersion()) Build: \(interactor.getAppBuildNumber())",
        logsUrl: interactor.retrieveLogFileUrl(),
        changelogUrl: nil,
        presentedWebLink: nil
      )
    )

    setState {
      $0.copy(sections: makeSections())
    }
  }

  private func makeSections() -> [SettingsTabSectionUIModel] {
    [
      .init(
        id: "settingsSupportSection",
        items: [
          .init(
            id: "settingsSupportItem",
            title: .settingsOverviewListSupport,
            leadingIcon: Theme.shared.image.help,
            showDivider: false,
            action: {}()
          )
        ]
      ),
      .init(
        id: "settingsSettingsSection",
        title: .settingsOverviewHeadlineSettings,
        items: [
          .init(
            id: "settingsWalletLossProtectionItem",
            title: .settingsOverviewListRevocation,
            leadingIcon: Theme.shared.image.walletKey,
            showDivider: false,
            action: self.openWalletLossProtection()
          ),
          .init(
            id: "settingsNotificationItem",
            title: .settingsOverviewListNotification,
            leadingIcon: Theme.shared.image.notification,
            trailingIcon: .externalLink,
            showDivider: false,
            action: self.openNotificationSettings()
          )
        ]
      ),
      .init(
        id: "settingsLegalSection",
        title: .settingsOverviewHeadlineLegal,
        items: [
          .init(
            id: "settingsAboutItem",
            title: .settingsOverviewListAboutEudi,
            showDivider: false,
            action: self.openWebLink(AppEnvironment.aboutLink)
          ),
          .init(
            id: "settingsAccessibilityItem",
            title: .settingsOverviewListAccessibility,
            showDivider: false,
            action: self.openWebLink(AppEnvironment.accessibilityStatementLink)
          ),
          .init(
            id: "settingsPrivacyPolicyItem",
            title: .settingsOverviewListPrivacyPolicy,
            showDivider: false,
            action: self.openWebLink(AppEnvironment.privacyPolicyLink)
          ),
          .init(
            id: "settingsTermsItem",
            title: .settingsOverviewListTermsAndConditions,
            showDivider: false,
            action: self.openWebLink(AppEnvironment.termsAndConditionsLink)
          ),
          .init(
            id: "settingsImprintItem",
            title: .settingsOverviewListImpress,
            showDivider: false,
            action: self.openWebLink(AppEnvironment.imprintLink)
          )
        ] + makeDebugItems()
      )
    ]
  }

  private func makeDebugItems() -> [SettingsTabItemUIModel] {
    guard [.DEV, .SANDBOX].contains(configLogic.appBuildVariant) else { return [] }
    return [
      .init(
        id: "settingsRetrieveLogsItem",
        title: .globalRetrieveLogs,
        showDivider: false,
        isShareLink: true,
        action: {}()
      ),
      .init(
        id: "settingsDebugConfigItem",
        title: .custom("Debug config"),
        showDivider: false,
        action: self.openDebugConfig()
      )
    ]
  }

  private func openDebugConfig() {
    router.push(with: .featureDashboardModule(.debugConfig))
  }

  private func openWalletLossProtection() {
    router.push(with: .featureDashboardModule(.walletLossProtection))
  }

  private func openNotificationSettings() {
    UIApplication.shared.openAppNotificationSettings()
  }

  private func openWebLink(_ url: URL?) {
    guard let url else { return }
    setState { $0.copy(presentedWebLink: SettingsWebLink(url: url)) }
  }

  func dismissWebLink() {
    setState { $0.copy(presentedWebLink: nil) }
  }

  func updatePin() {
    router.push(
      with: .featureCommonModule(
        .quickPin(
          config: QuickPinUiConfig(
            flow: .update
          )
        )
      )
    )
  }
}
