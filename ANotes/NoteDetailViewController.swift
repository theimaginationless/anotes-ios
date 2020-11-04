//
//  NoteDetailViewController.swift
//  ANotes
//
//  Created by Dmitry Teplyakov on 03.11.2020.
//

import UIKit

protocol NotifyReloadDataDelegate {
    func notifyReloadData()
}

class NoteDetailViewController: UIViewController {
    @IBOutlet var reminderSwitch: UISwitch!
    @IBOutlet var reminderDatePicker: UIDatePicker!
    @IBOutlet var pinnedButton: UIBarButtonItem!
    @IBOutlet var titleTextField: UITextField!
    @IBOutlet var contentTextField: UITextField!
    var delegate: NotifyReloadDataDelegate!
    var noteDataSource: NoteDataSource!
    var note: Note!
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.note.editDate = Date()
        if noteDataSource.notes.firstIndex(of: self.note) == nil {
            if self.note.title.isEmpty || self.note.text.isEmpty {
                return
            }
            self.noteDataSource.notes.append(self.note)
        }
        self.delegate.notifyReloadData()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if self.note == nil {
            self.note = Note()
        }
        self.reminderDatePicker.addTarget(self, action: #selector(self.settingReminderDate), for: .valueChanged)
        self.titleTextField.addTarget(self, action: #selector(self.titleChanged(_:)), for: .editingChanged)
        self.contentTextField.addTarget(self, action: #selector(self.contentChanged(_:)), for: .editingChanged)
        self.titleTextField.text = self.note.title
        self.contentTextField.text = self.note.text
        self.pinnedToggler(state: self.note.pinned)
        if let reminderDate = note.reminderDate {
            self.reminderToggler(state: true)
            self.reminderDatePicker.date = reminderDate
        }
    }
    
    @objc func contentChanged(_ textField: UITextField) {
        if !textField.text!.isEmpty {
            self.note.text = textField.text
            self.note.backedUp = false
        }
    }
    
    @objc func titleChanged(_ textField: UITextField) {
        if !textField.text!.isEmpty {
            self.note.title = textField.text
            self.note.backedUp = false
        }
    }
    
    @IBAction func pinnedAction(_ sender: Any) {
        let state = !self.note.pinned
        self.pinnedToggler(state: state)
        self.note.backedUp = false
    }
    
    @IBAction func reminderAction(_ sender: Any) {
        let reminderState = self.reminderSwitch.isOn
        self.reminderToggler(state: reminderState)
        self.note.backedUp = false
    }
    
    func pinnedToggler(state: Bool) {
        self.note.pinned = state
        let icon = state ? "pin.fill" : "pin"
        self.pinnedButton.image = UIImage(systemName: icon)
    }
    
    func reminderToggler(state: Bool) {
        self.reminderDatePicker.isEnabled = state
        self.reminderSwitch.isOn = state
        if state {
            self.note.reminderDate = reminderDatePicker.date
        }
        else {
            self.note.reminderDate = nil
        }
    }
    
    @objc func settingReminderDate() {
        self.note.reminderDate = self.reminderDatePicker.date
        self.note.backedUp = false
    }
}
