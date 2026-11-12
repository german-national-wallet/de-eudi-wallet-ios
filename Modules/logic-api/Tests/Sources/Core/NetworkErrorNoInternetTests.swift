//
//  NetworkErrorNoInternetTests.swift
//  logic-api
//

import Foundation
import Testing

@testable import logic_api

struct NetworkErrorNoInternetTests {

  @Test(arguments: [
    URLError.Code.notConnectedToInternet,
    .dataNotAllowed,
    .internationalRoamingOff
  ])
  func isNoInternet_IsTrue_ForOfflineURLErrors(code: URLError.Code) {
    #expect(URLError(code).isNoInternet)
  }

  @Test(arguments: [
    URLError.Code.timedOut,
    .networkConnectionLost,
    .cannotFindHost,
    .cannotConnectToHost,
    .serverCertificateUntrusted,
    .cancelled
  ])
  func isNoInternet_IsFalse_ForOtherURLErrors(code: URLError.Code) {
    #expect(!URLError(code).isNoInternet)
  }

  @Test
  func isNoInternet_IsTrue_ForNetworkErrorNoInternet() {
    #expect(NetworkError.noInternet.isNoInternet)
  }

  @Test
  func isNoInternet_IsFalse_ForOtherNetworkErrors() {
    #expect(!NetworkError.invalidResponse.isNoInternet)
    #expect(!NetworkError.httpError(code: 503, data: nil, headers: nil).isNoInternet)
  }

  @Test
  func isNoInternet_UnwrapsInternetFailure() {
    #expect(NetworkError.internetFailure(URLError(.notConnectedToInternet)).isNoInternet)
    #expect(!NetworkError.internetFailure(URLError(.timedOut)).isNoInternet)
  }

  @Test
  func isNoInternet_UnwrapsNSUnderlyingError() {
    let wrapped = NSError(
      domain: "wallet-kit",
      code: 1,
      userInfo: [NSUnderlyingErrorKey: URLError(.notConnectedToInternet)]
    )

    #expect(wrapped.isNoInternet)
  }

  @Test
  func monitorIsNoInternet_IsTrue_ForAnOfflineErrorWhileOnline() {
    #expect(StubConnectivityMonitor(isOffline: false).isNoInternet(NetworkError.noInternet))
  }

  @Test
  func monitorIsNoInternet_IsTrue_ForAWrappedErrorWhileOffline() {
    #expect(StubConnectivityMonitor(isOffline: true).isNoInternet(NetworkError.invalidResponse))
  }

  @Test
  func monitorIsNoInternet_IsFalse_ForAnOtherErrorWhileOnline() {
    #expect(!StubConnectivityMonitor(isOffline: false).isNoInternet(NetworkError.invalidResponse))
  }

  @Test
  func monitorIsNoInternet_IsFalse_ForABackendErrorWhileOffline() {
    #expect(!StubConnectivityMonitor(isOffline: true).isNoInternet(BackendError.invalidResponse))
  }
}
