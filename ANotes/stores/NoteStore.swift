//
//  NoteStore.swift
//  ANotes
//
//  Created by Dmitry Teplyakov on 27.10.2020.
//

import UIKit
import CoreData

class NoteStore {
    var allNotes = [Note]()
    let coreDataStack = CoreDataStack(modelName: "AnotesModel")
    let batchSize = 10
    
    private func processingRestoredNotesData(data: Data?) -> AnotesResult {
        guard let jsonData = data else {
            return .Failure(AnotesError.EmptyJSONData)
        }
        
        let result = AnotesApi.notesFrom(data: jsonData, inContext: self.coreDataStack.mainQueueContext)
        
        if case .RestoreSuccess(_) = result {
            self.coreDataStack.saveChanges()
        }
                
        return result
    }
    
    /// Restore notes from backend
    /// - Parameter for: user for authentication
    /// - Parameter completion: completion for using returned note instances
    func restoreNotesFromBackend(for user: User, completion: @escaping (AnotesResult) -> Void) {
        AnotesApi.fetchNotesData(for: user) {
            (dataResult) in
            switch dataResult {
            case let .DataRestoreSuccess(data):
                let notesProcessingResult = self.processingRestoredNotesData(data: data)
                completion(notesProcessingResult)
            default:
                completion(dataResult)
            }
        }
    }
    
    /// Restore notes from local persistence
    /// - Parameter completion: completion for using returned note instances
    func restoreNotesFromLocal(completion: @escaping (AnotesResult) -> Void) {
        let sortByEditDate = NSSortDescriptor(key: "editDate", ascending: false)
        
        guard let notes = try? self.fetchMainQueueNotes(sortDescriptors: [sortByEditDate]) else {
            completion(.Failure(AnotesError.UnknownError("Restore from local failed!")))
            return
        }
        
        completion(.RestoreSuccess(notes))
    }
    
    /// Remove all note entities from local persistence
    func resetLocalNotes() {
        let mainQueueContext = self.coreDataStack.mainQueueContext
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Note")
        mainQueueContext.performAndWait {
            [weak self] in
            do {
                let objects = try mainQueueContext.fetch(fetchRequest)
                for managedObject in objects {
                    let managedObjectData = managedObject as! NSManagedObject
                    mainQueueContext.delete(managedObjectData)
                }
                
                self?.coreDataStack.saveChanges()
            }
            catch let error {
                print("Remove object error! \(error)")
            }
        }
    }
    
    private func fetchMainQueueNotes(predicate: NSPredicate? = nil, sortDescriptors: [NSSortDescriptor]? = nil) throws -> [Note] {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Note")
        fetchRequest.sortDescriptors = sortDescriptors
        fetchRequest.predicate = predicate
        fetchRequest.returnsObjectsAsFaults = false
        fetchRequest.fetchBatchSize = self.batchSize
        let mainQueueContext = self.coreDataStack.mainQueueContext
        var mainQueueNotes: [Note]?
        var fetchRequestError: Error?
        mainQueueContext.performAndWait {
            do {
                mainQueueNotes = try mainQueueContext.fetch(fetchRequest) as? [Note]
            }
            catch let error {
                fetchRequestError = error
            }
        }
        
        guard let notes = mainQueueNotes else {
            throw fetchRequestError!
        }
        
        return notes
    }
    
    /// Create new note instance
    /// - Returns: CoreData persisted note instance
    func createNote() -> Note {
        var note: Note!
        self.coreDataStack.mainQueueContext.performAndWait {
            note = (NSEntityDescription.insertNewObject(forEntityName: "Note", into: self.coreDataStack.mainQueueContext) as! Note)
        }
        
        return note
    }
    
    /// Remove note entity from local persistence
    /// - Parameter note: note instance for removing
    func remove(note: Note) {
        let mainQueueContext = self.coreDataStack.mainQueueContext
        mainQueueContext.performAndWait {
            [weak self] in
            mainQueueContext.delete(note)
            self?.coreDataStack.saveChanges()
            
            print("Entity has been removed from persistence store!")
        }
    }
}
