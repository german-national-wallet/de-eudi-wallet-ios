//
//  PinnedCertificateTrustEvaluator.swift
//  logic-api
//

import Alamofire
import Foundation
import Security

struct PinnedCertificateTrustEvaluator: ServerTrustEvaluating {

  let pinner: CertificatePinner
  let hostSuffix: String

  func evaluate(_ trust: SecTrust, forHost host: String) throws {
    guard SecTrustEvaluateWithError(trust, nil), pinner.matches(serverTrust: trust, hostSuffix: hostSuffix) else {
      throw AFError.serverTrustEvaluationFailed(
        reason: .certificatePinningFailed(
          host: host,
          trust: trust,
          pinnedCertificates: pinner.anchors(forHostSuffix: hostSuffix),
          serverCertificates: SecTrustCopyCertificateChain(trust) as? [SecCertificate] ?? []
        )
      )
    }
  }
}
