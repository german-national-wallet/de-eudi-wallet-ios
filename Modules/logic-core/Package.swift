// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "logic-core",
  platforms: [.iOS(.v17)],
  products: [
    .library(
      name: "logic-core",
      targets: ["logic-core"])
  ],
  dependencies: [
    .package(
      url: "https://github.com/german-national-wallet/de-eudi-lib-ios-wallet-kit.git",
      revision: "59e1e8cc2dde82734b6059a17754fb7a1016e171"
    ),
    .package(
      url: "https://github.com/eu-digital-identity-wallet/eudi-lib-ios-openid4vp-swift.git",
      exact: "0.43.2"
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
      name: "logic-storage",
      path: "../logic-storage"
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
        "logic-storage",
        .product(
          name: "EudiWalletKit",
          package: "de-eudi-lib-ios-wallet-kit"
        ),
        .product(
            name: "OpenID4VP",
            package: "eudi-lib-ios-openid4vp-swift"
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
        "logic-storage",
        "logic-test",
        .product(
          name: "EudiWalletKit",
          package: "de-eudi-lib-ios-wallet-kit"
        ),
        .product(
            name: "OpenID4VP",
            package: "eudi-lib-ios-openid4vp-swift"
        )
      ],
      path: "./Tests"
    )
  ]
)
