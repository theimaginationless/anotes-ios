//
//  User.swift
//  ANotes
//
//  Created by Dmitry Teplyakov on 25.10.2020.
//

import UIKit

class User: Equatable {
    var username: String!
    var password: String!
    var fullname: String!
    var authToken: String!
    var unlocked: Bool?
    class var appLocked: Bool {
        set {
            UserDefaults.standard.setValue(newValue, forKey: "AppLocked")
            UserDefaults.standard.synchronize()
        }
        get {
            UserDefaults.standard.bool(forKey: "AppLocked")
        }
    }
    var passcode: String?
    var noteDataSource: NoteDataSource!
    var noteStore: NoteStore!
    
    static func == (lhs: User, rhs: User) -> Bool {
        return lhs.username == rhs.username
    }
    
    init(username: String, password: String, fullname: String? = nil, authToken: String) {
        self.username = username
        self.password = password
        if let fullnameUnwrap = fullname {
            self.fullname = fullnameUnwrap
        }
        else {
            self.fullname = UserDefaults.standard.string(forKey: "fullname")
        }
        self.authToken = authToken
        self.noteDataSource = NoteDataSource()
        self.noteStore = NoteStore()
    }
    
    class func setupPasscode(passcode: String, for user: User) {
        user.passcode = passcode
        do {
            try KeychainUtils.updateCredentials(for: user)
            self.appLocked = true
        }
        catch let error {
            print("Cannot setup passcode for user: \(user.username ?? "") with error: \(error)")
        }
    }
    
    /// Save user session
    /// - Parameter user: user for save
    class func saveSession(for user: User) {
        UserDefaults.standard.setValue(user.fullname, forKey: "fullname")
        UserDefaults.standard.synchronize()
        do {
            try KeychainUtils.saveCredentials(for: user)
        }
        catch let error {
            print("Cannot save credentials into keychain for user \(String(describing: user.username)) with error: \(error)")
        }
    }
    
    /// Reset last session
    class func resetSession() {
        UserDefaults.standard.removeObject(forKey: "fullname")
        UserDefaults.standard.removeObject(forKey: "LastBackupDate")
        UserDefaults.standard.removeObject(forKey: "LastRestoreDate")
        UserDefaults.standard.removeObject(forKey: "AlreadyUsing")
        UserDefaults.standard.synchronize()
        do {
            try KeychainUtils.resetCredentials()
        }
        catch let error {
            print("Cannot reset session keychain: \(error)")
        }
        self.appLocked = false
    }
    
    /// Get last session user
    /// - Returns: User instance of last saved session
    class func getLastSessionUser() -> User? {
        guard let fullname = UserDefaults.standard.string(forKey: "fullname") else {
            return nil
        }
        
        let user = try? KeychainUtils.loadCredentials()
        user?.fullname = fullname
        print("Cridentials load successful!")
        return user
    }
}
