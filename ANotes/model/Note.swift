//
//  Note.swift
//  ANotes
//
//  Created by Dmitry Teplyakov on 25.10.2020.
//

import UIKit

class Note: Equatable {
    var id: String
    var title: String!
    var text: String!
    var pinned: Bool!
    var reminderDate: Date?
    var creationDate: Date!
    var editDate: Date!
    var backedUp: Bool!
    
    init(title: String, text: String, pinned: Bool, reminderDate: Date?, creationDate: Date, editDate: Date?) {
        self.title = title
        self.text = text
        self.pinned = pinned
        self.reminderDate = reminderDate
        self.creationDate = creationDate
        self.editDate = editDate ?? creationDate
        self.backedUp = false
        self.id = UUID().uuidString
    }
    
    convenience init() {
        self.init(title: "", text: "", pinned: false, reminderDate: nil, creationDate: Date(), editDate: nil)
    }
    
    static func == (lhs: Note, rhs: Note) -> Bool {
        return lhs.id == rhs.id
    }
}
