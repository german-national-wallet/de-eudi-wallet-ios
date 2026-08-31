//
//  EIDAttribute.swift
//  feature-issuance
//
import Foundation
import AusweisApp2SDKWrapper
import logic_ui

enum EIDAttribute: String, Equatable, Identifiable {
  case documentType // DG1
  case issuingCountry // DG2
  case validUntil // DG3
  case givenNames // DG4
  case familyName // DG5
  case artisticName // DG6
  case doctoralDegree // DG7
  case dateOfBirth // DG8
  case placeOfBirth // DG9
  case nationality // DG10
  case birthName // DG13
  case address // DG17
  case communityID // DG18
  case residencePermitI // DG19
  case residencePermitII // DG20
  
  case addressVerification
  case ageVerification
  case pseudonym
  case writeAddress
  case writeCommunityID
  case writeResidencePermitI
  case writeResidencePermitII
  case canAllowed
  case pinManagement
  
  var id: String { rawValue }
  
  var localizedTitle: String {
    switch self {
    case .documentType: return "Document type"
    case .issuingCountry: return "Issuing country"
    case .validUntil: return "Valid until"
    case .givenNames: return "Given name"
    case .familyName: return "Family name"
    case .artisticName: return "Artistic name"
    case .doctoralDegree: return "Doctor degree"
    case .dateOfBirth: return "Date of birth"
    case .placeOfBirth: return "Place of birth"
    case .nationality: return "Nationality"
    case .birthName: return "Birth name"
    case .address: return "Address"
    case .communityID: return "Community ID"
    case .residencePermitI: return "Residence permit ID I"
    case .residencePermitII: return "Residence permit ID II"
    case .addressVerification: return "Address Verification"
    case .ageVerification: return "Age Verification"
    case .pseudonym: return "Pseudonym"
    case .writeAddress: return "Address"
    case .writeCommunityID: return "Community ID"
    case .writeResidencePermitI: return "Residence permit ID I"
    case .writeResidencePermitII: return "Residence permit ID II"
    case .canAllowed: return "CAN Allowed"
    case .pinManagement: return "PIN management"
    }
  }
  
  init(_ accessRight: AccessRight) throws {
    switch accessRight {
    case .Address: self = .address
    case .BirthName: self = .birthName
    case .FamilyName: self = .familyName
    case .GivenNames: self = .givenNames
    case .PlaceOfBirth: self = .placeOfBirth
    case .DateOfBirth: self = .dateOfBirth
    case .DoctoralDegree: self = .doctoralDegree
    case .ArtisticName: self = .artisticName
    case .Pseudonym: self = .pseudonym
    case .ValidUntil: self = .validUntil
    case .Nationality: self = .nationality
    case .IssuingCountry: self = .issuingCountry
    case .DocumentType: self = .documentType
    case .ResidencePermitI: self = .residencePermitI
    case .ResidencePermitII: self = .residencePermitII
    case .CommunityID: self = .communityID
    case .AddressVerification: self = .addressVerification
    case .AgeVerification: self = .ageVerification
    case .WriteAddress: self = .writeAddress
    case .WriteCommunityID: self = .writeCommunityID
    case .WriteResidencePermitI: self = .writeResidencePermitI
    case .WriteResidencePermitII: self = .writeResidencePermitII
    case .CanAllowed: self = .canAllowed
    case .PinManagement: self = .pinManagement
    @unknown default: throw EIDInteractionError.unexpectedReadAttribute(accessRight.rawValue)
    }
  }
}
