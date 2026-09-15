//
//  PARInteractorTests.swift
//  PARInteractorTests
//
//  Created by Tamas Dancsi  on 05.05.26.
//

import XCTest
import Cuckoo
import logic_core
@testable import feature_common

final class PARInteractorTests: XCTestCase {

  private var walletPoPController: MockWalletPoPController!
  private var walletKitController: MockWalletKitController!
  private var secureEnclaveController: MockSecureEnclaveController!
  private var sut: PARInteractorImpl!

  override func setUp() {
    super.setUp()

    walletPoPController = MockWalletPoPController()
    walletKitController = MockWalletKitController()
    secureEnclaveController = MockSecureEnclaveController()
    sut = PARInteractorImpl(
      walletPoPInteractor: walletPoPController,
      walletKitController: walletKitController,
      secureEnclaveController: secureEnclaveController
    )
  }

  override func tearDown() {
    sut = nil
    secureEnclaveController = nil
    walletKitController = nil
    walletPoPController = nil

    super.tearDown()
  }

  func testIssuePAR_WhenWalletReturnsDocument_ThenReturnsDocument() async throws {
    let document = makeDocument()

    stub(walletKitController) { mock in
      when(mock.issuePAR()).thenReturn(document)
    }

    let result = try await sut.issuePAR()

    XCTAssertEqual(result.id, document.id)
    verify(walletKitController).issuePAR()
  }

  func testIssuePAR_WhenWalletReturnsNil_ThenThrowsWIAPARCreationFailed() async {
    stub(walletKitController) { mock in
      when(mock.issuePAR()).thenReturn(nil)
    }

    do {
      _ = try await sut.issuePAR()
      XCTFail("Expected PARGenerationError.wiaParCreationFailed")
    } catch let error as PARGenerationError {
      XCTAssertEqual(error, .wiaParCreationFailed)
    } catch {
      XCTFail("Unexpected error: \(error)")
    }

    verify(walletKitController).issuePAR()
  }

  private func makeDocument() -> WalletStorage.Document {
    WalletStorage.Document(
      id: "par-document",
      docType: "testType",
      docDataFormat: .cbor,
      data: Data(),
      docKeyInfo: nil,
      createdAt: nil,
      metadata: nil,
      displayName: "Test Document",
      status: .pending
    )
  }
}
