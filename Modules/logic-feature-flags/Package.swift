// swift-tools-version: 5.9

import PackageDescription

let package = Package(
  name: "logic-feature-flags",
  platforms: [.iOS(.v16)],
  products: [
    .library(
      name: "logic-feature-flags",
      targets: ["logic-feature-flags"]
    )
  ],
  dependencies: [
    .package(name: "logic-business", path: "../logic-business"),
    .package(name: "logic-api", path: "../logic-api"),
    .package(name: "logic-test", path: "../logic-test")
  ],
  targets: [
    .target(
      name: "logic-feature-flags",
      dependencies: [
        "logic-business",
        "logic-api"
      ],
      path: "./Sources"
    ),
    .testTarget(
      name: "logic-feature-flags-tests",
      dependencies: [
        "logic-feature-flags",
        "logic-business",
        "logic-test"
      ],
      path: "./Tests/Sources"
    )
  ]
)
