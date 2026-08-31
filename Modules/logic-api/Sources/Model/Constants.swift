//
//  Constants.swift
//  logic-api
//

import Foundation

enum Constants {

  enum Key {
    static let authToken = "X-Auth-Token"
    static let authChallenge = "auth-challenge"
    static let signatureInput = "Signature-Input"
    static let signature = "Signature"
    static let mdvmToken = "mdvm-token"
    static let pinSessionToken = "rwsca-pin-session-token"
    static let apiKeyQueryParam = "apiKey"
    static let authorization = "Authorization"
    static let dpop = "DPoP"
    static let mdvmWIID = "mdvm-wi-id"
    static let wpbWIID = "wpb-wi-id"
    static let rwscaAccountId = "rwsca-account-id"
    static let clientAttestation = "OAuth-Client-Attestation"
    static let clientAttestationPoP = "OAuth-Client-Attestation-PoP"
    static let location = "Location"
    static let cookie = "Cookie"
    static let setCookie = "Set-Cookie"
  }

  enum BodyKey {
    static let accessToken = "access_token"
    static let refreshToken = "refresh_token"
    static let cNonce = "c_nonce"
    static let pidProviderCNonce = "pp_c_nonce"
    static let credential = "credential"
    static let credentials = "credentials"
    static let pinSessionToken = "rwsca_pin_session_token"
    static let rwscaAuthChallenge = "rwsca_auth_challenge"
    static let wpbAuthChallenge = "wpb_auth_challenge"
    static let keyBindingSignature = "rwscd_key_binding_signature"
    static let rwscaWiWrappedPrivateKey = "rwsca_wi_wrapped_prvk"
    static let rwscaWte = "rwsca_wte"
    static let papDeviceCheckAttestation = "pap_devicecheck_attestation"
    static let papDeviceCheckAssertion = "pap_devicecheck_assertion"
    static let preAuthorizedCode = "pre-authorized_code"
    static let txCode = "tx_code"
    static let authorizationCode = "code"
    static let codeVerifier = "code_verifier"
    static let mdvmToken = "mdvm_token"
    static let mdvmWIID = "mdvm_wi_id"
    static let mdvmAuthChallenge = "mdvm_auth_challenge"
    static let pnsAuthChallenge = "pns_auth_challenge"
    static let rwscaAccountId = "rwsca_account_id"
    static let wpbWia = "wpb_wia"
    static let proof = "proof"
    static let proofs = "proofs"
  }
}
