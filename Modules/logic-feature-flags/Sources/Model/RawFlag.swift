//
//  RawFlag.swift
//  logic-feature-flag
//

import Foundation

struct RawFlag: Decodable {

  enum ValueType: String, Decodable {
    case boolean = "BOOLEAN"
    case string = "STRING"
    case number = "NUMBER"
    case json = "JSON"
  }

  /// Unique feature value entry id from FeatureHub.
  let id: String
  /// Stable feature key used by the app.
  let key: String
  /// Lock status of the feature in the environment.
  let l: Bool
  /// Version of this feature value.
  let version: Int
  /// Value type used for decoding the value field.
  let type: ValueType
  /// Typed feature value consumed by the app.
  let value: FlagValue
  /// Strategy ids affecting this value.
  let strategies: [String]

  enum CodingKeys: String, CodingKey {
    case id
    case key
    case l
    case version
    case type
    case value
    case strategies
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    id = try container.decode(String.self, forKey: .id)
    key = try container.decode(String.self, forKey: .key)
    l = try container.decode(Bool.self, forKey: .l)
    version = try container.decode(Int.self, forKey: .version)
    type = try container.decode(ValueType.self, forKey: .type)
    strategies = try container.decodeIfPresent([String].self, forKey: .strategies) ?? []

    switch type {
    case .boolean:
      value = .bool(try container.decode(Bool.self, forKey: .value))
    case .string:
      value = .string(try container.decode(String.self, forKey: .value))
    case .number:
      if let intValue = try? container.decode(Int.self, forKey: .value) {
        value = .number(Double(intValue))
      } else {
        value = .number(try container.decode(Double.self, forKey: .value))
      }
    case .json:
      value = .json(try container.decode(String.self, forKey: .value))
    }
  }
}
