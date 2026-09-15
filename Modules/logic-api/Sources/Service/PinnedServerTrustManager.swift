//
//  PinnedServerTrustManager.swift
//  logic-api
//

import Alamofire
import Foundation

public final class PinnedServerTrustManager: ServerTrustManager, @unchecked Sendable {

  private let pinner: CertificatePinner

  public init(pinner: CertificatePinner) {
    self.pinner = pinner
    super.init(allHostsMustBeEvaluated: false, evaluators: [:])
  }

  public override func serverTrustEvaluator(forHost host: String) throws -> (any ServerTrustEvaluating)? {
    guard let hostSuffix = pinner.pinnedHostSuffix(for: host) else {
      return nil
    }
    return PinnedCertificateTrustEvaluator(pinner: pinner, hostSuffix: hostSuffix)
  }
}
