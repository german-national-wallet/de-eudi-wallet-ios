// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "logic-ui",
  platforms: [.iOS(.v16)],
  products: [
    .library(
      name: "logic-ui",
      targets: ["logic-ui"]
    )
  ],
  dependencies: [
    .package(
      name: "logic-core",
      path: "../logic-core"
    ),
    .package(
      name: "logic-business",
      path: "../logic-business"
    ),
    .package(
      name: "logic-analytics",
      path: "../logic-analytics"
    ),
    .package(
      name: "logic-resources",
      path: "../logic-resources"
    ),
    .package(
      url: "https://github.com/canopas/UIPilot.git",
      from: "2.0.0"
    ),
    .package(
      url: "https://github.com/twostraws/CodeScanner",
      from: "2.4.1"
    ),
    .package(
      url: "https://github.com/markiv/SwiftUI-Shimmer.git",
      from: "1.4.0"
    ),
    .package(
      url: "https://github.com/AndreaMiotto/PartialSheet.git",
      from: "3.1.1"
    ),
    .package(
        name: "logic-test",
        path: "../logic-test"),
    .package(
        url: "https://github.com/pointfreeco/swift-snapshot-testing.git",
        from: "1.18.9")
  ],
  targets: [
    .target(
      name: "logic-ui",
      dependencies: [
        "logic-business",
        "logic-resources",
        "logic-analytics",
        "logic-core",
        "PartialSheet",
        .product(
          name: "CodeScanner",
          package: "CodeScanner"
        ),
        .product(
          name: "UIPilot",
          package: "UIPilot"
        ),
        .product(
          name: "Shimmer",
          package: "SwiftUI-Shimmer"
        )
      ],
      path: "./Sources",
      resources: [
        .process("DesignSystem/Resources/EUDI Diatype")
      ]
    ),
    .testTarget(
      name: "logic-ui-tests",
      dependencies: [
        "logic-ui",
        "logic-business",
        "logic-core",
        "logic-analytics",
        "logic-resources",
        "logic-test",
        .product(
            name: "SnapshotTesting",
            package: "swift-snapshot-testing"
        )
      ],
      path: "./Tests"
    )
  ]
)
