// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "logic-analytics",
  platforms: [.iOS(.v16)],
  products: [
    .library(
      name: "logic-analytics",
      targets: ["logic-analytics"])
  ],
  dependencies: [
    .package(
      name: "logic-business",
      path: "../logic-business"
    ),
    .package(url: "https://github.com/open-telemetry/opentelemetry-swift.git", from: "2.1.0"),
    .package(url: "https://github.com/open-telemetry/opentelemetry-swift-core.git", from: "2.1.0")
  ],
  targets: [
    .target(
      name: "logic-analytics",
      dependencies: [
        "logic-business",
        .product(name: "OpenTelemetryApi", package: "opentelemetry-swift-core"),
        .product(name: "OpenTelemetrySdk", package: "opentelemetry-swift-core"),
        .product(name: "StdoutExporter", package: "opentelemetry-swift-core"),
        .product(name: "OpenTelemetryProtocolExporterHTTP", package: "opentelemetry-swift"),
        .product(name: "OpenTelemetryProtocolExporter", package: "opentelemetry-swift"),
        .product(name: "URLSessionInstrumentation", package: "opentelemetry-swift")
      ],
      path: "./Sources"
    )
  ]
)
