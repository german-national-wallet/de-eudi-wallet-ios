//
//  SimulatedEIDCardKeyGeneratorTests.swift
//  feature-issuance
//
//  Created by Ameen Qadri on 13.10.26.
//

import XCTest
@testable import feature_issuance

final class SimulatedEIDCardKeyGeneratorTests: XCTestCase {

  private let ausweisAppDefaultPseudonymKey = [
    "308202050201003081ec06072a8648ce3d02013081e0020101302c06072a8648ce3d0101022100a9fb57dba1eea9bc3e660a909d838d726e3bf623d5",
    "2620282013481d1f6e5377304404207d5a0975fc2c3057eef67530417affe7fb8055c126dc5c6ce94a4b44f330b5d9042026dc5c6ce94a4b44f330b5",
    "d9bbd77cbf958416295cf7e1ce6bccdc18ff8c07b60441048bd2aeb9cb7e57cb2c4b482ffc81b7afb9de27e1e3bd23c23a4453bd9ace3262547ef835",
    "c3dac4fd97f8461a14611dc9c27745132ded8e545c1d54c72f046997022100a9fb57dba1eea9bc3e660a909d838d718c397aa3b561a6f7901e0e8297",
    "4856a70201010482010f3082010b02010104209ad0ad7f4dfaaa06988339fc31d3a111f4c7964ac7f377373a2454327c43e2ffa081e33081e0020101",
    "302c06072a8648ce3d0101022100a9fb57dba1eea9bc3e660a909d838d726e3bf623d52620282013481d1f6e5377304404207d5a0975fc2c3057eef6",
    "7530417affe7fb8055c126dc5c6ce94a4b44f330b5d9042026dc5c6ce94a4b44f330b5d9bbd77cbf958416295cf7e1ce6bccdc18ff8c07b60441048b",
    "d2aeb9cb7e57cb2c4b482ffc81b7afb9de27e1e3bd23c23a4453bd9ace3262547ef835c3dac4fd97f8461a14611dc9c27745132ded8e545c1d54c72f",
    "046997022100a9fb57dba1eea9bc3e660a909d838d718c397aa3b561a6f7901e0e82974856a7020101"
  ].joined()

  private let ausweisAppDefaultPseudonymKeyScalar = "9ad0ad7f4dfaaa06988339fc31d3a111f4c7964ac7f377373a2454327c43e2ff"

  func testGeneratePseudonymKeyHex_WhenScalarIsDefaultKeyScalar_ThenReproducesAusweisAppDefaultKey() throws {
    let scalar = bytes(fromHex: ausweisAppDefaultPseudonymKeyScalar)
    let sut = SimulatedEIDCardKeyGenerator(randomBytes: { _ in scalar })

    let key = try XCTUnwrap(sut.generatePseudonymKeyHex())

    XCTAssertEqual(key, ausweisAppDefaultPseudonymKey)
  }

  func testGeneratePseudonymKeyHex_WhenUsingSecureRandom_ThenEachCallReturnsADifferentKey() throws {
    let sut = SimulatedEIDCardKeyGenerator()

    let first = try XCTUnwrap(sut.generatePseudonymKeyHex())
    let second = try XCTUnwrap(sut.generatePseudonymKeyHex())

    XCTAssertNotEqual(first, second)
    XCTAssertEqual(first.count, second.count)
    XCTAssertEqual(first.prefix(518), second.prefix(518))
    XCTAssertEqual(first.suffix(460), second.suffix(460))
  }

  func testGeneratePseudonymKeyHex_WhenFirstScalarIsOutOfRange_ThenRetriesWithNextScalar() throws {
    let valid = [UInt8](repeating: 0x01, count: 32)
    var scalars: [[UInt8]] = [
      [UInt8](repeating: 0x00, count: 32),
      SimulatedEIDCardKeyGenerator.brainpoolP256r1Order,
      [UInt8](repeating: 0xff, count: 32),
      valid
    ]
    let sut = SimulatedEIDCardKeyGenerator(randomBytes: { _ in scalars.removeFirst() })

    let key = try XCTUnwrap(sut.generatePseudonymKeyHex())

    XCTAssertTrue(scalars.isEmpty)
    XCTAssertTrue(key.contains(String(repeating: "01", count: 32)))
  }

  func testGeneratePseudonymKeyHex_WhenRandomSourceFails_ThenReturnsNil() {
    let sut = SimulatedEIDCardKeyGenerator(randomBytes: { _ in nil })

    XCTAssertNil(sut.generatePseudonymKeyHex())
  }

  func testGeneratePseudonymKeyHex_WhenRandomSourceNeverReturnsValidScalar_ThenReturnsNil() {
    let sut = SimulatedEIDCardKeyGenerator(randomBytes: { _ in [UInt8](repeating: 0x00, count: 32) })

    XCTAssertNil(sut.generatePseudonymKeyHex())
  }

  func testIsValidScalar_WhenScalarIsOrderMinusOne_ThenIsValid() {
    var scalar = SimulatedEIDCardKeyGenerator.brainpoolP256r1Order
    scalar[scalar.count - 1] -= 1

    XCTAssertTrue(SimulatedEIDCardKeyGenerator.isValidScalar(scalar))
  }

  private func bytes(fromHex hex: String) -> [UInt8] {
    let characters = Array(hex)
    return stride(from: 0, to: characters.count, by: 2).compactMap {
      UInt8(String(characters[$0...$0 + 1]), radix: 16)
    }
  }
}
