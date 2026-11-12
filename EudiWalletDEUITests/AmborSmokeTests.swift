//
//  AmborSmokeTests.swift
//  EudiWalletDEUITests
//

import XCTest

/// Proves that the Ambor test stack CI starts on the runner (e2e-wallet-test-tool, native mode) is
/// reachable from the simulator and that the simulator trusts its TLS root: both requests run on the
/// simulator, against the keychain `simctl keychain add-root-cert` was given. No wallet flow runs
/// here; the Ambor-backed UI tests read the same `AMBOR_URL`.
///
/// `AMBOR_URL` and `EUDIPLO_URL` come from the test runner's environment
/// (`TEST_RUNNER_AMBOR_URL=…` on xcodebuild, or the test plan). Both are required: CI always sets
/// them, and locally this class is only meaningful with `scripts/stack-native.sh up` running.
final class AmborSmokeTests: XCTestCase {

  func testAmborIsReady() throws {
    try get(try baseURL("AMBOR_URL"), path: "/health/ready")
  }

  func testEUDIPLOAnswersThroughCaddy() throws {
    try get(try baseURL("EUDIPLO_URL"), path: "/health")
  }

  // MARK: - Helpers

  private func baseURL(_ name: String) throws -> URL {
    guard let value = ProcessInfo.processInfo.environment[name], let url = URL(string: value) else {
      throw XCTSkip("\(name) is not set; the Ambor smoke test needs the stack's URLs")
    }
    return url
  }

  /// Both endpoints answer 200 only when healthy (Ambor's readiness returns 503 otherwise and also
  /// checks EUDIPLO behind it), so the status code is the whole assertion.
  private func get(_ base: URL, path: String) throws {
    let url = base.appendingPathComponent(path)
    final class Outcome: @unchecked Sendable {
      var status: Int?
      var error: Error?
    }
    let outcome = Outcome()
    let finished = expectation(description: "GET \(url.absoluteString)")
    let configuration = URLSessionConfiguration.ephemeral
    configuration.timeoutIntervalForRequest = 15
    URLSession(configuration: configuration).dataTask(with: url) { _, response, error in
      outcome.status = (response as? HTTPURLResponse)?.statusCode
      outcome.error = error
      finished.fulfill()
    }.resume()
    wait(for: [finished], timeout: 20)
    if let error = outcome.error {
      XCTFail("GET \(url.absoluteString) failed: \(error.localizedDescription)")
    }
    XCTAssertEqual(outcome.status, 200, "GET \(url.absoluteString)")
  }
}
