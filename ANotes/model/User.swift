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
    class var passcode: String? {
        set {
            UserDefaults.standard.setValue(newValue, forKey: "passcode")
            UserDefaults.standard.synchronize()
        }
        get {
            UserDefaults.standard.string(forKey: "passcode")
        }
    }
    var noteDataSource: NoteDataSource!
    var noteStore: NoteStore!
    
    static func == (lhs: User, rhs: User) -> Bool {
        return lhs.username == rhs.username
    }
    
    init(username: String, password: String, fullname: String, authToken: String) {
        self.username = username
        self.password = password
        self.fullname = fullname
        self.authToken = authToken
        self.noteDataSource = NoteDataSource()
        self.noteStore = NoteStore()
    }
    
    /// Save user session
    /// - Parameter user: user for save
    class func saveSession(for user: User) {
        // TODO: Move secure-sensitive data to keychain
        UserDefaults.standard.setValue(user.username, forKey: "username")
        UserDefaults.standard.setValue(user.password, forKey: "password")
        UserDefaults.standard.setValue(user.fullname, forKey: "fullname")
        UserDefaults.standard.setValue(user.authToken, forKey: "authToken")
        UserDefaults.standard.synchronize()
    }
    
    /// Reset last session
    class func resetSession() {
        UserDefaults.standard.removeObject(forKey: "username")
        UserDefaults.standard.removeObject(forKey: "password")
        UserDefaults.standard.removeObject(forKey: "fullname")
        UserDefaults.standard.removeObject(forKey: "authToken")
        UserDefaults.standard.removeObject(forKey: "LastBackupDate")
        UserDefaults.standard.removeObject(forKey: "LastRestoreDate")
        UserDefaults.standard.removeObject(forKey: "AlreadyUsing")
        UserDefaults.standard.synchronize()
        self.appLocked = false
        self.passcode = nil
    }
    
    /// Get last session user
    /// - Returns: User instance of last saved session
    class func getLastSessionUser() -> User? {
        // TODO: Move secure-sensitive data to keychain
        guard let username = UserDefaults.standard.string(forKey: "username"),
           let fullname = UserDefaults.standard.string(forKey: "fullname"),
           let password = UserDefaults.standard.string(forKey: "password"),
           let authToken = UserDefaults.standard.string(forKey: "authToken") else {
            
            return nil
        }
        
        let user = User(username: username, password: password, fullname: fullname, authToken: authToken)
        return user
    }
}
