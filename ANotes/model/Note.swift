//
//  Note.swift
//  ANotes
//
//  Created by Dmitry Teplyakov on 25.10.2020.
//

import UIKit

class Note {
    var title: String!
    var text: String!
    var pinned: Bool!
    var reminderDate: Date?
    var creationDate: Date!
    var editDate: Date!
    
    init(title: String, text: String, pinned: Bool?, reminderDate: Date?, creationDate: Date?, editDate: Date) {
        self.title = title
        self.text = text
        self.pinned = pinned ?? false
        self.reminderDate = reminderDate
        self.creationDate = creationDate
        self.editDate = editDate
    }
}
