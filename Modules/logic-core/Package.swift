// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "logic-core",
  platforms: [.iOS(.v16)],
  products: [
    .library(
      name: "logic-core",
      targets: ["logic-core"])
  ],
  dependencies: [
    .package(
      url: "https://github.com/german-national-wallet/de-eudi-lib-ios-wallet-kit.git",
      revision: "01d673c8804be1254b1e29c9cc66cddc822af216"
    ),
    .package(
      name: "logic-resources",
      path: "../logic-resources"
    ),
    .package(
      name: "logic-api",
      path: "../logic-api"
    ),
    .package(
      name: "logic-business",
      path: "../logic-business"
    ),
    .package(
      name: "logic-feature-flags",
      path: "../logic-feature-flags"
    ),
    .package(
      name: "logic-test",
      path: "../logic-test"
    )
  ],
  targets: [
    .target(
      name: "logic-core",
      dependencies: [
        "logic-resources",
        "logic-business",
        "logic-api",
        "logic-feature-flags",
        .product(
          name: "EudiWalletKit",
          package: "de-eudi-lib-ios-wallet-kit"
        )
      ],
      path: "./Sources"
    ),
    .testTarget(
      name: "logic-core-tests",
      dependencies: [
        "logic-core",
        "logic-business",
        "logic-api",
        "logic-feature-flags",
        "logic-test",
        .product(
          name: "EudiWalletKit",
          package: "de-eudi-lib-ios-wallet-kit"
        )
      ],
      path: "./Tests"
    )
  ]
)
