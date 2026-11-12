//
//  PresentationOriginStore.swift
//  logic-core
//

import Foundation

public protocol PresentationOriginStore: Sendable {
  func setServiceProviderURL(_ url: URL?)
  func getServiceProviderURL() -> URL?
}

final class PresentationOriginStoreImpl: PresentationOriginStore, @unchecked Sendable {

  private let lock = NSLock()
  private var serviceProviderURL: URL?

  func setServiceProviderURL(_ url: URL?) {
    lock.withLock { serviceProviderURL = url }
  }

  func getServiceProviderURL() -> URL? {
    lock.withLock { serviceProviderURL }
  }
}
