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
    var noteDataSource: NoteDataSource!
    
    static func == (lhs: User, rhs: User) -> Bool {
        return lhs.username == rhs.username
    }
    
    init(username: String, password: String, fullname: String, authToken: String) {
        self.username = username
        self.password = password
        self.fullname = fullname
        self.authToken = authToken
        self.noteDataSource = NoteDataSource()
    }
}
