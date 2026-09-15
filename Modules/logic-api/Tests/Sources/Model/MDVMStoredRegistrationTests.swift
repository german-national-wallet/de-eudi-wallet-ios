//
//  MDVMStoredRegistrationTests.swift
//  logic-api
//
//  Created by Tamas Dancsi on 05.03.26.
//

import Foundation
import Testing

@testable import logic_api

struct MDVMStoredRegistrationTests {

  @Test
  func expirationDate_ReturnsDate_WhenJWTContainsExp() {
    let expectedExp = Int(Date().addingTimeInterval(3600).timeIntervalSince1970)
    let token = makeJWT(payload: ["exp": expectedExp])
    let sut = MDVMStoredRegistration(mdvmWIID: "mdvm-id", mdvmToken: token)

    #expect(Int(sut.expirationDate?.timeIntervalSince1970 ?? 0) == expectedExp)
  }

  @Test
  func expirationDate_ReturnsNil_WhenExpIsMissing() {
    let token = makeJWT(payload: ["sub": "test"])
    let sut = MDVMStoredRegistration(mdvmWIID: "mdvm-id", mdvmToken: token)

    #expect(sut.expirationDate == nil)
  }

  @Test
  func expirationDate_ReturnsDate_WhenPayloadHasNoPadding() {
    let expectedExp = Int(Date().addingTimeInterval(1200).timeIntervalSince1970)
    let token = makeJWT(payload: ["exp": expectedExp], dropPadding: true)
    let sut = MDVMStoredRegistration(mdvmWIID: "mdvm-id", mdvmToken: token)

    #expect(Int(sut.expirationDate?.timeIntervalSince1970 ?? 0) == expectedExp)
  }

  private func makeJWT(payload: [String: Any], dropPadding: Bool = false) -> String {
    let headerData = try? JSONSerialization.data(withJSONObject: ["alg": "HS256", "typ": "JWT"])
    let payloadData = try? JSONSerialization.data(withJSONObject: payload)

    func encode(_ data: Data?) -> String {
      let base64 = (data ?? Data()).base64EncodedString()
      let base64URL = base64
        .replacingOccurrences(of: "+", with: "-")
        .replacingOccurrences(of: "/", with: "_")
      if dropPadding {
        return base64URL.replacingOccurrences(of: "=", with: "")
      }
      return base64URL
    }

    return "\(encode(headerData)).\(encode(payloadData)).signature"
  }
}
