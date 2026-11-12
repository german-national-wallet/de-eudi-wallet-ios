//
//  NetworkConnectivityMonitor.swift
//  logic-api
//

import Foundation
import Network
import os

public protocol NetworkConnectivityMonitor: Sendable {
  var isOffline: Bool { get }
}

public extension NetworkConnectivityMonitor {
  // Wallet-kit wraps transport errors in its own types, so the current path status is the fallback.
  // A BackendError means the backend answered, so it is never treated as offline.
  func isNoInternet(_ error: Error) -> Bool {
    guard !(error is BackendError) else { return false }
    return error.isNoInternet || isOffline
  }
}

final class NetworkConnectivityMonitorImpl: NetworkConnectivityMonitor {

  private let monitor = NWPathMonitor()
  private let status = OSAllocatedUnfairLock<NWPath.Status?>(initialState: nil)

  init() {
    monitor.pathUpdateHandler = { [status] path in
      status.withLock { $0 = path.status }
    }
    monitor.start(queue: DispatchQueue(label: "logic-api.network-connectivity-monitor"))
  }

  deinit {
    monitor.cancel()
  }

  // Fails open: an unknown status (before the first path update) or `.requiresConnection`
  // lets the request go through, so a stale monitor never blocks a working connection.
  var isOffline: Bool {
    status.withLock { $0 } == .unsatisfied
  }
}
