//
//  KeychainService.swift
//  SecurityCheck
//
//  Created by Matija Kruljac on 25.04.2023..
//

import Foundation
import Security

final class KeychainService {

    static let shared = KeychainService()

    @discardableResult
    func setString(_ value: String, forKey key: String) -> Bool {
        guard let valueData = value.data(using: .utf8) else {
            return false
        }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: valueData
        ]

        SecItemDelete(query as CFDictionary)

        let status = SecItemAdd(query as CFDictionary, nil)

        return status == errSecSuccess
    }

    func getString(forKey key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: kCFBooleanTrue as Any,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        if let data = result as? Data,
           let value = String(data: data, encoding: .utf8),
           status == errSecSuccess {
            return value
        }

        return nil
    }

    @discardableResult
    func deleteString(forKey key: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]

        let status = SecItemDelete(query as CFDictionary)

        return status == errSecSuccess
    }

    @discardableResult
    func saveDataToKeychain(data: Data, forKey key: String) -> Bool {
        // Define the query parameters
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlocked,
            kSecValueData as String: data
        ]

        // Delete any existing item with the same key
        let deleteStatus = SecItemDelete(query as CFDictionary)
        guard deleteStatus == errSecSuccess || deleteStatus == errSecItemNotFound else {
            return false
        }

        // Add the new item to the Keychain
        let addStatus = SecItemAdd(query as CFDictionary, nil)
        guard addStatus == errSecSuccess else {
            return false
        }

        return true
    }

    func getDataFromKeychain(forKey key: String) -> Data? {
        // Define the query parameters
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: kCFBooleanTrue!,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        // Query the Keychain for the item with the specified key
        var queryResult: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &queryResult)
        guard status == errSecSuccess else {
            return nil
        }

        // Convert the result to a Data object and return it
        guard let data = queryResult as? Data else {
            return nil
        }

        return data
    }
}
