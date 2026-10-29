//
//  SimulatedEIDCardKeyGenerator.swift
//  feature-issuance
//
//  Created by Ameen Qadri on 13.10.26.
//

import Foundation
import Security

struct SimulatedEIDCardKeyGenerator {
  static let pseudonymKeyId = 2
  static let scalarLength = 32

  static let derPrefix: [UInt8] = bytes(fromHex: [
    "308202050201003081ec06072a8648ce3d02013081e0020101302c06072a8648ce3d0101022100a9fb57dba1eea9bc3e660a909d838d726e3bf623d5",
    "2620282013481d1f6e5377304404207d5a0975fc2c3057eef67530417affe7fb8055c126dc5c6ce94a4b44f330b5d9042026dc5c6ce94a4b44f330b5",
    "d9bbd77cbf958416295cf7e1ce6bccdc18ff8c07b60441048bd2aeb9cb7e57cb2c4b482ffc81b7afb9de27e1e3bd23c23a4453bd9ace3262547ef835",
    "c3dac4fd97f8461a14611dc9c27745132ded8e545c1d54c72f046997022100a9fb57dba1eea9bc3e660a909d838d718c397aa3b561a6f7901e0e8297",
    "4856a70201010482010f3082010b0201010420"
  ])

  static let derSuffix: [UInt8] = bytes(fromHex: [
    "a081e33081e0020101302c06072a8648ce3d0101022100a9fb57dba1eea9bc3e660a909d838d726e3bf623d52620282013481d1f6e5377304404207d",
    "5a0975fc2c3057eef67530417affe7fb8055c126dc5c6ce94a4b44f330b5d9042026dc5c6ce94a4b44f330b5d9bbd77cbf958416295cf7e1ce6bccdc",
    "18ff8c07b60441048bd2aeb9cb7e57cb2c4b482ffc81b7afb9de27e1e3bd23c23a4453bd9ace3262547ef835c3dac4fd97f8461a14611dc9c2774513",
    "2ded8e545c1d54c72f046997022100a9fb57dba1eea9bc3e660a909d838d718c397aa3b561a6f7901e0e82974856a7020101"
  ])

  static let brainpoolP256r1Order: [UInt8] = bytes(fromHex: [
    "a9fb57dba1eea9bc3e660a909d838d718c397aa3b561a6f7901e0e82974856a7"
  ])

  private static let maxAttempts = 16

  private let randomBytes: (Int) -> [UInt8]?

  init(randomBytes: @escaping (Int) -> [UInt8]? = Self.secureRandomBytes) {
    self.randomBytes = randomBytes
  }

  func generatePseudonymKeyHex() -> String? {
    for _ in 0..<Self.maxAttempts {
      guard let scalar = randomBytes(Self.scalarLength),
            scalar.count == Self.scalarLength else {
        return nil
      }
      if Self.isValidScalar(scalar) {
        return (Self.derPrefix + scalar + Self.derSuffix)
          .map { String(format: "%02x", $0) }
          .joined()
      }
    }
    return nil
  }

  static func isValidScalar(_ scalar: [UInt8]) -> Bool {
    scalar.contains { $0 != 0 } && scalar.lexicographicallyPrecedes(brainpoolP256r1Order)
  }

  private static func secureRandomBytes(count: Int) -> [UInt8]? {
    var bytes = [UInt8](repeating: 0, count: count)
    let status = SecRandomCopyBytes(kSecRandomDefault, count, &bytes)
    return status == errSecSuccess ? bytes : nil
  }

  private static func bytes(fromHex chunks: [String]) -> [UInt8] {
    let hex = Array(chunks.joined())
    return stride(from: 0, to: hex.count, by: 2).compactMap {
      UInt8(String(hex[$0...$0 + 1]), radix: 16)
    }
  }
}
