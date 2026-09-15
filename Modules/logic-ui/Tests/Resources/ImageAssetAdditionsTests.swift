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

  func test_arrowForwardAsset_existsInBundle() {
    XCTAssertNotNil(
      UIImage(named: "arrow-forward", in: .assetsBundle, compatibleWith: nil),
      "Missing 'arrow-forward' asset in the resources bundle"
    )
  }
}
