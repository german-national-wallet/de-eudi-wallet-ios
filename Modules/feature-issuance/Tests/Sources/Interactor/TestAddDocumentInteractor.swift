//
//  TestAddDocumentInteractor.swift
//  feature-issuance
//
//  Created by Pankaj Sachdeva on 17.10.24.
//

import XCTest

@testable import logic_core
@testable import logic_test
@testable import feature_issuance
@testable import EudiWalletKit
@testable import feature_test
@testable import logic_business

import OpenID4VCI
import JOSESwift


final class TestAddDocumentInteractor: XCTestCase {
    var sut: AddDocumentInteractorImpl!
    var mockWalletController: MockWalletKitController!
    var mockSecureEnclaveController: MockSecureEnclaveController!
    
    override func setUp() {
        mockWalletController = MockWalletKitController()
        mockSecureEnclaveController = MockSecureEnclaveController()
        sut = AddDocumentInteractorImpl(
            walletController: mockWalletController,
            secureEnclaveController: mockSecureEnclaveController
        )
    }

    override func tearDown() {
        mockWalletController = nil
        mockSecureEnclaveController = nil
        sut = nil
        super.tearDown()
    }
    
    func testFetchStoredDocuments_Success_ForExtraDocument() async {
        let mockScopedDocument = ScopedDocument(name: "", issuer: "", configId: "", isPid: true, docTypeIdentifier: .mDocPid)
        stub(mockWalletController) { stub in
            when(stub.getScopedDocuments()).thenReturn([mockScopedDocument])
        }
        
        let mockDock = MockDocClaimsDecodable()
        
        stub(mockWalletController) { stub in
            when(stub.fetchDocuments(with: equal(to: ["test"]))).thenReturn([mockDock])
        }
        
        let result = await sut.fetchStoredDocuments(documentIds: ["test"])
        switch result {
        case .success(let documents):
            XCTAssert(documents.count == 1)
        case .failure(_):
            XCTFail("PAR failed")
        }
    }

    struct MockDocClaimsDecodable: DocClaimsDecodable {
        var id: String = "mock-id"
        var createdAt: Date = Date()
        var modifiedAt: Date? = Date()
        var displayName: String? = "Mock Document"
        var display: [DisplayMetadata]? = [DisplayMetadata(name: "Mock Display")]
        var issuerDisplay: [DisplayMetadata]? = [DisplayMetadata(name: "Issuer Display")]
        var credentialIssuerIdentifier: String? = "mock-issuer-id"
        var configurationIdentifier: String? = "mock-config-id"
        var docType: String = "mock-doc-type"
        var docClaims: [DocClaim] = [DocClaim(name: "name", dataValue: .string("name"), stringValue: "name")]
        var docDataFormat: DocDataFormat = .sdjwt
        var validFrom: Date? = Date()
        var validUntil: Date? = Calendar.current.date(byAdding: .year, value: 1, to: Date())
        var statusIdentifier: MdocDataModel18013.StatusIdentifier?
        var secureAreaName: String?
        var credentialsUsageCounts: MdocDataModel18013.CredentialsUsageCounts?
        var credentialPolicy: MdocDataModel18013.CredentialPolicy = .oneTimeUse

        // AgeAttesting conformance
        var ageOverXX: [Int: Bool] = [18: true, 21: false]
        
        func getValue(for claim: String) -> String? {
            return "mock-value"
        }
        
        func getValueAsDate(for claim: String) -> Date? {
            return Date()
        }
        
        func getValueAsImage(for claim: String) -> Data? {
            return nil
        }
        
        func hasExpired() -> Bool {
            return false
        }
    }
    
    let jsonPendingIssuanceModel = """
    {
      "identifier": {
        "value": "pid-mso-mdoc"
      },
      "displayName": "",
      "pckeCodeVerifierMethod": "S256",
      "pckeCodeVerifier": "Pslym_C3WJY2JQdk70J5iniVBAKkWJ2nkH5SFa2PCU7",
      "metadataKey": "56010BD8-9763-4806-8ED0-4CC59994581B",
      "pendingReason": {
        "presentation_request_url":{
      "_0": "https://demo.pid-issuer.de/c1/authorize?client_id=fed79862-af36-4fee-8e64-89e3c91091ed&request_uri=urn:ietf:params:oauth:request_uri:ZO0WX1ksEgn1e4SnzcrJlb&state=CCB9ncAMkm2sJcDbzNbn8ZIR0-hu1FAg"
    }
      }
    }
    """
}
