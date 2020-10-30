//
//  UserStore.swift
//  ANotes
//
//  Created by Dmitry Teplyakov on 26.10.2020.
//

import Foundation

class UserStore {
    var user: User?
    
    public func prepareForRemove() {
        user?.noteDataSource.notes.removeAll()
        user = nil
        UserDefaults.standard.setValue(false, forKey: SettingKeys.BiometricAuth)
    }
}
