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

class NoteDetailViewController: UIViewController, UITextViewDelegate {
    @IBOutlet var reminderSwitch: UISwitch!
    @IBOutlet var reminderDatePicker: UIDatePicker!
    @IBOutlet var pinnedButton: UIBarButtonItem!
    @IBOutlet var titleTextField: UITextField!
    @IBOutlet var contentTextView: UITextView!
    var delegate: NotifyReloadDataDelegate!
    var noteDataSource: NoteDataSource!
    var noteStore: NoteStore!
    var note: Note!
    var isEdited: Bool = false
    var oldInset: UIEdgeInsets!
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillShow(_:)), name: UIResponder.keyboardDidShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillDismiss(_:)), name: UIResponder.keyboardDidHideNotification, object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if noteDataSource.notes.firstIndex(of: self.note) == nil {
            if self.note.title.isEmpty || self.note.text.isEmpty {
                self.noteStore.remove(note: self.note)
                return
            }
            
            self.noteDataSource.notes.append(self.note)
        }
        
        if self.isEdited {
            self.note.editDate = Date()
            self.delegate.notifyReloadData()
            try? self.noteStore.coreDataStack.saveChanges()
        }
        
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let downSwipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(self.downSwipeGestureAction))
        downSwipeGesture.direction = .down
        self.view.addGestureRecognizer(downSwipeGesture)
        if self.note == nil {
            self.note = self.noteStore.createNote()
            self.navigationItem.title = ""
        }
        else {
            self.navigationItem.title = self.note.title
        }
        
        self.reminderDatePicker.addTarget(self, action: #selector(self.settingReminderDate), for: .valueChanged)
        self.titleTextField.addTarget(self, action: #selector(self.titleChanged(_:)), for: .editingChanged)
        self.contentTextView.delegate = self
        self.titleTextField.text = self.note.title
        self.contentTextView.text = self.note.text
        self.pinnedToggler(state: self.note.pinned)
        // Threshold on current date for reminder
        self.reminderDatePicker.minimumDate = Date()
        if let reminderDate = note.reminderDate {
            self.reminderToggler(state: true)
            self.reminderDatePicker.date = reminderDate
        }
        
        self.oldInset = self.contentTextView.contentInset
    }
    
    @objc func keyboardWillShow(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let keyboardFrame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else {
            return
        }
        
        let keyboardRect = keyboardFrame.cgRectValue
        let contentInset = UIEdgeInsets(top: 0, left: 0, bottom: keyboardRect.height, right: 0)
        self.contentTextView.contentInset = contentInset
        self.contentTextView.scrollIndicatorInsets = contentInset
    }
    
    @objc func keyboardWillDismiss(_ notification: Notification) {
        UIView.animate(withDuration: 0.3) {
            self.contentTextView.contentInset = self.oldInset
            self.contentTextView.scrollIndicatorInsets = self.oldInset
        }
    }
    
    func textViewDidChange(_ textView: UITextView) {
        if !textView.text.isEmpty {
            self.catchContent(text: textView.text)
        }
    }
    
    @objc func contentChanged(_ textField: UITextField) {
        if !textField.text!.isEmpty {
            self.note.text = textField.text!
            self.note.backedUp = false
            self.isEdited = true
        }
    }
    
    func catchContent(text: String) {
        self.note.text = text
        self.note.backedUp = false
        self.isEdited = true
    }
    
    @objc func titleChanged(_ textField: UITextField) {
        if !textField.text!.isEmpty {
            self.note.title = textField.text!
            self.note.backedUp = false
            self.isEdited = true
        }
    }
    
    @IBAction func pinnedAction(_ sender: Any) {
        let state = !self.note.pinned
        self.pinnedToggler(state: state)
        self.note.backedUp = false
        self.isEdited = true
    }
    
    @IBAction func reminderAction(_ sender: Any) {
        let reminderState = self.reminderSwitch.isOn
        self.reminderToggler(state: reminderState)
        self.note.backedUp = false
        self.isEdited = true
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
        self.isEdited = true
    }
    
    @objc func downSwipeGestureAction() {
        self.hideKeyboard()
    }
    
    func hideKeyboard() {
        self.view.endEditing(true)
    }
}
