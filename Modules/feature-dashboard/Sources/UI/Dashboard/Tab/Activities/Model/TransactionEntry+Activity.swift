//
//  TransactionEntry+Activity.swift
//  feature-dashboard
//
//  Created by Pankaj Sachdeva on 02.10.26.
//

import Foundation
import logic_core
import logic_resources

extension TransactionEntry {

  static func isPid(_ identifier: String) -> Bool {
    switch DocumentTypeIdentifier(rawValue: identifier) {
    case .mDocPid, .sdJwtPid: true
    default: false
    }
  }

  var typeTitle: LocalizableStringKey {
    switch self {
    case .credentialIssuance, .credentialReissuance: .activitiesLogTypeIssuance
    case .credentialDeletion: .activitiesLogTypeDeletion
    default: .activitiesLogTypePresentation
    }
  }

  func displayTitle(_ names: [String: String]) -> String {
    switch self {
    case .presentation(let presentation):
      if let name = presentation.interactingPartyName?.content, !name.isEmpty { return name }
      return LocalizableStringKey.activitiesLogUnknownParty.toString
    case .credentialIssuance(let issuance):
      var seen = Set<String>()
      return issuance.details.credentialIdentifier
        .map { Self.credentialName($0, names: names) }
        .filter { seen.insert($0).inserted }
        .joined(separator: ", ")
    case .credentialDeletion(let deletion):
      return Self.credentialName(deletion.credentialIdentifier, names: names)
    default:
      return typeTitle.toString
    }
  }

  func listTitle(_ names: [String: String]) -> String {
    switch self {
    case .credentialIssuance, .credentialReissuance:
      LocalizableStringKey.activitiesLogCredentialCreated([displayTitle(names)]).toString
    case .credentialDeletion:
      LocalizableStringKey.activitiesLogCredentialDeleted([displayTitle(names)]).toString
    default:
      displayTitle(names)
    }
  }

  /// `docType` or `vct` mapped to a readable name where the app knows one.
  static func credentialName(_ identifier: String, names: [String: String]) -> String {
    if isPid(identifier) { return LocalizableStringKey.dashboardCardTitle.toString }
    return names[identifier].flatMap { $0.isEmpty ? nil : $0 } ?? identifier
  }
}

enum ActivityDateFormatter {

  static var appLocale: Locale {
    Locale(identifier: Locale.preferredLanguages.first?.components(separatedBy: "-").first ?? "en")
  }

  static func time(_ date: Date, locale: Locale = appLocale) -> String {
    let time = date.formatted(Date.FormatStyle(date: .omitted, time: .shortened).locale(locale))
    return LocalizableStringKey.activitiesLogTime([time]).toString
  }

  static func date(_ date: Date) -> String {
    dateFormatter.string(from: date)
  }

  private static let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.dateFormat = "dd.MM.yyyy"
    return formatter
  }()

  static func dateTime(_ date: Date, locale: Locale = appLocale) -> String {
    "\(self.date(date)) · \(time(date, locale: locale))"
  }
}
