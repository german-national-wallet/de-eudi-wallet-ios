//
//  RWSCARepositoryTests.swift
//  logic-api
//
//  Created by Pankaj Sachdeva on 11.03.26.
//

import Foundation
import Security
import Testing
import Cuckoo

@testable import logic_api
@testable import logic_business
@testable import logic_test

private func signatures(count: Int) -> ParameterMatcher<[HTTPMessageSignature]> {
  ParameterMatcher { $0.count == count }
}

private func makeValidChallengeData() throws -> Data {
  try JSONEncoder().encode(RWSCAChallengeResponse(rwscaAuthChallenge: "challenge-abc"))
}

private func makeValidRegistrationData() throws -> Data {
  try JSONEncoder().encode(RWSCARegistrationResponse(rwscaAccountID: "account-123"))
}

private func makeValidCreateKeysData() throws -> Data {
  try JSONEncoder().encode(
    RWSCACreateKeysResponse(
      rwscaWIKeys: [
        .init(
          rwscdWIPubk: "MFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAEpubk",
          rwscaWIWrappedPrvk: "wrapped-prvk-1"
        )
      ],
      rwscaWTE: "mock-wte"
    )
  )
}

private func makeValidSignDataData() throws -> Data {
  try JSONEncoder().encode(
    RWSCASignDataResponse(rwscdKeyBindingSignature: "MEYCIQDmock-signature")
  )
}

private func makeServerErrorData(
  code: String = "ERR_001",
  description: String = "Something went wrong",
  traceID: String = "trace-xyz"
) throws -> Data {
  try JSONEncoder().encode(MDVMErrorResponse(code: code, description: description, traceID: traceID))
}

private func makeMockPrivateKey() -> SecKey {
  let attributes: [String: Any] = [
    kSecAttrKeyType as String: kSecAttrKeyTypeECSECPrimeRandom,
    kSecAttrKeySizeInBits as String: 256
  ]
  return SecKeyCreateRandomKey(attributes as CFDictionary, nil)!
}

private func makeSUT(
  networkManager: FakeNetworkManager = FakeNetworkManager(),
  httpSignatureService: MockHTTPSignatureService = makeSigningServiceMock(),
  secureEnclaveController: FakeSecureEnclaveController = FakeSecureEnclaveController()
) -> RWSCARepositoryImpl {
  RWSCARepositoryImpl(
    networkManager: networkManager,
    httpSignatureService: httpSignatureService,
    secureEnclaveController: secureEnclaveController
  )
}

private func makeSigningServiceMock(
  contentDigest: String = "sha-256=:mock-digest:",
  signatureHeaders: [String: String] = [
    MDVMConstants.Header.contentDigest: "sha-256=:mock-digest:",
    MDVMConstants.Header.signatureInput: "rwsca-auth-sig=mock-signature-input",
    MDVMConstants.Header.signature: "rwsca-auth-sig=:mock-signature:"
  ],
  multiSignatureHeaders: [String: String] = [
    MDVMConstants.Header.contentDigest: "sha-256=:mock-digest:",
    MDVMConstants.Header.signatureInput: "rwsca-auth-sig=mock-auth-input,rwsca-pin-sig=mock-pin-input",
    MDVMConstants.Header.signature: "rwsca-auth-sig=:mock-auth-signature:,rwsca-pin-sig=:mock-pin-signature:"
  ]
) -> MockHTTPSignatureService {
  let mock = MockHTTPSignatureService()
  stub(mock) { stub in
    when(stub.createContentDigest(for: any())).thenReturn(contentDigest)
    when(stub.makeSignatureHeaders(context: any(), signatures: signatures(count: 1)))
      .thenReturn(signatureHeaders)
    when(stub.makeSignatureHeaders(context: any(), signatures: signatures(count: 2)))
      .thenReturn(multiSignatureHeaders)
  }
  return mock
}

@Suite("RWSCARepositoryImpl")
struct RWSCARepositoryImplTests {

  @Suite("fetchChallenge")
  struct FetchChallengeTests {

    @Test("returns challenge string on success")
    func success() async throws {
      let network = FakeNetworkManager()
      network.mockResponse = NetworkResponse(data: try makeValidChallengeData(), headers: [:])
      let sut = makeSUT(networkManager: network)

      let result = try await sut.fetchChallenge()

      #expect(result == "challenge-abc")
    }

    @Test("throws invalidResponse when data is nil")
    func nilData() async throws {
      let network = FakeNetworkManager()
      network.mockResponse = NetworkResponse(data: nil, headers: nil)
      let sut = makeSUT(networkManager: network)

      await #expect(throws: RWSCARepositoryError.invalidResponse) {
        try await sut.fetchChallenge()
      }
    }

    @Test("throws decodingFailed when response JSON is malformed")
    func malformedJSON() async throws {
      let network = FakeNetworkManager()
      network.mockResponse = NetworkResponse(data: "not-json".data(using: .utf8), headers: nil)
      let sut = makeSUT(networkManager: network)

      await #expect(throws: RWSCARepositoryError.decodingFailed) {
        try await sut.fetchChallenge()
      }
    }

    @Test("throws serverError when server returns error payload")
    func serverErrorPayload() async throws {
      let network = FakeNetworkManager()
      network.mockResponse = NetworkResponse(data: try makeServerErrorData(
        code: "ERR_001",
        description: "Unauthorized",
        traceID: "trace-xyz"
      ), headers: nil)
      let sut = makeSUT(networkManager: network)

      await #expect(throws: RWSCARepositoryError.serverError(
        code: "ERR_001",
        description: "Unauthorized",
        traceID: "trace-xyz"
      )) {
        try await sut.fetchChallenge()
      }
    }

    @Test("propagates network errors")
    func networkFailure() async throws {
      let network = FakeNetworkManager()
      network.error = URLError(.notConnectedToInternet)
      let sut = makeSUT(networkManager: network)

      await #expect(throws: URLError.self) {
        try await sut.fetchChallenge()
      }
    }
  }

  // MARK: register

  @Suite("register")
  struct RegisterTests {

    @Test("succeeds and saves rwscaAccountId to secure storage")
    func success_savesAccountId() async throws {
      let network = FakeNetworkManager()
      network.mockResponse = NetworkResponse(data: try makeValidRegistrationData(), headers: nil)
      let secureEnclave = FakeSecureEnclaveController()
      let sut = makeSUT(networkManager: network, secureEnclaveController: secureEnclave)

      try await sut.register(
        mdvmToken: "my-token",
        authChallenge: "my-challenge",
        privateKey: makeMockPrivateKey()
      )

      #expect(secureEnclave.retrieveStringFromKeychain(keyTag: .rwscaAccountID) == "account-123")
    }

    @Test("throws invalidResponse when network returns nil data")
    func nilData() async throws {
      let network = FakeNetworkManager()
      network.mockResponse = NetworkResponse(data: nil, headers: nil)
      let sut = makeSUT(networkManager: network)

      await #expect(throws: RWSCARepositoryError.invalidResponse) {
        try await sut.register(
          mdvmToken: "token",
          authChallenge: "challenge",
          privateKey: makeMockPrivateKey()
        )
      }
    }

    @Test("throws serverError when API returns error payload")
    func serverErrorPayload() async throws {
      let network = FakeNetworkManager()
      network.mockResponse = NetworkResponse(data: try makeServerErrorData(
        code: "REG_FAIL",
        description: "Registration denied",
        traceID: "trace-xyz"
      ), headers: nil)
      let sut = makeSUT(networkManager: network)

      await #expect(throws: RWSCARepositoryError.serverError(
        code: "REG_FAIL",
        description: "Registration denied",
        traceID: "trace-xyz"
      )) {
        try await sut.register(
          mdvmToken: "token",
          authChallenge: "challenge",
          privateKey: makeMockPrivateKey()
        )
      }
    }

    @Test("throws decodingFailed when registration response is malformed")
    func malformedRegistrationResponse() async throws {
      let network = FakeNetworkManager()
      network.mockResponse = NetworkResponse(data: "bad-json".data(using: .utf8), headers: nil)
      let sut = makeSUT(networkManager: network)

      await #expect(throws: RWSCARepositoryError.decodingFailed) {
        try await sut.register(
          mdvmToken: "token",
          authChallenge: "challenge",
          privateKey: makeMockPrivateKey()
        )
      }
    }

    @Test("does NOT save account ID when signing fails")
    func noAccountIdOnSigningFailure() async throws {
      let signingService = makeSigningServiceMock()
      stub(signingService) { stub in
        when(
          stub.makeSignatureHeaders(context: any(), signatures: signatures(count: 1))
        ).thenThrow(HTTPMessageSigningError.signingFailed)
      }
      let secureEnclave = FakeSecureEnclaveController()
      let sut = makeSUT(httpSignatureService: signingService, secureEnclaveController: secureEnclave)

      try? await sut.register(
        mdvmToken: "token",
        authChallenge: "challenge",
        privateKey: makeMockPrivateKey()
      )

      #expect(secureEnclave.retrieveStringFromKeychain(keyTag: .rwscaAccountID) == nil)
    }

    @Test("does NOT save account ID when network fails")
    func noAccountIdOnNetworkFailure() async throws {
      let network = FakeNetworkManager()
      network.error = URLError(.timedOut)
      let secureEnclave = FakeSecureEnclaveController()
      let sut = makeSUT(networkManager: network, secureEnclaveController: secureEnclave)

      try? await sut.register(
        mdvmToken: "token",
        authChallenge: "challenge",
        privateKey: makeMockPrivateKey()
      )

      #expect(secureEnclave.retrieveStringFromKeychain(keyTag: .rwscaAccountID) == nil)
    }

    @Test("propagates network errors")
    func networkFailure() async throws {
      let network = FakeNetworkManager()
      network.error = URLError(.timedOut)
      let sut = makeSUT(networkManager: network)

      await #expect(throws: URLError.self) {
        try await sut.register(
          mdvmToken: "token",
          authChallenge: "challenge",
          privateKey: makeMockPrivateKey()
        )
      }
    }
  }

  // MARK: getRWSCAID

  @Suite("getRWSCAID")
  struct GetRWSCAIDTests {

    @Test("returns stored account ID when present")
    func returnsStoredValue() {
      let secureEnclave = FakeSecureEnclaveController()
      _ = secureEnclave.storeStringInKeychain(value: "account-999", keyTag: .rwscaAccountID)
      let sut = makeSUT(secureEnclaveController: secureEnclave)

      #expect(sut.getRWSCAID() == "account-999")
    }

    @Test("returns nil when no account ID is stored")
    func returnsNilWhenMissing() {
      let sut = makeSUT(secureEnclaveController: FakeSecureEnclaveController())

      #expect(sut.getRWSCAID() == nil)
    }

    @Test("returns nil after a failed registration attempt")
    func returnsNilAfterFailedRegistration() async throws {
      let network = FakeNetworkManager()
      network.error = URLError(.timedOut)
      let secureEnclave = FakeSecureEnclaveController()
      let sut = makeSUT(networkManager: network, secureEnclaveController: secureEnclave)

      try? await sut.register(
        mdvmToken: "token",
        authChallenge: "challenge",
        privateKey: makeMockPrivateKey()
      )

      #expect(sut.getRWSCAID() == nil)
    }

    @Test("returns account ID after successful registration")
    func returnsIDAfterSuccessfulRegistration() async throws {
      let network = FakeNetworkManager()
      network.mockResponse = NetworkResponse(data: try makeValidRegistrationData(), headers: nil)
      let secureEnclave = FakeSecureEnclaveController()
      let sut = makeSUT(networkManager: network, secureEnclaveController: secureEnclave)

      try await sut.register(
        mdvmToken: "token",
        authChallenge: "challenge",
        privateKey: makeMockPrivateKey()
      )

      #expect(sut.getRWSCAID() == "account-123")
    }
  }

  @Suite("initializePinAndStartPinSession")
  struct InitializePinAndStartPinSession {

    private func makeValidPinSessionResponseData() throws -> Data {
      try JSONEncoder().encode(RWSCAPinSessionResponse(
        rwscaPinSessionToken: "eyJraWQiOiIxIiwidHlwIjoicndzY2EtcGluLXNlc3Npb24tdG9rZW4iLCJhbGciOiJIUzI1NiJ9.test.signature"
      ))
    }

    private func makePayload() -> RWSCAInitializePinAndStartPinSessionPayload {
      RWSCAInitializePinAndStartPinSessionPayload(
        wiRwscaPinPubk: "MFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAEDO+n/vG9XUk3MnMqzGdb+SL5MUIMyF6laK/tvNqHSe16Hfzp4U7ZZRR3J/g3YPS1sGCbAbWKRmZz4yYq4C2KOA=="
      )
    }

    private func makeECKey() -> SecKey {
      let attributes: [String: Any] = [
        kSecAttrKeyType as String: kSecAttrKeyTypeECSECPrimeRandom,
        kSecAttrKeySizeInBits as String: 256
      ]
      return SecKeyCreateRandomKey(attributes as CFDictionary, nil)!
    }

    // MARK: - Success

    @Test("returns RWSCAPinSessionResponse on success")
    func success_returnsResponse() async throws {
      let network = FakeNetworkManager()
      network.mockResponse = NetworkResponse(data: try makeValidPinSessionResponseData(), headers: nil)
      let sut = makeSUT(networkManager: network)

      let response = try await sut.initializePinAndStartPinSession(
        mdvmToken: "mock-mdvm-token",
        challenge: "mock-challenge",
        rwscaID: "mock-rwsca-id",
        pinPrivateKey: makeECKey(),
        mdvmPrivateKey: makeECKey(),
        payload: makePayload()
      )

      #expect(response.rwscaPinSessionToken.isEmpty == false)
    }

    @Test("encodes payload as request body")
    func success_encodesPayloadAsBody() async throws {
      class SpyNetworkManager: FakeNetworkManager {
        var capturedBody: Data?
        override func execute<R: NetworkRequest>(
          with request: R,
          parameters: [NetworkParameter]?
        ) async throws -> NetworkResponse {
          capturedBody = (request as? RWSCAPinSessionRequest)?.body
          return try await super.execute(with: request, parameters: parameters)
        }
      }
      let spy = SpyNetworkManager()
      spy.mockResponse = NetworkResponse(data: try makeValidPinSessionResponseData(), headers: nil)
      let sut = makeSUT(networkManager: spy)
      let payload = makePayload()

      _ = try await sut.initializePinAndStartPinSession(
        mdvmToken: "token",
        challenge: "challenge",
        rwscaID: "id",
        pinPrivateKey: makeECKey(),
        mdvmPrivateKey: makeECKey(),
        payload: payload
      )

      let capturedPayload = try JSONDecoder().decode(
        RWSCAInitializePinAndStartPinSessionPayload.self,
        from: spy.capturedBody!
      )
      #expect(capturedPayload.wiRwscaPinPubk == payload.wiRwscaPinPubk)
    }

    @Test("sends both rwsca-auth-sig and rwsca-pin-sig in Signature header")
    func success_sendsBothSignatures() async throws {
      class SpyNetworkManager: FakeNetworkManager {
        var capturedHeaders: [String: String] = [:]
        override func execute<R: NetworkRequest>(
          with request: R,
          parameters: [NetworkParameter]?
        ) async throws -> NetworkResponse {
          capturedHeaders = (request as? RWSCAPinSessionRequest)?.additionalHeaders ?? [:]
          return try await super.execute(with: request, parameters: parameters)
        }
      }
      let spy = SpyNetworkManager()
      spy.mockResponse = NetworkResponse(data: try makeValidPinSessionResponseData(), headers: nil)
      let signingService = makeSigningServiceMock(
        multiSignatureHeaders: [
          MDVMConstants.Header.signature: "rwsca-auth-sig=:mock-auth-signature:,rwsca-pin-sig=:mock-pin-signature:"
        ]
      )
      let sut = makeSUT(networkManager: spy, httpSignatureService: signingService)


      _ = try await sut.initializePinAndStartPinSession(
        mdvmToken: "token",
        challenge: "challenge",
        rwscaID: "rwsca-id",
        pinPrivateKey: makeECKey(),
        mdvmPrivateKey: makeECKey(),
        payload: makePayload()
      )

      let signatureHeader = spy.capturedHeaders[MDVMConstants.Header.signature] ?? ""
      #expect(signatureHeader.contains(RWSCAConstants.Signature.nameAuthSig))
      #expect(signatureHeader.contains(RWSCAConstants.Signature.namePinSig))
    }

    @Test("sends Content-Digest header")
    func success_sendsContentDigest() async throws {
      class SpyNetworkManager: FakeNetworkManager {
        var capturedHeaders: [String: String] = [:]
        override func execute<R: NetworkRequest>(
          with request: R,
          parameters: [NetworkParameter]?
        ) async throws -> NetworkResponse {
          capturedHeaders = (request as? RWSCAPinSessionRequest)?.additionalHeaders ?? [:]
          return try await super.execute(with: request, parameters: parameters)
        }
      }
      let spy = SpyNetworkManager()
      spy.mockResponse = NetworkResponse(data: try makeValidPinSessionResponseData(), headers: nil)
      let signingService = makeSigningServiceMock(
        multiSignatureHeaders: [
          MDVMConstants.Header.contentDigest: "sha-256=:mock-digest:"
        ]
      )
      let sut = makeSUT(networkManager: spy, httpSignatureService: signingService)

      _ = try await sut.initializePinAndStartPinSession(
        mdvmToken: "token",
        challenge: "challenge",
        rwscaID: "rwsca-id",
        pinPrivateKey: makeECKey(),
        mdvmPrivateKey: makeECKey(),
        payload: makePayload()
      )

      #expect(spy.capturedHeaders[MDVMConstants.Header.contentDigest] != nil)
    }

    // MARK: - Failures

    @Test("throws signingFailed when signature service throws")
    func signingFails_throwsSigningFailed() async throws {
      let signingService = makeSigningServiceMock()
      stub(signingService) { stub in
        when(
          stub.makeSignatureHeaders(context: any(), signatures: signatures(count: 2))
        ).thenThrow(HTTPMessageSigningError.signingFailed)
      }
      let sut = makeSUT(httpSignatureService: signingService)

      await #expect(throws: RWSCARepositoryError.signingFailed) {
        try await sut.initializePinAndStartPinSession(
          mdvmToken: "token",
          challenge: "challenge",
          rwscaID: "id",
          pinPrivateKey: makeECKey(),
          mdvmPrivateKey: makeECKey(),
          payload: makePayload()
        )
      }
    }

    @Test("maps missing signed header errors from signature service")
    func missingSignedHeader_throwsRepositoryError() async throws {
      let signingService = makeSigningServiceMock()
      stub(signingService) { stub in
        when(
          stub.makeSignatureHeaders(context: any(), signatures: signatures(count: 2))
        ).thenThrow(HTTPMessageSigningError.missingSignedHeader("content-digest"))
      }
      let sut = makeSUT(httpSignatureService: signingService)

      await #expect(throws: RWSCARepositoryError.missingSignedHeader("content-digest")) {
        try await sut.initializePinAndStartPinSession(
          mdvmToken: "token",
          challenge: "challenge",
          rwscaID: "id",
          pinPrivateKey: makeECKey(),
          mdvmPrivateKey: makeECKey(),
          payload: makePayload()
        )
      }
    }

    @Test("throws invalidResponse when network returns nil data")
    func nilData_throwsInvalidResponse() async throws {
      let network = FakeNetworkManager()
      network.mockResponse = NetworkResponse(data: nil, headers: nil)
      let sut = makeSUT(networkManager: network)

      await #expect(throws: RWSCARepositoryError.invalidResponse) {
        try await sut.initializePinAndStartPinSession(
          mdvmToken: "token",
          challenge: "challenge",
          rwscaID: "id",
          pinPrivateKey: makeECKey(),
          mdvmPrivateKey: makeECKey(),
          payload: makePayload()
        )
      }
    }

    @Test("throws serverError when API returns error payload")
    func serverError_throwsServerError() async throws {
      let network = FakeNetworkManager()
      network.mockResponse = NetworkResponse(data: try JSONEncoder().encode(
        MDVMErrorResponse(code: "MALFORMED_PIN_PUB_KEY", description: "Bad key", traceID: "trace-1")
      ), headers: nil)
      let sut = makeSUT(networkManager: network)

      await #expect(throws: RWSCARepositoryError.serverError(
        code: "MALFORMED_PIN_PUB_KEY",
        description: "Bad key",
        traceID: "trace-1"
      )) {
        try await sut.initializePinAndStartPinSession(
          mdvmToken: "token",
          challenge: "challenge",
          rwscaID: "id",
          pinPrivateKey: makeECKey(),
          mdvmPrivateKey: makeECKey(),
          payload: makePayload()
        )
      }
    }

    @Test("throws decodingFailed when response is malformed JSON")
    func malformedResponse_throwsDecodingFailed() async throws {
      let network = FakeNetworkManager()
      network.mockResponse = NetworkResponse(data: "not-json".data(using: .utf8), headers: nil)
      let sut = makeSUT(networkManager: network)

      await #expect(throws: RWSCARepositoryError.decodingFailed) {
        try await sut.initializePinAndStartPinSession(
          mdvmToken: "token",
          challenge: "challenge",
          rwscaID: "id",
          pinPrivateKey: makeECKey(),
          mdvmPrivateKey: makeECKey(),
          payload: makePayload()
        )
      }
    }

    @Test("propagates network errors")
    func networkFailure_propagates() async throws {
      let network = FakeNetworkManager()
      network.error = URLError(.timedOut)
      let sut = makeSUT(networkManager: network)

      await #expect(throws: URLError.self) {
        try await sut.initializePinAndStartPinSession(
          mdvmToken: "token",
          challenge: "challenge",
          rwscaID: "id",
          pinPrivateKey: makeECKey(),
          mdvmPrivateKey: makeECKey(),
          payload: makePayload()
        )
      }
    }

  }

  @Suite("createKeys")
  struct CreateKeysTests {

    private func makePayload() -> RWSCACreateKeysPayload {
      RWSCACreateKeysPayload(numberOfKeys: 2, ppCNonce: "issuer-nonce")
    }

    @Test("returns RWSCACreateKeysResponse on success")
    func success_returnsResponse() async throws {
      let network = FakeNetworkManager()
      network.mockResponse = NetworkResponse(data: try makeValidCreateKeysData(), headers: nil)
      let sut = makeSUT(networkManager: network)

      let response = try await sut.createKeys(
        mdvmToken: "mdvm-token",
        challenge: "challenge",
        rwscaID: "rwsca-id",
        mdvmPrivateKey: makeMockPrivateKey(),
        payload: makePayload()
      )

      #expect(response.rwscaWIKeys.count == 1)
      #expect(response.rwscaWIKeys.first?.rwscaWIWrappedPrvk == "wrapped-prvk-1")
      #expect(response.rwscaWTE == "mock-wte")
    }

    @Test("encodes payload as request body")
    func success_encodesPayloadAsBody() async throws {
      class SpyNetworkManager: FakeNetworkManager {
        var capturedBody: Data?
        override func execute<R: NetworkRequest>(
          with request: R,
          parameters: [NetworkParameter]?
        ) async throws -> NetworkResponse {
          capturedBody = (request as? RWSCACreateKeysRequest)?.body
          return try await super.execute(with: request, parameters: parameters)
        }
      }

      let spy = SpyNetworkManager()
      spy.mockResponse = NetworkResponse(data: try makeValidCreateKeysData(), headers: nil)
      let payload = makePayload()
      let sut = makeSUT(networkManager: spy)

      _ = try await sut.createKeys(
        mdvmToken: "mdvm-token",
        challenge: "challenge",
        rwscaID: "rwsca-id",
        mdvmPrivateKey: makeMockPrivateKey(),
        payload: payload
      )

      let capturedPayload = try JSONDecoder().decode(RWSCACreateKeysPayload.self, from: spy.capturedBody!)
      #expect(capturedPayload == payload)
    }

    @Test("sends signed headers with content digest")
    func success_sendsSignedHeaders() async throws {
      class SpyNetworkManager: FakeNetworkManager {
        var capturedHeaders: [String: String] = [:]
        override func execute<R: NetworkRequest>(
          with request: R,
          parameters: [NetworkParameter]?
        ) async throws -> NetworkResponse {
          capturedHeaders = (request as? RWSCACreateKeysRequest)?.additionalHeaders ?? [:]
          return try await super.execute(with: request, parameters: parameters)
        }
      }

      let spy = SpyNetworkManager()
      spy.mockResponse = NetworkResponse(data: try makeValidCreateKeysData(), headers: nil)
      let signingService = makeSigningServiceMock(
        signatureHeaders: [
          MDVMConstants.Header.contentDigest: "sha-256=:mock-digest:",
          MDVMConstants.Header.signatureInput: "rwsca-auth-sig=mock-signature-input",
          MDVMConstants.Header.signature: "rwsca-auth-sig=:mock-signature:"
        ]
      )
      let sut = makeSUT(networkManager: spy, httpSignatureService: signingService)

      _ = try await sut.createKeys(
        mdvmToken: "mdvm-token",
        challenge: "challenge",
        rwscaID: "rwsca-id",
        mdvmPrivateKey: makeMockPrivateKey(),
        payload: makePayload()
      )

      #expect(spy.capturedHeaders[MDVMConstants.Header.contentDigest] != nil)
      #expect(spy.capturedHeaders[MDVMConstants.Header.signatureInput]?.contains(RWSCAConstants.Signature.nameAuthSig) == true)
      #expect(spy.capturedHeaders[MDVMConstants.Header.signature]?.contains(RWSCAConstants.Signature.nameAuthSig) == true)
    }

    @Test("maps signature service errors")
    func signingFails_throwsSigningFailed() async throws {
      let signingService = makeSigningServiceMock()
      stub(signingService) { stub in
        when(
          stub.makeSignatureHeaders(context: any(), signatures: signatures(count: 1))
        ).thenThrow(HTTPMessageSigningError.signingFailed)
      }
      let sut = makeSUT(httpSignatureService: signingService)

      await #expect(throws: RWSCARepositoryError.signingFailed) {
        try await sut.createKeys(
          mdvmToken: "mdvm-token",
          challenge: "challenge",
          rwscaID: "rwsca-id",
          mdvmPrivateKey: makeMockPrivateKey(),
          payload: makePayload()
        )
      }
    }

    @Test("throws invalidResponse when network returns nil data")
    func nilData_throwsInvalidResponse() async throws {
      let network = FakeNetworkManager()
      network.mockResponse = NetworkResponse(data: nil, headers: nil)
      let sut = makeSUT(networkManager: network)

      await #expect(throws: RWSCARepositoryError.invalidResponse) {
        try await sut.createKeys(
          mdvmToken: "mdvm-token",
          challenge: "challenge",
          rwscaID: "rwsca-id",
          mdvmPrivateKey: makeMockPrivateKey(),
          payload: makePayload()
        )
      }
    }

    @Test("throws serverError when API returns error payload")
    func serverError_throwsServerError() async throws {
      let network = FakeNetworkManager()
      network.mockResponse = NetworkResponse(data: try makeServerErrorData(
        code: "CREATE_FAIL",
        description: "Create denied",
        traceID: "trace-create"
      ), headers: nil)
      let sut = makeSUT(networkManager: network)

      await #expect(throws: RWSCARepositoryError.serverError(
        code: "CREATE_FAIL",
        description: "Create denied",
        traceID: "trace-create"
      )) {
        try await sut.createKeys(
          mdvmToken: "mdvm-token",
          challenge: "challenge",
          rwscaID: "rwsca-id",
          mdvmPrivateKey: makeMockPrivateKey(),
          payload: makePayload()
        )
      }
    }

    @Test("propagates network errors")
    func networkFailure_propagates() async throws {
      let network = FakeNetworkManager()
      network.error = URLError(.timedOut)
      let sut = makeSUT(networkManager: network)

      await #expect(throws: URLError.self) {
        try await sut.createKeys(
          mdvmToken: "mdvm-token",
          challenge: "challenge",
          rwscaID: "rwsca-id",
          mdvmPrivateKey: makeMockPrivateKey(),
          payload: makePayload()
        )
      }
    }
  }

  @Suite("signData")
  struct SignDataTests {

    private func makePayload() -> RWSCASignDataPayload {
      RWSCASignDataPayload(
        rwscaWIWrappedPrvk: "wrapped-prvk",
        wiKeyBindingDataHash: "binding-hash"
      )
    }

    @Test("returns RWSCASignDataResponse on success")
    func success_returnsResponse() async throws {
      let network = FakeNetworkManager()
      network.mockResponse = NetworkResponse(data: try makeValidSignDataData(), headers: nil)
      let sut = makeSUT(networkManager: network)

      let response = try await sut.signData(
        mdvmToken: "mdvm-token",
        challenge: "challenge",
        rwscaID: "rwsca-id",
        pinSessionToken: "pin-session-token",
        mdvmPrivateKey: makeMockPrivateKey(),
        payload: makePayload()
      )

      #expect(response.rwscdKeyBindingSignature == "MEYCIQDmock-signature")
    }

    @Test("encodes payload as request body")
    func success_encodesPayloadAsBody() async throws {
      class SpyNetworkManager: FakeNetworkManager {
        var capturedBody: Data?
        override func execute<R: NetworkRequest>(
          with request: R,
          parameters: [NetworkParameter]?
        ) async throws -> NetworkResponse {
          capturedBody = (request as? RWSCASignDataRequest)?.body
          return try await super.execute(with: request, parameters: parameters)
        }
      }

      let spy = SpyNetworkManager()
      spy.mockResponse = NetworkResponse(data: try makeValidSignDataData(), headers: nil)
      let payload = makePayload()
      let sut = makeSUT(networkManager: spy)

      _ = try await sut.signData(
        mdvmToken: "mdvm-token",
        challenge: "challenge",
        rwscaID: "rwsca-id",
        pinSessionToken: "pin-session-token",
        mdvmPrivateKey: makeMockPrivateKey(),
        payload: payload
      )

      let capturedPayload = try JSONDecoder().decode(RWSCASignDataPayload.self, from: spy.capturedBody!)
      #expect(capturedPayload == payload)
    }

    @Test("sends pin session token header")
    func success_sendsPinSessionTokenHeader() async throws {
      class SpyNetworkManager: FakeNetworkManager {
        var capturedHeaders: [String: String] = [:]
        override func execute<R: NetworkRequest>(
          with request: R,
          parameters: [NetworkParameter]?
        ) async throws -> NetworkResponse {
          capturedHeaders = (request as? RWSCASignDataRequest)?.additionalHeaders ?? [:]
          return try await super.execute(with: request, parameters: parameters)
        }
      }

      let spy = SpyNetworkManager()
      spy.mockResponse = NetworkResponse(data: try makeValidSignDataData(), headers: nil)
      let signingService = makeSigningServiceMock(
        signatureHeaders: [
          RWSCAConstants.Header.authChallenge: "challenge",
          RWSCAConstants.Header.mdvmToken: "mdvm-token",
          RWSCAConstants.Header.rwscaAccountId: "rwsca-id",
          RWSCAConstants.Header.rwscaPinSessionToken: "pin-session-token",
          MDVMConstants.Header.contentDigest: "sha-256=:mock-digest:",
          MDVMConstants.Header.signatureInput: "rwsca-auth-sig=mock-signature-input",
          MDVMConstants.Header.signature: "rwsca-auth-sig=:mock-signature:"
        ]
      )
      let sut = makeSUT(networkManager: spy, httpSignatureService: signingService)

      _ = try await sut.signData(
        mdvmToken: "mdvm-token",
        challenge: "challenge",
        rwscaID: "rwsca-id",
        pinSessionToken: "pin-session-token",
        mdvmPrivateKey: makeMockPrivateKey(),
        payload: makePayload()
      )

      #expect(spy.capturedHeaders[RWSCAConstants.Header.rwscaPinSessionToken] == "pin-session-token")
      #expect(spy.capturedHeaders[MDVMConstants.Header.signatureInput]?.contains(RWSCAConstants.Signature.nameAuthSig) == true)
    }

    @Test("maps missing signed header errors")
    func missingSignedHeader_throwsRepositoryError() async throws {
      let signingService = makeSigningServiceMock()
      stub(signingService) { stub in
        when(
          stub.makeSignatureHeaders(context: any(), signatures: signatures(count: 1))
        ).thenThrow(HTTPMessageSigningError.missingSignedHeader("rwsca-pin-session-token"))
      }
      let sut = makeSUT(httpSignatureService: signingService)

      await #expect(throws: RWSCARepositoryError.missingSignedHeader("rwsca-pin-session-token")) {
        try await sut.signData(
          mdvmToken: "mdvm-token",
          challenge: "challenge",
          rwscaID: "rwsca-id",
          pinSessionToken: "pin-session-token",
          mdvmPrivateKey: makeMockPrivateKey(),
          payload: makePayload()
        )
      }
    }

    @Test("throws decodingFailed when response is malformed JSON")
    func malformedResponse_throwsDecodingFailed() async throws {
      let network = FakeNetworkManager()
      network.mockResponse = NetworkResponse(data: "not-json".data(using: .utf8), headers: nil)
      let sut = makeSUT(networkManager: network)

      await #expect(throws: RWSCARepositoryError.decodingFailed) {
        try await sut.signData(
          mdvmToken: "mdvm-token",
          challenge: "challenge",
          rwscaID: "rwsca-id",
          pinSessionToken: "pin-session-token",
          mdvmPrivateKey: makeMockPrivateKey(),
          payload: makePayload()
        )
      }
    }

    @Test("throws invalidResponse when network returns nil data")
    func nilData_throwsInvalidResponse() async throws {
      let network = FakeNetworkManager()
      network.mockResponse = NetworkResponse(data: nil, headers: nil)
      let sut = makeSUT(networkManager: network)

      await #expect(throws: RWSCARepositoryError.invalidResponse) {
        try await sut.signData(
          mdvmToken: "mdvm-token",
          challenge: "challenge",
          rwscaID: "rwsca-id",
          pinSessionToken: "pin-session-token",
          mdvmPrivateKey: makeMockPrivateKey(),
          payload: makePayload()
        )
      }
    }

    @Test("throws serverError when API returns error payload")
    func serverError_throwsServerError() async throws {
      let network = FakeNetworkManager()
      network.mockResponse = NetworkResponse(data: try makeServerErrorData(
        code: "SIGN_FAIL",
        description: "Sign denied",
        traceID: "trace-sign"
      ), headers: nil)
      let sut = makeSUT(networkManager: network)

      await #expect(throws: RWSCARepositoryError.serverError(
        code: "SIGN_FAIL",
        description: "Sign denied",
        traceID: "trace-sign"
      )) {
        try await sut.signData(
          mdvmToken: "mdvm-token",
          challenge: "challenge",
          rwscaID: "rwsca-id",
          pinSessionToken: "pin-session-token",
          mdvmPrivateKey: makeMockPrivateKey(),
          payload: makePayload()
        )
      }
    }

    @Test("propagates network errors")
    func networkFailure_propagates() async throws {
      let network = FakeNetworkManager()
      network.error = URLError(.timedOut)
      let sut = makeSUT(networkManager: network)

      await #expect(throws: URLError.self) {
        try await sut.signData(
          mdvmToken: "mdvm-token",
          challenge: "challenge",
          rwscaID: "rwsca-id",
          pinSessionToken: "pin-session-token",
          mdvmPrivateKey: makeMockPrivateKey(),
          payload: makePayload()
        )
      }
    }
  }

  @Suite("deleteAccount")
  struct DeleteAccountTests {

    @Test("succeeds on 204 no-content response and clears local RWSCA state")
    func success_clearsStoredState() async throws {
      let network = FakeNetworkManager()
      network.mockResponse = NetworkResponse(data: nil, headers: nil)
      let secureEnclave = FakeSecureEnclaveController()
      _ = secureEnclave.storeStringInKeychain(value: "account-123", keyTag: .rwscaAccountID)
      let sut = makeSUT(networkManager: network, secureEnclaveController: secureEnclave)

      try await sut.deleteAccount(
        mdvmToken: "mdvm-token",
        challenge: "challenge",
        rwscaID: "account-123",
        mdvmPrivateKey: makeMockPrivateKey()
      )

      #expect(sut.getRWSCAID() == nil)
    }

    @Test("sends delete signature headers")
    func success_sendsDeleteSignatureHeaders() async throws {
      class SpyNetworkManager: FakeNetworkManager {
        var capturedHeaders: [String: String] = [:]
        override func execute<R: NetworkRequest>(
          with request: R,
          parameters: [NetworkParameter]?
        ) async throws -> NetworkResponse {
          capturedHeaders = (request as? RWSCADeleteAccountRequest)?.additionalHeaders ?? [:]
          return try await super.execute(with: request, parameters: parameters)
        }
      }

      let spy = SpyNetworkManager()
      spy.mockResponse = NetworkResponse(data: nil, headers: nil)
      let signingService = makeSigningServiceMock(
        signatureHeaders: [
          MDVMConstants.Header.signatureInput: "rwsca-auth-sig=mock-signature-input",
          MDVMConstants.Header.signature: "rwsca-auth-sig=:mock-signature:"
        ]
      )
      let sut = makeSUT(networkManager: spy, httpSignatureService: signingService)

      try await sut.deleteAccount(
        mdvmToken: "mdvm-token",
        challenge: "challenge",
        rwscaID: "account-123",
        mdvmPrivateKey: makeMockPrivateKey()
      )

      #expect(spy.capturedHeaders[MDVMConstants.Header.signature]?.contains(RWSCAConstants.Signature.nameAuthSig) == true)
      #expect(spy.capturedHeaders[MDVMConstants.Header.signatureInput] != nil)
    }

    @Test("throws serverError when API returns an error payload")
    func serverError_throwsServerError() async throws {
      let network = FakeNetworkManager()
      network.mockResponse = NetworkResponse(data: try makeServerErrorData(
        code: "DELETE_FAIL",
        description: "Delete denied",
        traceID: "trace-delete"
      ), headers: nil)
      let secureEnclave = FakeSecureEnclaveController()
      _ = secureEnclave.storeStringInKeychain(value: "account-123", keyTag: .rwscaAccountID)
      let sut = makeSUT(networkManager: network, secureEnclaveController: secureEnclave)

      await #expect(throws: RWSCARepositoryError.serverError(
        code: "DELETE_FAIL",
        description: "Delete denied",
        traceID: "trace-delete"
      )) {
        try await sut.deleteAccount(
          mdvmToken: "mdvm-token",
          challenge: "challenge",
          rwscaID: "account-123",
          mdvmPrivateKey: makeMockPrivateKey()
        )
      }

      #expect(sut.getRWSCAID() == "account-123")
    }

    @Test("throws signingFailed when signature service throws")
    func signingFailure_throwsSigningFailed() async throws {
      let signingService = makeSigningServiceMock()
      stub(signingService) { stub in
        when(
          stub.makeSignatureHeaders(context: any(), signatures: signatures(count: 1))
        ).thenThrow(HTTPMessageSigningError.signingFailed)
      }
      let sut = makeSUT(httpSignatureService: signingService)

      await #expect(throws: RWSCARepositoryError.signingFailed) {
        try await sut.deleteAccount(
          mdvmToken: "mdvm-token",
          challenge: "challenge",
          rwscaID: "account-123",
          mdvmPrivateKey: makeMockPrivateKey()
        )
      }
    }

    @Test("propagates network errors")
    func networkFailure_propagates() async throws {
      let network = FakeNetworkManager()
      network.error = URLError(.timedOut)
      let sut = makeSUT(networkManager: network)

      await #expect(throws: URLError.self) {
        try await sut.deleteAccount(
          mdvmToken: "mdvm-token",
          challenge: "challenge",
          rwscaID: "account-123",
          mdvmPrivateKey: makeMockPrivateKey()
        )
      }
    }
  }
}

private final class FakeSecureEnclaveController: SecureEnclaveController {
  private var stringStorage: [SecureEnclaveKeys: String] = [:]

  func createPrivateKey(with keyTag: SecureEnclaveKeys) -> SecKey? { nil }
  func storePrivateKey(_ privateKey: SecKey, with keyTag: SecureEnclaveKeys) -> Bool { false }
  func retrievePrivateKey(with keyTag: SecureEnclaveKeys) -> SecKey? { nil }
  func deletePrivateKey(with keyTag: SecureEnclaveKeys) -> Bool { true }

  @discardableResult
  func storeStringInKeychain(value: String, keyTag: SecureEnclaveKeys) -> Bool {
    stringStorage[keyTag] = value
    return true
  }

  func retrieveStringFromKeychain(keyTag: SecureEnclaveKeys) -> String? {
    stringStorage[keyTag]
  }

  // The fake does not actually encrypt; it shares the same backing store as the plain variants.
  @discardableResult
  func storeEncryptedString(value: String, keyTag: SecureEnclaveKeys) -> Bool {
    stringStorage[keyTag] = value
    return true
  }

  func retrieveDecryptedString(keyTag: SecureEnclaveKeys) -> String? {
    stringStorage[keyTag]
  }

  func deleteKeychainItem(keyTag: SecureEnclaveKeys) {
    stringStorage.removeValue(forKey: keyTag)
  }

  func generateECPrivateKey(from pin: String, and salt: String) throws -> SecKey {
    throw NSError(domain: "unused", code: -1)
  }

  func generatePublicKey(from privateKey: SecKey) throws -> SecKey {
    throw NSError(domain: "unused", code: -1)
  }

  func getOrCreatePrivateKey(with keyTag: SecureEnclaveKeys) throws -> SecKey {
    throw NSError(domain: "unused", code: -1)
  }

  func getPublicKeyInfo(from privateKey: SecKey) throws -> PublicKeyInfo {
    throw NSError(domain: "unused", code: -1)
  }
}
