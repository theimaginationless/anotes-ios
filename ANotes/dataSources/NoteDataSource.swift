//
//  NoteDataSource.swift
//  ANotes
//
//  Created by Dmitry Teplyakov on 29.10.2020.
//

import UIKit

class NoteDataSource: NSObject, UITableViewDataSource {
    var notes = [Note]()
    var searchMode: Bool {
        get {
            return self.searchNotes != nil
        }
    }
    var searchNotes: [Note]?
    var lastRestoreDate: Date? {
        get {
            UserDefaults.standard.value(forKey: "LastRestoreDate") as? Date
        }
        set {
            UserDefaults.standard.setValue(newValue, forKey: "LastRestoreDate")
        }
    }
    var lastBackupDate: Date? {
        get {
            UserDefaults.standard.value(forKey: "LastBackupDate") as? Date
        }
        set {
            UserDefaults.standard.setValue(newValue, forKey: "LastBackupDate")
        }
    }
    var notBackedIndices: [Array<Note>.Index] {
        get {
            zip(self.notes.indices, self.notes).compactMap{if !$1.backedUp {return $0} else {return nil}}
        }
    }
    let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.doesRelativeDateFormatting = true
        return formatter
    }()
    var noteStore: NoteStore!
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if self.searchMode {
            return self.searchNotes!.count
        }
        
        switch self.numberOfSections(in: tableView) {
        case 1:
            return self.notes.count
        case 2:
            switch section {
            case 0:
                return self.notes.filter{$0.pinned}.count
            case 1:
                return self.notes.filter{!$0.pinned}.count
            default:
                return 0
            }
        default:
            return 0
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        if self.searchMode {
            return 1
        }
        
        return self.notes.filter{$0.pinned}.count > 0 ? 2 : 1
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch self.numberOfSections(in: tableView) {
        case 1:
            return ""
        case 2:
            switch section {
            case 0:
                return TitleLocalized.pinned
            case 1:
                if notes.filter({!$0.pinned}).count == 0 {
                    fallthrough
                }
                return TitleLocalized.all
            default:
                return ""
            }
        default:
            return ""
        }
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        if self.notes.count == 1 || self.searchMode {
            return false
        }
        
        var deletableSectionItems = 0
        if self.numberOfSections(in: tableView) > 1 {
            deletableSectionItems = 1
        }
        
        if deletableSectionItems != indexPath.section {
            return false
        }
        
        return true
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        switch editingStyle {
        case .delete:
            var deletableSectionItems = 0
            if self.numberOfSections(in: tableView) > 1 {
                deletableSectionItems = 1
            }
            
            if deletableSectionItems != indexPath.section {
                return
            }
            
            let cell = tableView.cellForRow(at: indexPath) as! NoteTableViewCell
            let note: Note = cell.note
            let noteIndex = self.notes.firstIndex(of: note)!
            self.notes.remove(at: noteIndex)
            tableView.deleteRows(at: [indexPath], with: .automatic)
            self.noteStore.remove(note: note)
            let notPinnedNotes = self.notes.filter{!$0.pinned}
            if notPinnedNotes.count == 0 && deletableSectionItems == 1 {
                tableView.reloadSections([deletableSectionItems], with: .automatic)
            }
        default:
            return
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let identifier = "NoteTableViewCell"
        let cell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath) as! NoteTableViewCell
        
        var note: Note
        if self.searchMode {
            note = self.searchNotes![indexPath.row]
        }
        else {
            switch self.numberOfSections(in: tableView){
            case 1:
                note = notes[indexPath.row]
            case 2:
                let pinnedNotes = notes.filter{$0.pinned}
                let otherNotes = notes.filter{!$0.pinned}
                switch indexPath.section {
                case 0:
                    note = pinnedNotes[indexPath.row]
                case 1:
                    note = otherNotes[indexPath.row]
                default:
                    return cell
                }
            default:
                return cell
            }
        }
        
        cell.titleLabel.text = note.title
        cell.contentLabel.text = note.text
        cell.backedUpButton.isHidden = note.backedUp
        cell.note = note
        if let reminderDate = note.reminderDate {
            cell.reminderButton.isEnabled = true
            cell.reminderButton.setImage(UIImage(systemName: "alarm.fill"), for: .normal)
            cell.reminderDateLabel.text = self.dateFormatter.string(from: reminderDate)
        }
        else {
            cell.reminderButton.isEnabled = false
            cell.reminderButton.setImage(UIImage(systemName: "alarm"), for: .normal)
            cell.reminderDateLabel.text = TitleLocalized.reminderDisabled
        }
        return cell
    }
}
