//
//  StringExtensionsTests.swift
//  logic-business
//
//  Created by Tamas Dancsi on 19.11.25.
//

@testable import logic_business
@testable import logic_test

final class StringExtensionsTests: XCTestCase {

    func testNormalizedHTTPHeaderKey() {
        XCTAssertEqual("traceparent".normalizedHTTPHeaderKey, "traceparent")
        XCTAssertEqual("Server".normalizedHTTPHeaderKey, "server")
        XCTAssertEqual("x-trace-id".normalizedHTTPHeaderKey, "x_trace_id")
        XCTAssertEqual("Strict-Transport-Security".normalizedHTTPHeaderKey, "strict_transport_security")
        XCTAssertEqual("Cache-Control".normalizedHTTPHeaderKey, "cache_control")
        XCTAssertEqual("Content-Length".normalizedHTTPHeaderKey, "content_length")
        XCTAssertEqual("Content-Type".normalizedHTTPHeaderKey, "content_type")
        XCTAssertEqual("x-envoy-upstream-service-time".normalizedHTTPHeaderKey, "x_envoy_upstream_service_time")
        XCTAssertEqual("Set-Cookie".normalizedHTTPHeaderKey, "set_cookie")
        XCTAssertEqual("Transfer-Encoding".normalizedHTTPHeaderKey, "transfer_encoding")
        XCTAssertEqual("DPoP".normalizedHTTPHeaderKey, "dpop")
        XCTAssertEqual("dpop-nonce".normalizedHTTPHeaderKey, "dpop_nonce")
        XCTAssertEqual("X-Rwscd-Account-Id".normalizedHTTPHeaderKey, "x_rwscd_account_id")
        XCTAssertEqual("Authorization".normalizedHTTPHeaderKey, "authorization")
        XCTAssertEqual("Location".normalizedHTTPHeaderKey, "location")
    }

    func testToISO8601DurationMinutes_ParsesPT10M() {
        XCTAssertEqual("PT10M".minutesFromISO8601DurationString(), 10)
    }

    func testToISO8601DurationMinutes_ParsesDayHourMinute() {
        XCTAssertEqual("P1DT2H30M".minutesFromISO8601DurationString(), 1590)
    }

    func testToISO8601DurationMinutes_ParsesLegacyDT10M() {
        XCTAssertEqual("DT10M".minutesFromISO8601DurationString(), 10)
    }

    func testToISO8601DurationMinutes_ReturnsNilForInvalidFormat() {
        XCTAssertNil("10m".minutesFromISO8601DurationString())
    }
}
