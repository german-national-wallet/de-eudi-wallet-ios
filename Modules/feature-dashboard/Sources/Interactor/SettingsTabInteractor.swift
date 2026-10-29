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
import logic_core
import logic_business
import logic_resources
import Combine

public protocol SettingsTabInteractor: Sendable {
  func getAppVersion() -> String
  func getAppBuildNumber() -> String
  func retrieveLogFileUrl() -> URL?
  func retrieveRevocationCode() throws -> String?
}

final class SettingsTabInteractorImpl: SettingsTabInteractor {

  private let walletController: WalletKitController
  private let configLogic: ConfigLogic
  private let secureEnclaveController: SecureEnclaveController

  init(
    walletController: WalletKitController,
    configLogic: ConfigLogic,
    secureEnclaveController: SecureEnclaveController
  ) {
    self.walletController = walletController
    self.configLogic = configLogic
    self.secureEnclaveController = secureEnclaveController
  }

  public func getAppVersion() -> String {
    return configLogic.appVersion
  }

  func getAppBuildNumber() -> String {
    Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? ""
  }

  func retrieveLogFileUrl() -> URL? {
    return walletController.retrieveLogFileUrl()
  }

  func retrieveRevocationCode() throws -> String? {
    guard let code = try secureEnclaveController.retrieveDecryptedString(keyTag: .wpbWiRevocationCode),
          !code.isEmpty else {
      return nil
    }
    return code
  }
}
