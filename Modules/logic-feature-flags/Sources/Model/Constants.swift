//
//  Constants.swift
//  logic-feature-flag
//

import Foundation

enum Constants {

  enum Env {
    static let file = ".env"
    static let apiKey = "FEATURE_FLAG_API_KEY"
  }

  enum API {
    static let baseURLKey = "FEATURE_FLAG_BASE_URL"
    static let featuresPath = "features"
    static let apiKeyQueryParam = "apiKey"
  }

  enum Cache {
    static let maxAgeHours = 24
  }
}
