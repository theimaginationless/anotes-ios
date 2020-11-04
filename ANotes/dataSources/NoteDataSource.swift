//
//  NoteDataSource.swift
//  ANotes
//
//  Created by Dmitry Teplyakov on 29.10.2020.
//

import UIKit

class NoteDataSource: NSObject, UITableViewDataSource {
    var notes = [Note]()
    var lastSyncDate: Date?
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
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
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
        if self.notes.count == 1 {
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
            let stubNote = Note()
            stubNote.id = cell.noteId
            let noteIndex = self.notes.firstIndex(of: stubNote)!
            self.notes.remove(at: noteIndex)
            tableView.deleteRows(at: [indexPath], with: .automatic)
        default:
            return
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let identifier = "NoteTableViewCell"
        let cell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath) as! NoteTableViewCell
        
        var note: Note
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
        
        
        cell.titleLabel.text = note.title
        cell.contentLabel.text = note.text
        cell.backedUpButton.isHidden = note.backedUp
        cell.noteId = note.id
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
