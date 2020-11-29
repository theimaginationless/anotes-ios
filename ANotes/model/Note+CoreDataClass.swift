//
//  Note+CoreDataClass.swift
//  ANotes
//
//  Created by Dmitry Teplyakov on 26.11.2020.
//
//

import Foundation
import CoreData

@objc(Note)
public class Note: NSManagedObject {
    public override func awakeFromInsert() {
        super.awakeFromInsert()
        title = ""
        text = ""
        pinned = false
        backedUp = false
        reminderDate = nil
        creationDate = Date()
        editDate = creationDate
        id = UUID().uuidString
    }
}
