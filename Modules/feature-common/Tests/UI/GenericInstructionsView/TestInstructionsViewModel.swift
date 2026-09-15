//
//  TestInstructionsViewModel.swift
//  feature-common
//
//  Created by Pankaj Sachdeva on 18.07.25.
//

@testable import feature_common
@testable import logic_test
@testable import feature_test


final class TestInstructionsViewModel: XCTestCase {

  @MainActor func test_init_withCorrectConfig_shouldInitializeState() {
    let mockRouter = MockRouterHost()
    let config = UIConfig.InstructionsViewConfig(
      mainTitle: .setupPinTitle,
      message: .setupPinMessage,
      image: nil,
      illustrationWidthFactor: 0.5,
      primaryButtonTitle: .continueTitle,
      primaryRoute: .featureStartupModule(.startup)
    )

    let viewModel = InstructionsViewModel(router: mockRouter, config: config)
    XCTAssertEqual(viewModel.viewState.config.mainTitle, .setupPinTitle)
  }

  @MainActor func test_secondaryButtonTapped_shouldToggleState() {
      let mockRouter = MockRouterHost()
      let config = UIConfig.InstructionsViewConfig(
        mainTitle: .setupPinTitle,
        message: .setupPinMessage,
        image: nil,
        illustrationWidthFactor: 0.5,
        primaryButtonTitle: .continueTitle,
        primaryRoute: .featureStartupModule(.startup),
        onClose: {}
      )

      let viewModel = InstructionsViewModel(router: mockRouter, config: config)

      XCTAssertFalse(viewModel.isSecondaryButtonSheetOpen)

      viewModel.secondaryButtonTapped()
      XCTAssertTrue(viewModel.isSecondaryButtonSheetOpen)

      viewModel.secondaryButtonTapped()
      XCTAssertFalse(viewModel.isSecondaryButtonSheetOpen)
    }
}
