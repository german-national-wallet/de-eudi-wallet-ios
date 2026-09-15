//
//  TestIssuanceCardRemoteRepository.swift
//  feature-issuance
//
//  Created by Pankaj Sachdeva on 17.10.24.
//

import XCTest
@testable import feature_issuance
@testable import logic_core
@testable import logic_test
@testable import logic_api

final class TestIssuanceCardRemoteRepository: XCTestCase {

    var mockNetworkManager: FakeNetworkManager!
    var sut: IssuanceCardRemoteRepositoryImpl!

    override func setUp() {
        super.setUp()
        
        mockNetworkManager = FakeNetworkManager()
        sut = IssuanceCardRemoteRepositoryImpl(networkManager: mockNetworkManager)
    }
    
    override func tearDown() {
        mockNetworkManager = nil
        sut = nil
        super.tearDown()
    }
    
    func testExecuteFinishAuthorizationRequest_ShouldReturnFinishAuthorization() async throws {
            let testURL = "https://example.com"
        let expectedHeaders = ["dpop-nonce": "test_nonce", "Location": "https://uri.example.com?code=GqQesNtf6TGDZhuYkL40rX&state=OseoFDv8JE3mi5hNTU7H_TJvcs0kVWAl"]
            
        mockNetworkManager.mockResponse = NetworkResponse(data: nil, headers: expectedHeaders)
            
            let result = try await sut.executeFinishAuthorizationRequest(with: testURL)
         
        XCTAssertNotNil(result)
        XCTAssertEqual(result.nonce, expectedHeaders["dpop-nonce"])
    }
    
    func testExecuteFinishAuthorizationRequest_ShouldThrowErrorForInvalidResponse() async {
        let testURL = "https://example.com"
        
        do {
            _ = try await sut.executeFinishAuthorizationRequest(with: testURL)
            XCTFail("Expected error to be thrown, but no error was thrown.")
        } catch let error as NetworkError {
            XCTAssertEqual(error, NetworkError.invalidResponse)
        } catch {
            XCTFail("Unexpected error thrown: \(error)")
        }
    }
    
    func testExecuteFinishAuthorizationRequest_ShouldThrowNetworkError() async {
        let testURL = "https://example.com"
        
        // Set up the mock to throw an error
        mockNetworkManager.error = NetworkError.invalidUrl
        
        do {
            _ = try await sut.executeFinishAuthorizationRequest(with: testURL)
            XCTFail("Expected error to be thrown, but no error was thrown.")
        } catch let error as NetworkError {
            XCTAssertEqual(error, NetworkError.invalidUrl)
        } catch {
            XCTFail("Unexpected error thrown: \(error)")
        }
    }
    
}
