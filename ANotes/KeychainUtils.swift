//
//  KeychainUtils.swift
//  ANotes
//
//  Created by Dmitry Teplyakov on 14.01.2021.
//

import Foundation

enum KeychainError: Error {
    case noPassword
    case unexpectedPasswordData
    case unhandledError(status: OSStatus)
}

struct KeychainUtils {
    private static var server: String {
        get {
            UserDefaults.standard.string(forKey: SettingKeys.Backend) ?? ""
        }
    }
    
    static func saveCredentials(for user: User) throws {
        let query = self.prepareQuery(for: user)
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw KeychainError.unhandledError(status: status)
        }
    }
    
    private static func prepareQuery(for user: User) -> [String: Any] {
        let username = user.username!
        let password = user.password
        let token = user.authToken
        let passcode = user.passcode
        let tamperedDict: [String: String?] = ["password": password,
                                              "token": token,
                                              "passcode": passcode]
        let tamperedData = try! JSONSerialization.data(withJSONObject: tamperedDict, options: [])
        let query: [String: Any] = [kSecClass as String: kSecClassInternetPassword,
                                    kSecAttrAccount as String: username,
                                    kSecAttrServer as String: self.server,
                                    kSecValueData as String: tamperedData]
        
        return query
    }
    
    static func loadCredentials() throws -> User {
        let query: [String: Any] = [kSecClass as String: kSecClassInternetPassword,
                                    kSecAttrServer as String: self.server,
                                    kSecMatchLimit as String: kSecMatchLimitOne,
                                    kSecReturnAttributes as String: true,
                                    kSecReturnData as String: true]
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status != errSecItemNotFound else {
            throw KeychainError.noPassword
        }
        
        guard status == errSecSuccess else {
            throw KeychainError.unhandledError(status: status)
        }
        
        guard let foundItem = item as? [String: Any],
              let username = foundItem[kSecAttrAccount as String] as? String,
              let tamperedData = foundItem[kSecValueData as String] as? Data,
              let tamperedDictionary = try? JSONSerialization.jsonObject(with: tamperedData, options: []) as? [String: String?]
        else {
            throw KeychainError.unexpectedPasswordData
        }
        
        let password = (tamperedDictionary["password"])! ?? ""
        let token = (tamperedDictionary["token"])! ?? ""
        let passcode = tamperedDictionary["passcode"]!
        let user = User(username: username, password: password, authToken: token)
        user.passcode = passcode
        
        return user
    }
    
    static func updateCredentials(for user: User) throws {
        let query = self.prepareQuery(for: user)
        let newValue = query[kSecValueData as String] as! Data
        let attributes: [String: Any] = [kSecValueData as String: newValue]
        let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        guard status != errSecItemNotFound else {
            throw KeychainError.noPassword
        }
        
        guard status == errSecSuccess else {
            throw KeychainError.unhandledError(status: status)
        }
    }
    
    static func resetCredentials() throws {
        let query: [String: Any] = [kSecClass as String: kSecClassInternetPassword]
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess else {
            throw KeychainError.unhandledError(status: status)
        }
    }
}
