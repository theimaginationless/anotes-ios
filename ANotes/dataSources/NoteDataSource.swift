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
        switch section {
        case 0:
            return self.notes.filter{$0.pinned}.count
        case 1:
            return self.notes.filter{!$0.pinned}.count
        default:
            return 0
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return self.notes.filter{$0.pinned}.count > 0 ? 2 : 1
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0:
            return TitleLocalized.pinned
        default:
            return TitleLocalized.all
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let identifier = "NoteTableViewCell"
        let cell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath) as! NoteTableViewCell
        let pinnedNotes = notes.filter{$0.pinned}
        let otherNotes = notes.filter{!$0.pinned}
        var note: Note
        switch indexPath.section {
        case 0:
            note = pinnedNotes[indexPath.row]
        case 1:
            note = otherNotes[indexPath.row]
        default:
            return cell
        }
        
        cell.titleLabel.text = note.title
        cell.contentLabel.text = note.text
        cell.backedUpButton.isHidden = note.backedUp
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
