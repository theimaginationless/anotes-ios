//
//  CoreDataStack.swift
//  ANotes
//
//  Created by Dmitry Teplyakov on 26.11.2020.
//

import Foundation
import CoreData

class CoreDataStack {
    let managedObjectModelName: String
    private lazy var managedObjectModel: NSManagedObjectModel = {
        let modelURL = Bundle.main.url(forResource: managedObjectModelName, withExtension: "momd")!
        return NSManagedObjectModel(contentsOf: modelURL)!
    }()
    
    private var applicationDocumentsDirectory: URL {
        let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return urls.first!
    }
    
    private lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator = {
        var coordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        let pathComponent = "\(self.managedObjectModelName).sqlite"
        let url = self.applicationDocumentsDirectory.appendingPathComponent(pathComponent)
        let store = try! coordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: url, options: nil)
        return coordinator
    }()
    
    lazy var mainQueueContext: NSManagedObjectContext = {
        let moc = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        moc.name = "Main Queue Context (UI Context)"
        moc.parent = self.privateWriterContext
        return moc
    }()
    
    lazy var privateWriterContext: NSManagedObjectContext = {
        let moc = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        moc.name = "Private Queue Context (Writer Context)"
        moc.persistentStoreCoordinator = self.persistentStoreCoordinator
        return moc
    }()
    
    required init(modelName: String) {
        self.managedObjectModelName = modelName
    }
    
    /// Save persistence changes
    func saveChanges() {
        self.mainQueueContext.performAndWait {
            do {
                if self.mainQueueContext.hasChanges {
                    try self.mainQueueContext.save()
                }
            }
            catch let localError {
                print("Error saving \(self.mainQueueContext.name!) context:\n\(localError)")
            }
        }
        
        self.privateWriterContext.perform {
            do {
                if self.privateWriterContext.hasChanges {
                    try self.privateWriterContext.save()
                }
            } catch let localError {
                print("Error saving \(self.privateWriterContext.name!) context:\n\(localError)")
            }
        }
    }
}
