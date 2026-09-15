//
//  FlagValueTests.swift
//  logic-feature-flag
//

import Foundation
import Testing
@testable import logic_feature_flags

struct FlagValueTests {

  @Test
  func converted_ReturnsValue_WhenTypeMatches() {
    #expect(FlagValue.bool(true).converted(to: Bool.self) == true)
    #expect(FlagValue.string("wallet").converted(to: String.self) == "wallet")
    #expect(FlagValue.json("{}").converted(to: String.self) == "{}")
    #expect(FlagValue.number(1.5).converted(to: Double.self) == 1.5)
  }

  @Test
  func converted_ReturnsNil_WhenTypeDoesNotMatch() {
    #expect(FlagValue.bool(true).converted(to: String.self) == nil)
    #expect(FlagValue.string("wallet").converted(to: Bool.self) == nil)
    #expect(FlagValue.number(1.5).converted(to: String.self) == nil)
  }

  @Test
  func converted_NarrowsNumbers_ToFloat() {
    #expect(FlagValue.number(1.5).converted(to: Float.self) == Float(1.5))
  }

  @Test
  func converted_NarrowsNumbers_ToInt_OnlyWhenThereIsNoFraction() {
    #expect(FlagValue.number(3).converted(to: Int.self) == 3)
    #expect(FlagValue.number(3.5).converted(to: Int.self) == nil)
  }

  @Test
  func decodeAll_ReturnsNoValues_WhenPayloadIsEmpty() throws {
    #expect(try FlagValue.decodeAll(from: "").isEmpty)
  }

  @Test
  func decodeAll_ReturnsNoValues_WhenPayloadHasNoEnvironments() throws {
    #expect(try FlagValue.decodeAll(from: "[]").isEmpty)
  }

  @Test
  func decodeAll_DecodesEveryValueType() throws {
    let values = try FlagValue.decodeAll(from: payloadWithEveryType)

    #expect(values["bool_feature"] == .bool(true))
    #expect(values["string_feature"] == .string("wallet"))
    #expect(values["number_feature"] == .number(42))
    #expect(values["json_feature"] == .json("{\"a\":1}"))
  }

  @Test
  func decodeAll_FlattensFeaturesOfAllEnvironments() throws {
    let values = try FlagValue.decodeAll(from: payloadWithTwoEnvironments)

    #expect(values.count == 2)
    #expect(values["first_feature"] == .bool(true))
    #expect(values["second_feature"] == .bool(false))
  }

  @Test
  func decodeAll_Throws_WhenPayloadIsNotValidJSON() {
    #expect(throws: FlagError.invalidPayload) {
      try FlagValue.decodeAll(from: "not json")
    }
  }

  @Test
  func decodeAll_Throws_WhenTheSameKeyAppearsTwice() {
    #expect(throws: FlagError.duplicateKey) {
      try FlagValue.decodeAll(from: payloadWithDuplicateKey)
    }
  }

  private func environment(id: String, features: String) -> String {
    """
    {
      "id": "\(id)",
      "features": [\(features)]
    }
    """
  }

  private func feature(id: String, key: String, type: String, value: String) -> String {
    """
    {
      "id": "\(id)",
      "key": "\(key)",
      "l": false,
      "version": 1,
      "type": "\(type)",
      "value": \(value),
      "strategies": []
    }
    """
  }

  private var payloadWithEveryType: String {
    let features = [
      feature(id: "1", key: "bool_feature", type: "BOOLEAN", value: "true"),
      feature(id: "2", key: "string_feature", type: "STRING", value: "\"wallet\""),
      feature(id: "3", key: "number_feature", type: "NUMBER", value: "42"),
      feature(id: "4", key: "json_feature", type: "JSON", value: "\"{\\\"a\\\":1}\"")
    ].joined(separator: ",")
    return "[\(environment(id: "env-id", features: features))]"
  }

  private var payloadWithTwoEnvironments: String {
    let first = environment(id: "first-env", features: feature(id: "1", key: "first_feature", type: "BOOLEAN", value: "true"))
    let second = environment(id: "second-env", features: feature(id: "2", key: "second_feature", type: "BOOLEAN", value: "false"))
    return "[\(first),\(second)]"
  }

  private var payloadWithDuplicateKey: String {
    let features = [
      feature(id: "1", key: "test_feature", type: "BOOLEAN", value: "true"),
      feature(id: "2", key: "test_feature", type: "BOOLEAN", value: "false")
    ].joined(separator: ",")
    return "[\(environment(id: "env-id", features: features))]"
  }
}
