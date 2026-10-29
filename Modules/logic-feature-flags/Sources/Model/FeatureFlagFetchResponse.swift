//
//  FeatureFlagFetchResponse.swift
//  logic-feature-flag
//

import Foundation

struct FeatureFlagFetchResponse: Decodable {
  let id: String
  let features: [RawFlag]
  let skippedFeatureKeys: [String]

  enum CodingKeys: String, CodingKey {
    case id
    case features
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    id = try container.decode(String.self, forKey: .id)

    var featuresContainer = try container.nestedUnkeyedContainer(forKey: .features)
    var decodedFeatures: [RawFlag] = []
    var skippedKeys: [String] = []
    while !featuresContainer.isAtEnd {
      if let feature = try? featuresContainer.decode(RawFlag.self) {
        decodedFeatures.append(feature)
      } else {
        let skipped = try featuresContainer.decode(SkippedFeature.self)
        skippedKeys.append(skipped.key ?? "unknown")
      }
    }
    features = decodedFeatures
    skippedFeatureKeys = skippedKeys
  }
}

private struct SkippedFeature: Decodable {
  let key: String?

  enum CodingKeys: String, CodingKey {
    case key
  }

  init(from decoder: Decoder) throws {
    key = try? decoder.container(keyedBy: CodingKeys.self).decodeIfPresent(String.self, forKey: .key)
  }
}
