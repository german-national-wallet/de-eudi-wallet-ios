//
//  FlagValue.swift
//  logic-feature-flag
//

import Foundation
import logic_business

enum FlagValue: Sendable, Equatable {
  case bool(Bool)
  case string(String)
  case number(Double)
  case json(String)

  /// Decodes a FeatureHub payload into the flag values the app reads.
  static func decodeAll(from json: String, logger: Logging? = nil) throws -> [String: FlagValue] {
    guard !json.isEmpty else {
      return [:]
    }

    let environments: [FeatureFlagFetchResponse]
    do {
      environments = try JSONDecoder().decode([FeatureFlagFetchResponse].self, from: Data(json.utf8))
    } catch {
      throw FlagError.invalidPayload
    }

    let skippedKeys = environments.flatMap(\.skippedFeatureKeys)
    if !skippedKeys.isEmpty {
      logger?.e("Feature flags skipped, invalid entries: \(skippedKeys)")
    }

    let flags = environments.flatMap(\.features)

    guard Set(flags.map(\.key)).count == flags.count else {
      throw FlagError.duplicateKey
    }

    return Dictionary(uniqueKeysWithValues: flags.map { ($0.key, $0.value) })
  }

  func converted<T>(to type: T.Type) -> T? {
    switch self {
    case .bool(let boolValue):
      return boolValue as? T
    case .string(let stringValue):
      return stringValue as? T
    case .json(let jsonValue):
      return jsonValue as? T
    case .number(let numberValue):
      if type == Double.self {
        return numberValue as? T
      }
      if type == Float.self {
        return Float(numberValue) as? T
      }
      if type == Int.self, numberValue.rounded() == numberValue {
        return Int(numberValue) as? T
      }
      return nil
    }
  }
}
