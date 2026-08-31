//
//  OfferedDocModel.swift
//  logic-core
//

extension OfferedDocModel: @retroactive Equatable {
  public static func == (lhs: OfferedDocModel, rhs: OfferedDocModel) -> Bool {
    return lhs.credentialConfigurationIdentifier == rhs.credentialConfigurationIdentifier
    && lhs.docType == rhs.docType
    && lhs.scope == rhs.scope
    && lhs.displayName == rhs.displayName
    && lhs.algValuesSupported == rhs.algValuesSupported
  }
  var documentTypeIdentifier: DocumentTypeIdentifier {
    DocumentTypeIdentifier(rawValue: docTypeOrVct ?? "")
  }
}
