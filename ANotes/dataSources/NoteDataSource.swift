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
            return self.notes.count
        default:
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let identifier = "NoteTableViewCell"
        let cell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath) as! NoteTableViewCell
        let note = notes[indexPath.row]
        cell.titleLabel.text = note.title
        cell.contentLabel.text = note.text
        if let reminderDate = note.reminderDate {
            cell.reminderButton.isEnabled = true
            cell.reminderDateLabel.text = self.dateFormatter.string(from: reminderDate)
        }
        else {
            cell.reminderButton.isEnabled = false
            cell.reminderDateLabel.text = TitleLocalized.reminderDisabled
        }
        return cell
    }
}
