//
//  RWSCAWiMetaDataResponse.swift
//  logic-api
//

import JOSESwift

struct RWSCAWiMetaDataResponse: Decodable {
  let rwscaPinEncPubk: ECPublicKey

  enum CodingKeys: String, CodingKey {
    case rwscaPinEncPubk = "rwsca_pin_enc_pubk"
  }
}
