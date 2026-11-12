//
//  ImageAssetAdditionsTests.swift
//  logic-ui
//
//  Created by Ameen Qadri on 27.07.26.
//

import XCTest
import UIKit
import logic_resources

// Verifies the image assets added for the EAA card designs are present in the
// resources bundle under the exact names ImageManager references.
final class ImageAssetAdditionsTests: XCTestCase {

  func test_backButtonAsset_existsInBundle() {
    XCTAssertNotNil(
      UIImage(named: "back-button", in: .assetsBundle, compatibleWith: nil),
      "Missing 'back-button' asset in the resources bundle"
    )
  }

  func test_activityServiceLinkAssets_existInBundle() {
    for name in ["activity_support", "activity_data_policy", "activity_website", "activity_information", "activity_warning"] {
      XCTAssertNotNil(
        UIImage(named: name, in: .assetsBundle, compatibleWith: nil),
        "Missing '\(name)' asset in the resources bundle"
      )
    }
  }

  func test_arrowForwardAsset_existsInBundle() {
    XCTAssertNotNil(
      UIImage(named: "arrow-forward", in: .assetsBundle, compatibleWith: nil),
      "Missing 'arrow-forward' asset in the resources bundle"
    )
  }

  func test_credentialTeaserCardsAsset_existsInBundle() {
    XCTAssertNotNil(
      UIImage(named: "credential_teaser_cards", in: .assetsBundle, compatibleWith: nil),
      "Missing 'credential_teaser_cards' asset in the resources bundle"
    )
  }

  func test_dYouWordmarkAsset_existsInBundle() {
    XCTAssertNotNil(
      UIImage(named: "d_you_wordmark", in: .assetsBundle, compatibleWith: nil),
      "Missing 'd_you_wordmark' asset in the resources bundle"
    )
  }
}
