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
      revision: "ffa947404a6974244e253e0735b6690980257691"
    ),
    .package(url: "https://github.com/eu-digital-identity-wallet/eudi-lib-ios-openid4vp-swift.git", exact: "0.44.1"),
    .package(url: "https://github.com/eu-digital-identity-wallet/eudi-lib-ios-openid4vci-swift.git", exact: "0.55.6"),
    .package(url: "https://github.com/apple/swift-asn1.git", exact: "1.7.3"),
    .package(url: "https://github.com/apple/swift-certificates.git", exact: "1.21.0"),
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
        ),
        .product(
            name: "OpenID4VCI",
            package: "eudi-lib-ios-openid4vci-swift"
        ),
        .product(name: "SwiftASN1", package: "swift-asn1"),
        .product(name: "X509", package: "swift-certificates")
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
        ),
        .product(
            name: "OpenID4VCI",
            package: "eudi-lib-ios-openid4vci-swift"
        ),
        .product(name: "SwiftASN1", package: "swift-asn1"),
        .product(name: "X509", package: "swift-certificates")
      ],
      path: "./Tests",
      resources: [.process("Trust/Fixtures")]
    )
  ]
)
