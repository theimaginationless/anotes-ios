//
//  Note+CoreDataProperties.swift
//  ANotes
//
//  Created by Dmitry Teplyakov on 26.11.2020.
//
//

import Foundation
import CoreData


extension Note {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Note> {
        return NSFetchRequest<Note>(entityName: "Note")
    }

    @NSManaged public var backedUp: Bool
    @NSManaged public var creationDate: Date
    @NSManaged public var editDate: Date
    @NSManaged public var id: String
    @NSManaged public var pinned: Bool
    @NSManaged public var reminderDate: Date?
    @NSManaged public var text: String
    @NSManaged public var title: String
}

extension Note : Identifiable {

}
