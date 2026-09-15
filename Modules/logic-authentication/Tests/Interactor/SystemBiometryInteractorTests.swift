//
//  SystemBiometryInteractorTests.swift
//  SystemBiometryInteractorTests
//
//  Created by Tamas Dancsi  on 05.05.26.
//

import XCTest
import Combine
import Cuckoo
@testable import logic_authentication

final class SystemBiometryInteractorTests: XCTestCase {

  private var controller: MockSystemBiometryController!
  private var sut: SystemBiometryInteractorImpl!
  private var cancellables: Set<AnyCancellable>!

  override func setUp() {
    super.setUp()

    controller = MockSystemBiometryController()
    sut = SystemBiometryInteractorImpl(
      with: controller,
      useTestDispatcher: true
    )
    cancellables = []
  }

  override func tearDown() {
    cancellables = nil
    sut = nil
    controller = nil

    super.tearDown()
  }

  func testAuthenticate_WhenControllerSucceeds_ThenPublishesAuthenticated() {
    stub(controller) { mock in
      when(mock.requestBiometricUnlock())
        .thenReturn(Just(()).setFailureType(to: SystemBiometryError.self).eraseToAnyPublisher())
    }

    let state = firstAuthenticateState()

    XCTAssertEqual(state, .authenticated)
    verify(controller).requestBiometricUnlock()
  }

  func testAuthenticate_WhenControllerFails_ThenPublishesFailure() {
    stub(controller) { mock in
      when(mock.requestBiometricUnlock())
        .thenReturn(Fail(error: SystemBiometryError.biometricError).eraseToAnyPublisher())
    }

    let state = firstAuthenticateState()

    XCTAssertEqual(state, .failure(.biometricError))
    verify(controller).requestBiometricUnlock()
  }

  private func firstAuthenticateState() -> BiometricsState? {
    let expectation = expectation(description: "Wait for biometric state")
    var state: BiometricsState?

    sut.authenticate()
      .sink {
        state = $0
        expectation.fulfill()
      }
      .store(in: &cancellables)

    wait(for: [expectation], timeout: 1)
    return state
  }
}
