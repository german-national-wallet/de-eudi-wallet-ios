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
import XCTest
import logic_core
import OrderedCollections
@testable import feature_dashboard
@testable import logic_test
@testable import feature_test

final class TestDashboardCredentialInteractor: EudiTest {

  private var interactor: DashboardInteractor!
  private var walletKitController: MockWalletKitController!
  private var prefsController: MockPrefsController!

  override func setUp() {
    walletKitController = MockWalletKitController()
    prefsController = MockPrefsController()
    interactor = DashboardInteractorImpl(
      walletKitController: walletKitController,
      prefsController: prefsController
    )
  }

  override func tearDown() {
    interactor = nil
    walletKitController = nil
    prefsController = nil
  }

  func testClearFirstRunFlag_WhenCalled_ThenRemovesRunAtLeastOnceKey() {
    stub(prefsController) { mock in
      when(mock.remove(forKey: any())).thenDoNothing()
    }

    interactor.clearFirstRunFlag()

    verify(prefsController).remove(forKey: equal(to: .runAtLeastOnce))
    verify(prefsController).remove(forKey: equal(to: .isPinInitialized))
  }
}
