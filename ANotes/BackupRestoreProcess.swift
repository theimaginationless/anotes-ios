//
//  BackupRestoreProcess.swift
//  ANotes
//
//  Created by Dmitry Teplyakov on 03.11.2020.
//

enum Operation {
    case Backup
    case Restore
}

struct BackupRestore {
    public static func backup(for currentUser: User, with notes: [Note], completion: @escaping (AnotesResult) -> Void) {
        AnotesApi.backupNotes(for: currentUser, with: notes, completion: completion)
    }
    
    public static func restore(for currentUser: User, completion: @escaping (AnotesResult) -> Void) {
        AnotesApi.restoreNotes(for: currentUser, completion: completion)
    }
}
