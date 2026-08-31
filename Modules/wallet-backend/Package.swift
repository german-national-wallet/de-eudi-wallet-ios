// swift-tools-version: 5.9

import PackageDescription

let package = Package(
  name: "wallet-backend",
  platforms: [.iOS(.v16)],
  products: [
    .library(
      name: "wallet-backend",
      targets: ["wallet-backend"]
    )
  ],
  dependencies: [
    .package(name: "logic-api", path: "../logic-api"),
    .package(name: "logic-business", path: "../logic-business"),
    .package(name: "logic-core", path: "../logic-core"),
    .package(name: "logic-test", path: "../logic-test"),
    .package(url: "https://github.com/Swinject/Swinject.git", from: "2.8.4")
  ],
  targets: [
    .target(
      name: "wallet-backend",
      dependencies: [
        "logic-api",
        "logic-business",
        "logic-core",
        "Swinject"
      ],
      path: "./Sources"
    ),
    .testTarget(
      name: "wallet-backend-tests",
      dependencies: [
        "wallet-backend",
        "logic-test"
      ],
      path: "./Tests"
    )
  ]
)
