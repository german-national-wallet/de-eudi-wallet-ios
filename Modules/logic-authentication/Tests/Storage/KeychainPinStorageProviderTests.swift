//
//  KeychainPinStorageProviderTests.swift
//  KeychainPinStorageProviderTests
//
//  Created by Tamas Dancsi  on 05.05.26.
//

import XCTest
import Cuckoo
@testable import logic_authentication

final class KeychainPinStorageProviderTests: XCTestCase {

  private var keyChainController: MockKeyChainController!
  private var sut: KeychainPinStorageProvider!

  override func setUp() {
    super.setUp()

    keyChainController = MockKeyChainController()
    sut = KeychainPinStorageProvider(keyChainController: keyChainController)
  }

  override func tearDown() {
    sut = nil
    keyChainController = nil

    super.tearDown()
  }

  func testRetrievePIN_WhenKeychainHasPIN_ThenReturnsPIN() {
    stub(keyChainController) { mock in
      when(mock.getValue(key: any())).thenReturn("123456")
    }

    let pin = sut.retrievePin()

    XCTAssertEqual(pin, "123456")
    verify(keyChainController).getValue(key: any())
  }

  func testSetPIN_WhenCalled_ThenStoresPINInKeychain() {
    stub(keyChainController) { mock in
      when(mock.storeValue(key: any(), value: equal(to: "123456"))).thenDoNothing()
    }

    sut.setPin(with: "123456")

    verify(keyChainController).storeValue(key: any(), value: equal(to: "123456"))
  }

  func testIsPINValid_WhenStoredPINMatches_ThenReturnsTrue() {
    stub(keyChainController) { mock in
      when(mock.getValue(key: any())).thenReturn("123456")
    }

    XCTAssertTrue(sut.isPinValid(with: "123456"))
    verify(keyChainController).getValue(key: any())
  }

  func testIsPINValid_WhenStoredPINDiffers_ThenReturnsFalse() {
    stub(keyChainController) { mock in
      when(mock.getValue(key: any())).thenReturn("123456")
    }

    XCTAssertFalse(sut.isPinValid(with: "654321"))
    verify(keyChainController).getValue(key: any())
  }
}
