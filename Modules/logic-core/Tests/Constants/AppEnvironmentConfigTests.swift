//
//  AppEnvironmentConfigTests.swift
//  logic-core-tests
//

import Foundation
import Testing
import logic_resources
@testable import logic_core

/// Guards the contract between the localized link keys in the xcconfigs, Wallet.plist and the languages
/// the resources bundle ships. `AppEnvironment` resolves `<KEY>_<LANG>` at runtime, so any drift between
/// these three places silently yields a `nil` link in one build variant or language.
struct AppEnvironmentConfigTests {

  private static let variants = ["Dev", "Staging", "Sandbox", "Prod"]
  private static let languageSuffixes = ["EN", "DE"]
  private static let emptyKeys = ["PID_PRIVACY_POLICY_LINK_EN", "PID_PRIVACY_POLICY_LINK_DE"]

  // MARK: - xcconfig

  @Test(arguments: variants)
  func xcconfig_WhenLinkKeyIsLocalized_ThenEveryLanguageHasAValue(variant: String) throws {
    let settings = try Self.xcconfigSettings(variant: variant)

    for base in Self.localizedLinkBases(in: settings.keys) {
      for suffix in Self.languageSuffixes where !Self.emptyKeys.contains("\(base)_\(suffix)") {
        let value = settings["\(base)_\(suffix)"]
        #expect(value?.isEmpty == false, "\(variant): missing \(base)_\(suffix)")
      }
    }
  }

  @Test(arguments: variants)
  func xcconfig_WhenLinkIsLocalized_ThenEveryLanguageResolvesToAnHTTPSURL(variant: String) throws {
    let settings = try Self.xcconfigSettings(variant: variant)

    for base in Self.localizedLinkBases(in: settings.keys) {
      for suffix in Self.languageSuffixes where !Self.emptyKeys.contains("\(base)_\(suffix)") {
        guard let value = settings["\(base)_\(suffix)"], !value.hasPrefix("PLACEHOLDER_") else { continue }
        let url = URL(string: Self.xcconfigResolved(value))
        #expect(url?.scheme == "https", "\(variant): \(base)_\(suffix) resolves to \(Self.xcconfigResolved(value))")
        #expect(url?.host()?.isEmpty == false, "\(variant): \(base)_\(suffix) has no host")
      }
    }
  }

  @Test(arguments: variants)
  func xcconfig_WhenLinkIsLocalized_ThenEnglishLinkPointsToEnglishPage(variant: String) throws {
    let settings = try Self.xcconfigSettings(variant: variant)

    for base in Self.localizedLinkBases(in: settings.keys) where !Self.emptyKeys.contains("\(base)_EN") {
      guard let value = settings["\(base)_EN"], !value.hasPrefix("PLACEHOLDER_") else { continue }
      #expect(value.contains("/en/"), "\(variant): \(base)_EN points to \(value)")
    }
  }

  @Test(arguments: variants)
  func xcconfig_WhenLinkIsLocalized_ThenGermanLinkDiffersFromEnglishAndIsNotEnglish(variant: String) throws {
    let settings = try Self.xcconfigSettings(variant: variant)

    for base in Self.localizedLinkBases(in: settings.keys) where !Self.emptyKeys.contains("\(base)_DE") {
      guard let value = settings["\(base)_DE"], !value.hasPrefix("PLACEHOLDER_") else { continue }
      #expect(!value.contains("/en/"), "\(variant): \(base)_DE points to \(value)")
      #expect(value != settings["\(base)_EN"], "\(variant): \(base)_DE is the same as \(base)_EN")
    }
  }

  @Test(arguments: variants)
  func xcconfig_WhenLinkKeyIsLocalized_ThenNoUnlocalizedKeyRemains(variant: String) throws {
    let settings = try Self.xcconfigSettings(variant: variant)

    for base in Self.localizedLinkBases(in: settings.keys) {
      #expect(settings[base] == nil, "\(variant): \(base) is dead config, only \(base)_<LANG> is read")
    }
  }

  // MARK: - Wallet.plist

  @Test(arguments: variants)
  func plist_WhenXcconfigDefinesLocalizedLink_ThenPlistForwardsIt(variant: String) throws {
    let settings = try Self.xcconfigSettings(variant: variant)
    let plist = try Self.walletPlist()

    for base in Self.localizedLinkBases(in: settings.keys) {
      for suffix in Self.languageSuffixes {
        let key = "\(base)_\(suffix)"
        #expect(plist[key] as? String == "$(\(key))", "Wallet.plist does not forward \(key)")
      }
    }
  }

  @Test(arguments: variants)
  func plist_WhenPlistForwardsLocalizedLink_ThenEveryVariantDefinesIt(variant: String) throws {
    let settings = try Self.xcconfigSettings(variant: variant)
    let plist = try Self.walletPlist()

    for key in Self.localizedLinkKeys(in: plist.keys) where !Self.emptyKeys.contains(key) {
      #expect(settings[key]?.isEmpty == false, "\(variant) does not define \(key) forwarded by Wallet.plist")
    }
  }

  // MARK: - Resources bundle

  @Test
  func resourcesBundle_WhenInspected_ThenDevelopmentLocalizationIsEnglish() {
    #expect(Bundle.assetsBundle.developmentLocalization == "en")
  }

  @Test
  func resourcesBundle_WhenInspected_ThenEveryShippedLanguageHasALinkSuffix() {
    let shipped = Set(Bundle.assetsBundle.localizations).subtracting(["Base"]).map { $0.uppercased() }

    #expect(Set(shipped) == Set(Self.languageSuffixes))
  }

  // MARK: - Runtime accessors outside the app host

  @Test
  func accessors_WhenHostBundleHasNoLinkKeys_ThenReturnNilInsteadOfCrashing() {
    #expect(AppEnvironment.privacyPolicyLink == nil)
    #expect(AppEnvironment.pidPrivacyPolicyLink == nil)
    #expect(AppEnvironment.termsAndConditionsLink == nil)
    #expect(AppEnvironment.faqLink == nil)
    #expect(AppEnvironment.aboutLink == nil)
    #expect(AppEnvironment.imprintLink == nil)
  }

  // MARK: - Helpers

  private static var repositoryRoot: URL {
    // <root>/Modules/logic-core/Tests/Constants/<this file>
    URL(fileURLWithPath: #filePath)
      .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
      .deletingLastPathComponent().deletingLastPathComponent()
  }

  private static func xcconfigSettings(variant: String) throws -> [String: String] {
    let url = repositoryRoot.appendingPathComponent("Wallet/Config/Wallet\(variant).xcconfig")
    let content = try String(contentsOf: url, encoding: .utf8)
    let pattern = #/^([A-Za-z_][A-Za-z0-9_]*)\s*=\s*(.*)$/#

    var settings: [String: String] = [:]
    for line in content.split(whereSeparator: \.isNewline) {
      guard let match = line.trimmingCharacters(in: .whitespaces).wholeMatch(of: pattern) else { continue }
      settings[String(match.1)] = String(match.2).trimmingCharacters(in: .whitespaces)
    }
    return settings
  }

  private static func xcconfigResolved(_ value: String) -> String {
    let uncommented = value.range(of: "//").map { String(value[..<$0.lowerBound]) } ?? value
    return uncommented.replacingOccurrences(of: "$()", with: "").trimmingCharacters(in: .whitespaces)
  }

  private static func walletPlist() throws -> [String: Any] {
    let url = repositoryRoot.appendingPathComponent("Wallet/Wallet.plist")
    let plist = try PropertyListSerialization.propertyList(from: Data(contentsOf: url), format: nil)
    return try #require(plist as? [String: Any])
  }

  private static func localizedLinkKeys<S: Sequence>(in keys: S) -> [String] where S.Element == String {
    keys.filter { key in key.contains("_LINK_") && languageSuffixes.contains { key.hasSuffix("_\($0)") } }
  }

  private static func localizedLinkBases<S: Sequence>(in keys: S) -> Set<String> where S.Element == String {
    Set(localizedLinkKeys(in: keys).map { key in
      let suffix = languageSuffixes.first { key.hasSuffix("_\($0)") } ?? ""
      return String(key.dropLast(suffix.count + 1))
    })
  }
}
