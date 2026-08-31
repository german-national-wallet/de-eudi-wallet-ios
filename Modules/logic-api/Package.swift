// swift-tools-version: 5.9

import PackageDescription

let package = Package(
  name: "logic-api",
  platforms: [.iOS(.v16)],
  products: [
    .library(
      name: "logic-api",
      targets: ["logic-api"])
  ],
  dependencies: [
    .package(url: "https://github.com/Alamofire/Alamofire.git", from: "5.6.0"),
    .package(url: "https://github.com/thebarndog/swift-dotenv.git", from: "2.0.0"),
    .package(name: "logic-business", path: "../logic-business"),
    .package(name: "logic-analytics", path: "../logic-analytics"),
    .package(name: "logic-test", path: "../logic-test")
  ],
  targets: [
    .target(
      name: "logic-api",
      dependencies: [
        "logic-business",
        "logic-analytics",
        .product(name: "SwiftDotenv", package: "swift-dotenv"),
        .product(name: "Alamofire", package: "Alamofire")
      ],
      path: "./Sources"
    ),
    .testTarget(
      name: "logic-api-tests",
      dependencies: [
        "logic-api",
        "logic-test"
      ],
      path: "./Tests"
    )
  ]
)
