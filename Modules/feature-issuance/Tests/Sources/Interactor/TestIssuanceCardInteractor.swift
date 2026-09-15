//
//  TestIssuanceCardInteractor.swift
//  feature-issuance
//
//  Created by Pankaj Sachdeva on 17.10.24.
//


@testable import logic_test
@testable import feature_issuance
@testable import logic_api
@testable import feature_common

final class TestIssuanceCardInteractor: XCTestCase {

    var sut: IssuanceCardInteractor!
    var mockIssuanceCardRemoteRepository: MockIssuanceCardRemoteRepository!
    var mockWalletController: MockWalletKitController!
    var mockWalletPoPInteractor: MockWalletPoPController!
    var mockSecureEnclaveController: MockSecureEnclaveController!
    
    override func setUp() {
        mockIssuanceCardRemoteRepository = MockIssuanceCardRemoteRepository()
        mockWalletController = MockWalletKitController()
        mockWalletPoPInteractor = MockWalletPoPController()
        mockSecureEnclaveController = MockSecureEnclaveController()
        
        sut = IssuanceCardInteractorImpl(
            issuanceCardRemoteRepository: mockIssuanceCardRemoteRepository,
            walletController: mockWalletController,
            secureEnclaveController: mockSecureEnclaveController
        )
    }

    override func tearDown() {
        mockIssuanceCardRemoteRepository = nil
        mockWalletController = nil
        mockWalletPoPInteractor = nil
        mockSecureEnclaveController = nil
        sut = nil
        super.tearDown()
    }

    func testExecuteFinishAuthorizationRequest_Success() async throws {
        do {
            let testURL = "https://test-par-url.de"
            let expectedResponse = FinishAuthorizationResponse(nonce: "dpop_nonce", code: "test", state: "test", location: "test")
            
            stub(mockIssuanceCardRemoteRepository) { stub in
                when(stub.executeFinishAuthorizationRequest(with: equal(to: testURL))).thenReturn(expectedResponse)
            }
            
            let result = try await sut.executeFinishAuthorizationRequest(testURL)
            XCTAssertTrue(result.nonce == expectedResponse.nonce)
            verify(mockIssuanceCardRemoteRepository).executeFinishAuthorizationRequest(with: equal(to: testURL))
        }
        catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testExecuteFinishAuthorizationRequest_ThrowsError() async {
        let testURL = "http://test-par-url.de"
        let expectedError = NetworkError.invalidResponse
        
        stub(mockIssuanceCardRemoteRepository) { stub in
            when(stub.executeFinishAuthorizationRequest(with: equal(to: testURL))).thenThrow(expectedError)
        }
        
        do {
            _ = try await sut.executeFinishAuthorizationRequest(testURL)
            XCTFail("Expected error but got success")
        } catch let error as NetworkError {
            XCTAssert(true)
        } catch let error as NSError {
            XCTFail("Expected NetworkError but got generic error: \(error)")
        }
        
        verify(mockIssuanceCardRemoteRepository).executeFinishAuthorizationRequest(with: equal(to: testURL))
    }
}
