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

public protocol DashboardInteractor: Sendable {
  func getWalletKitController() -> WalletKitController
  func getPIDDocument() throws -> DocClaimsDecodable?
  func deleteDocument(with id: String) async throws
  func getAdditionalDocuments() throws -> [DocClaimsDecodable]?
  func clearFirstRunFlag()
}

final class DashboardInteractorImpl: DashboardInteractor {
  private let walletKitController: WalletKitController
  private let prefsController: PrefsController
  
  init(
    walletKitController: WalletKitController,
    prefsController: PrefsController
  ) {
    self.walletKitController = walletKitController
    self.prefsController = prefsController
  }

  func getWalletKitController() -> WalletKitController {
    self.walletKitController
  }
  
  func getPIDDocument() throws -> DocClaimsDecodable? {
    walletKitController.fetchIssuedDocuments(with: [.mDocPid]).last
  }
  
  func clearFirstRunFlag() {
    prefsController.remove(forKey: .runAtLeastOnce)
    prefsController.remove(forKey: .isPinInitialized)
  }
  
  func deleteDocument(with id: String) async throws {
    try await walletKitController.deleteDocument(with: id, status: .issued)
    try await walletKitController.clearDocuments(status: .pending)
  }
  
  func getAdditionalDocuments() throws -> [DocClaimsDecodable]? {
    walletKitController.fetchIssuedDocuments(excluded: [.mDocPid, .sdJwtPid])
  }
}
