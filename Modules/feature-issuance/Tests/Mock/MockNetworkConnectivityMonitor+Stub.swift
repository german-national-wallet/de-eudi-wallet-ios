//
//  MockNetworkConnectivityMonitor+Stub.swift
//  feature-issuance
//

import Cuckoo
@testable import logic_api

extension MockNetworkConnectivityMonitor {
  static func stubbed(isOffline: Bool = false) -> MockNetworkConnectivityMonitor {
    let monitor = MockNetworkConnectivityMonitor()
    stub(monitor) { mock in
      when(mock.isOffline.get).thenReturn(isOffline)
    }
    return monitor
  }
}
