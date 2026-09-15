//
//  SecKeyMock.swift
//  feature-test
//
//  Created by Pankaj Sachdeva on 29.01.25.
//

import Security

public final class SecKeyMock {
    public static func generateFakePrivateKey() -> SecKey {
        return createFakeKey()
    }

  public static func generateFakePublicKey() -> SecKey {
        return createFakeKey()
    }

    private static func createFakeKey() -> SecKey {
        let attributes: [String: Any] = [
            kSecAttrKeyType as String: kSecAttrKeyTypeEC,
            kSecAttrKeySizeInBits as String: 256
        ]
        
        var error: Unmanaged<CFError>?
        guard let key = SecKeyCreateRandomKey(attributes as CFDictionary, &error) else {
            fatalError("Failed to create fake SecKey: \(String(describing: error))")
        }
        return key
    }
}
