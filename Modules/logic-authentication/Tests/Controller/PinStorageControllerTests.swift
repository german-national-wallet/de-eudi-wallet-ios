//
//  PinStorageControllerTests.swift
//  PinStorageControllerTests
//
//  Created by Tamas Dancsi  on 05.05.26.
//

import XCTest
import Cuckoo
@testable import logic_authentication

final class PinStorageControllerTests: XCTestCase {

  private var provider: MockPinStorageProvider!
  private var sut: PinStorageControllerImpl!

  override func setUp() {
    super.setUp()

    provider = MockPinStorageProvider()
    sut = PinStorageControllerImpl(provider: provider)
  }

  override func tearDown() {
    sut = nil
    provider = nil

    super.tearDown()
  }

  func testRetrievePIN_WhenProviderHasPIN_ThenReturnsPIN() {
    let pin = "1234"

    stub(provider) { mock in
      when(mock.retrievePin()).thenReturn(pin)
    }

    let result = sut.retrievePin()

    XCTAssertEqual(result, pin)
    verify(provider).retrievePin()
  }

  func testSetPIN_WhenCalled_ThenDelegatesToProvider() {
    let pin = "1234"

    stub(provider) { mock in
      when(mock.setPin(with: any())).thenDoNothing()
    }

    sut.setPin(with: pin)

    verify(provider).setPin(with: equal(to: pin))
  }

  func testIsPINValid_WhenProviderReturnsTrue_ThenReturnsTrue() {
    let pin = "1234"

    stub(provider) { mock in
      when(mock.isPinValid(with: equal(to: pin))).thenReturn(true)
    }

    let result = sut.isPinValid(with: pin)

    XCTAssertTrue(result)
    verify(provider).isPinValid(with: equal(to: pin))
  }
}
