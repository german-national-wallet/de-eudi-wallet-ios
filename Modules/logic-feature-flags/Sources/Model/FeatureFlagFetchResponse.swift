//
//  FeatureFlagFetchResponse.swift
//  logic-feature-flag
//

import Foundation

struct FeatureFlagFetchResponse: Decodable {
  let id: String
  let features: [RawFlag]
}
