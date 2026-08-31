//
//  AppState.swift
//  logic-core
//

import Combine

public class AppState: ObservableObject {
  public static let shared = AppState()
  @Published public var useSimulatedEIDCard: Bool = false
  private init() {}
}
