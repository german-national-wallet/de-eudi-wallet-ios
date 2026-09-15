//
//  PinSessionInteractorTests.swift
//  feature-common
//
//  Created by Pankaj Sachdeva on 23.04.26.
//

import Testing
import Cuckoo
import logic_api
import MdocDataModel18013

@testable import feature_common

@Suite
final class PinSessionInteractorTests {

  private var sut: PinSessionInteractor!

  private var mdvmInteractor: MockMDVMInteractor!
  private var rwscaInteractor: MockRWSCAInteractor!
  private var secureEnclaveController: MockSecureEnclaveController!

  init() {
    mdvmInteractor = MockMDVMInteractor()
    rwscaInteractor = MockRWSCAInteractor()
    secureEnclaveController = MockSecureEnclaveController()

    sut = PinSessionInteractorImpl(
      mdvmInteractor: mdvmInteractor,
      rwscaInteractor: rwscaInteractor,
      secureEnclaveController: secureEnclaveController
    )
  }

  // MARK: - SET PIN

  @Test
  func set_whenAllDependenciesSucceed_storesToken() async throws {
    // Given
    let pin = "1234"
    let mdvmToken = MDVMStoredRegistration(mdvmWIID: "mdvm_wiid", mdvmToken: "mdvm_token")
    let sessionToken = "session-token"

    stub(secureEnclaveController) { stub in
      when(stub.storeStringInKeychain(value: sessionToken, keyTag: equal(to: .pinSessionToken))).thenReturn(true)
    }

    stub(mdvmInteractor) { stub in
      when(stub.ensureFreshMDVMToken()).thenReturn(mdvmToken)
    }

    stub(rwscaInteractor) { stub in
      when(stub.register(mdvmStoredRegistration: equal(to: mdvmToken)))
        .thenDoNothing()

      when(stub.startPinSession(pin: pin))
        .thenReturn(RWSCAPinSessionResponse(rwscaPinSessionToken: sessionToken))

    }

    // When
    try await sut.set(pin: pin)

    // Then
    verify(rwscaInteractor).register(mdvmStoredRegistration: equal(to: mdvmToken))
    verify(rwscaInteractor).startPinSession(pin: pin)
    verify(secureEnclaveController).storeStringInKeychain(
      value: sessionToken,
      keyTag: equal(to: .pinSessionToken)
    )
  }

  @Test
  func set_whenMDVMTokenIsNil_doesNothing() async throws {
    // Given
    stub(mdvmInteractor) { stub in
      when(stub.ensureFreshMDVMToken()).thenReturn(nil)
    }

    // When
    try await sut.set(pin: "1234")

    // Then
    verify(rwscaInteractor, never()).register(mdvmStoredRegistration: any())
    verify(rwscaInteractor, never()).startPinSession(pin: any())
    verify(secureEnclaveController, never()).storeStringInKeychain(
      value: any(),
      keyTag: any()
    )
  }

  @Test
  func set_whenSessionTokenIsEmpty_throwsError() async {
    // Given
    let mdvmToken = MDVMStoredRegistration(mdvmWIID: "mdvm_wiid", mdvmToken: "mdvm_token")

    stub(mdvmInteractor) { stub in
      when(stub.ensureFreshMDVMToken()).thenReturn(mdvmToken)
    }

    stub(rwscaInteractor) { stub in
      when(stub.register(mdvmStoredRegistration: equal(to: mdvmToken)))
        .thenDoNothing()

      when(stub.startPinSession(pin: any()))
        .thenReturn(RWSCAPinSessionResponse(rwscaPinSessionToken: ""))
    }

    // When / Then
    await #expect(throws: SecureAreaError.self) {
      try await sut.set(pin: "1234")
    }

    verify(secureEnclaveController, never()).storeStringInKeychain(
      value: any(),
      keyTag: any()
    )
  }

  @Test
  func set_whenStartPinSessionThrows_propagatesError() async {
    // Given
    let mdvmToken = MDVMStoredRegistration(mdvmWIID: "mdvm_wiid", mdvmToken: "mdvm_token")
    let error = NSError(domain: "test", code: 1)

    stub(mdvmInteractor) { stub in
      when(stub.ensureFreshMDVMToken()).thenReturn(mdvmToken)
    }

    stub(rwscaInteractor) { stub in
      when(stub.register(mdvmStoredRegistration: equal(to: mdvmToken)))
        .thenDoNothing()

      when(stub.startPinSession(pin: any()))
        .thenThrow(error)
    }

    // When / Then
    await #expect(throws: NSError.self) {
      try await sut.set(pin: "1234")
    }
  }

  @Test
  func clear_deletesPinSessionToken() {
    stub(secureEnclaveController) { stub in
      when(stub.deleteKeychainItem(keyTag: equal(to: .pinSessionToken)))
        .thenDoNothing()
    }

    sut.clear()

    verify(secureEnclaveController).deleteKeychainItem(keyTag: equal(to: .pinSessionToken))
  }

}
