//
//  SemanticVersionTests.swift
//  logic-business
//
//  Created by Tamas Dancsi on 18.05.26.
//

import Testing

@testable import logic_business

struct SemanticVersionTests {

  @Test
  func init_WhenVersionIsValid_ParsesCoreComponents() throws {
    let version = try #require(SemanticVersion("1.2.3"))

    #expect(version.major == 1)
    #expect(version.minor == 2)
    #expect(version.patch == 3)
  }

  @Test
  func init_WhenVersionHasPrerelease_ParsesPrereleaseIdentifiers() throws {
    let version = try #require(SemanticVersion("1.0.0-alpha.1"))

    #expect(version.prereleaseIdentifiers == ["alpha", "1"])
  }

  @Test
  func init_WhenVersionIsInvalid_ReturnsNil() {
    #expect(SemanticVersion("1") == nil)
    #expect(SemanticVersion("1.2") == nil)
    #expect(SemanticVersion("01.2.3") == nil)
    #expect(SemanticVersion("1.2.3.4") == nil)
  }

  @Test
  func comparison_OrdersCoreVersionComponents() throws {
    let current = try #require(SemanticVersion("0.2.4"))
    let patchUpdate = try #require(SemanticVersion("0.2.5"))
    let minorUpdate = try #require(SemanticVersion("0.3.0"))
    let majorUpdate = try #require(SemanticVersion("1.0.0"))
    let previousVersion = try #require(SemanticVersion("0.9.9"))

    #expect(current < patchUpdate)
    #expect(current < minorUpdate)
    #expect(majorUpdate > previousVersion)
  }

  @Test
  func comparison_OrdersPrereleaseBeforeStableVersion() throws {
    let prerelease = try #require(SemanticVersion("1.0.0-alpha"))
    let stable = try #require(SemanticVersion("1.0.0"))

    #expect(prerelease < stable)
  }

  @Test
  func comparison_OrdersPrereleaseIdentifiers() throws {
    let alphaOne = try #require(SemanticVersion("1.0.0-alpha.1"))
    let alphaBeta = try #require(SemanticVersion("1.0.0-alpha.beta"))
    let beta = try #require(SemanticVersion("1.0.0-beta"))
    let betaTwo = try #require(SemanticVersion("1.0.0-beta.2"))

    #expect(alphaOne < alphaBeta)
    #expect(beta < betaTwo)
  }

  @Test
  func comparison_IgnoresBuildMetadata() throws {
    let buildOne = try #require(SemanticVersion("1.0.0+1"))
    let buildTwo = try #require(SemanticVersion("1.0.0+2"))

    #expect(buildOne == buildTwo)
  }
}
