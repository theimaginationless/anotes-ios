//
//  NotesTableViewController.swift
//  ANotes
//
//  Created by Dmitry Teplyakov on 27.10.2020.
//

import UIKit
import LocalAuthentication

class NotesTableViewController: UITableViewController, NotifyReloadDataDelegate {
    var userDataSource = UserDataSource()
    var userStore: UserStore!
    var currentUser: User!
    let isBiometricAuthEnabled = true
//    var isBiometricAuthEnabled: Bool {
//        get {
//            UserDefaults.standard.bool(forKey: SettingKeys.BiometricAuth)
//        }
//        set {
//            UserDefaults.standard.setValue(false, forKey: SettingKeys.BiometricAuth)
//        }
//    }
    @IBOutlet var lastRestoreDateLabel: BarLabelItem!
    @IBOutlet var userButton: UIBarButtonItem!
    let operationQueue = OperationQueue()
    var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.doesRelativeDateFormatting = true
        return formatter
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.userButton.target = self
        self.tableView.delegate = self
        self.currentUser = self.userStore.user
        self.userDataSource.user = self.userStore.user
        self.currentUser.noteDataSource.noteStore = self.currentUser.noteStore
        self.tableView.dataSource = self.currentUser.noteDataSource
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.updateLastBackupDate(date: self.currentUser.noteDataSource.lastBackupDate)
        if self.currentUser.noteDataSource.lastRestoreDate == nil {
            self.syncData(mode: .Restore)
        }
        else {
            self.restoreFromLocal()
        }
        
//        if isBiometricAuthEnabled {
//            self.biometricAuthentication()
//        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
        
    /// Update last backup date label
    /// - Parameter date: Date for display in format: Last backup Today at 12:34
    private func updateLastBackupDate(date: Date?) {
        if let date = date {
            self.lastRestoreDateLabel.date = self.dateFormatter.string(from: date)
        }
        else {
            self.lastRestoreDateLabel.date = nil
        }
    }
    
    func restoreFromLocal() {
        self.currentUser.noteStore.restoreNotesFromLocal {
            (result) in
            switch result {
            case let .RestoreSuccess(notesArray):
                self.currentUser.noteDataSource.notes = notesArray
                self.notifyReloadData()
                return
            case let .Failure(error):
                self.operationQueue.addOperation {
                    self.vibrate(occured: .error)
                }
                let alert = UIAlertController(title: ErrorTitleLocalized.restoreFromLocalFailed, message: error.localizedDescription, preferredStyle: .actionSheet)
                alert.addAction(UIAlertAction(title: NSLocalizedString("Ok", comment: "Ok for close restore error alert"), style: .cancel, handler: nil))
                self.present(alert, animated: true, completion: nil)
            default:
                self.operationQueue.addOperation {
                    self.vibrate(occured: .error)
                }
                let alert = UIAlertController(title: ErrorTitleLocalized.unknownError, message: ErrorMessageLocalized.unknownError, preferredStyle: .actionSheet)
                alert.addAction(UIAlertAction(title: NSLocalizedString("Ok", comment: "Ok for close unknown error alert"), style: .cancel, handler: nil))
                self.present(alert, animated: true, completion: nil)
            }
        }
    }
    
    /// Restore local storage with backend
    func syncData(mode: Operation, successCompletion: (() -> Void)? = nil) {
        let previousStatus = self.lastRestoreDateLabel.text
        switch mode {
        case .Restore:
            self.currentUser.noteStore.restoreNotesFromBackend(for: currentUser) {
                (result) in
                OperationQueue.main.addOperation {
                    switch result {
                    case let .RestoreSuccess(notesArray):
                        notesArray.forEach{$0.backedUp = true}
                        self.currentUser.noteDataSource.notes = notesArray
                        self.currentUser.noteDataSource.lastRestoreDate = Date()
                        self.notifyReloadData()
                        do {
                            try self.currentUser.noteStore.coreDataStack.saveChanges()
                        }
                        catch let error {
                            print("Error while saving: \(error)")
                        }
                        if let safeSuccessCompletion = successCompletion {
                            safeSuccessCompletion()
                        }
                        return
                    case let .Failure(error):
                        self.operationQueue.addOperation {
                            self.vibrate(occured: .error)
                        }
                        switch error {
                        case AnotesError.AuthError:
                            let alert = UIAlertController(title: ErrorTitleLocalized.syncFailed, message: ErrorMessageLocalized.AuthenticationTokenError, preferredStyle: .actionSheet)
                            alert.addAction(UIAlertAction(title: ButtonLabelLocalized.cancel, style: .cancel, handler: nil))
                            alert.addAction(UIAlertAction(title: ButtonLabelLocalized.logout, style: .destructive) {
                                (action) in
                                
                                self.logoutWithConfirm()
                            })
                            self.present(alert, animated: true, completion: nil)
                        default:
                            let alert = UIAlertController(title: ErrorTitleLocalized.networkError, message: ErrorMessageLocalized.networkError, preferredStyle: .actionSheet)
                            alert.addAction(UIAlertAction(title: NSLocalizedString("Ok", comment: "Ok for close network error alert"), style: .cancel, handler: nil))
                            self.present(alert, animated: true, completion: nil)
                        }
                    default:
                        self.operationQueue.addOperation {
                            self.vibrate(occured: .error)
                        }
                        let alert = UIAlertController(title: ErrorTitleLocalized.networkError, message: ErrorMessageLocalized.networkError, preferredStyle: .actionSheet)
                        alert.addAction(UIAlertAction(title: NSLocalizedString("Ok", comment: "Ok for close network error alert"), style: .cancel, handler: nil))
                        self.present(alert, animated: true, completion: nil)
                    }
                    self.lastRestoreDateLabel.text = previousStatus
                }
            }
        case .Backup:
            let indices = self.currentUser.noteDataSource.notBackedIndices
            let allNotes = self.currentUser.noteDataSource.notes
            
            AnotesApi.backupNotes(for: currentUser, with: allNotes) {
                (result) in
                OperationQueue.main.addOperation {
                    switch result {
                    case .BackupSuccess:
                        self.currentUser.noteDataSource.lastBackupDate = Date()
                        self.updateLastBackupDate(date: self.currentUser.noteDataSource.lastBackupDate)
                        indices.forEach{allNotes[$0].backedUp = true}
                        self.notifyReloadData()
                        do {
                            try self.currentUser.noteStore.coreDataStack.saveChanges()
                        }
                        catch let error {
                            print("Error while saving: \(error)")
                        }
                        if let safeSuccessCompletion = successCompletion {
                            safeSuccessCompletion()
                        }
                        return
                    case let .Failure(error):
                        switch error {
                        case AnotesError.AuthError:
                            self.operationQueue.addOperation {
                                self.vibrate(occured: .error)
                            }
                            let alert = UIAlertController(title: ErrorTitleLocalized.syncFailed, message: ErrorMessageLocalized.AuthenticationTokenError, preferredStyle: .actionSheet)
                            alert.addAction(UIAlertAction(title: ButtonLabelLocalized.cancel, style: .cancel, handler: nil))
                            alert.addAction(UIAlertAction(title: ButtonLabelLocalized.logout, style: .destructive) {
                                (action) in
                                
                                self.logoutWithConfirm()
                            })
                            self.present(alert, animated: true, completion: nil)
                        default:
                            self.operationQueue.addOperation {
                                self.vibrate(occured: .error)
                            }
                            let alert = UIAlertController(title: ErrorTitleLocalized.networkError, message: ErrorMessageLocalized.networkError, preferredStyle: .actionSheet)
                            alert.addAction(UIAlertAction(title: NSLocalizedString("Ok", comment: "Ok for close network error alert"), style: .cancel, handler: nil))
                            self.present(alert, animated: true, completion: nil)
                        }
                    default:
                        self.operationQueue.addOperation {
                            self.vibrate(occured: .error)
                        }
                        let alert = UIAlertController(title: ErrorTitleLocalized.networkError, message: ErrorMessageLocalized.networkError, preferredStyle: .actionSheet)
                        alert.addAction(UIAlertAction(title: NSLocalizedString("Ok", comment: "Ok for close network error alert"), style: .cancel, handler: nil))
                        self.present(alert, animated: true, completion: nil)
                    }
                    self.lastRestoreDateLabel.text = previousStatus
                }
            }
        }
    }
    
    @IBAction func logoutAction(_ sender: Any) {
        self.logoutWithConfirm()
    }
    
    @IBAction func backupAction(_ sender: Any) {
        self.syncData(mode: .Backup) {
            self.operationQueue.addOperation {
                self.vibrate(occured: .success)
            }
        }
    }
    
    func vibrate(occured: UINotificationFeedbackGenerator.FeedbackType) {
        let feedbackGenerator = UINotificationFeedbackGenerator()
        feedbackGenerator.notificationOccurred(occured)
    }
    
    func logoutWithConfirm() {
        let wipeAccountAlert = UIAlertController(title: TitleLocalized.confirmLogout, message: MessagesLocalized.wipeAccountMessage, preferredStyle: .actionSheet)
        wipeAccountAlert.addAction(UIAlertAction(title: ButtonLabelLocalized.cancel, style: .cancel, handler: nil))
        wipeAccountAlert.addAction(UIAlertAction(title: ButtonLabelLocalized.confirmWipeAccount, style: .destructive) {
            (action) in
            
            self.logout()
        })
        self.present(wipeAccountAlert, animated: true, completion: nil)
    }
    
    func logout() {
        self.userStore.prepareForRemove()
        let loginAndRegisterStoryboard = UIStoryboard(name: "LoginAndRegister", bundle: nil)
        guard let loginVC = loginAndRegisterStoryboard.instantiateViewController(identifier: "LoginViewController") as? LoginViewController else {
            print("Cannot instantiate LoginViewController")
            return
        }
        self.userDataSource.user = nil
        self.currentUser.noteStore.resetLocalNotes()
        loginVC.userStore = self.userStore
        User.resetSession()
        UIView.transition(with: self.view.window!, duration: 0.5, options: UIView.AnimationOptions.transitionFlipFromLeft, animations: {
            self.view.window!.rootViewController = loginVC
        }, completion: nil)
    }
    
    func biometricAuthentication() {
        guard #available(iOS 8.0, *) else {
            return
        }
        
        let context = LAContext()
        var error: NSError?
        
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            return
        }
        
        self.securedViewCover(enable: true)
        let reason = "Typically run application"
        context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) {
            isAuthorized, error in
            guard isAuthorized == true else {
                return
            }
            
            OperationQueue.main.addOperation {
                self.securedViewCover(enable: false)
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier {
        case "NewNoteSegue":
            if let destination = segue.destination as? NoteDetailViewController {
                destination.delegate = self
                destination.noteStore = self.userStore.user?.noteStore
                destination.noteDataSource = self.currentUser.noteDataSource
            }
        case "EditNoteSegue":
            if let destination = segue.destination as? NoteDetailViewController {
                if let cell = sender as? NoteTableViewCell,
                   let indexPath = self.tableView.indexPath(for: cell) {
                    var note: Note!
                    if self.userDataSource.user.noteDataSource.numberOfSections(in: self.tableView) > 1 {
                        switch indexPath.section {
                        case 0:
                            note = self.currentUser.noteDataSource.notes.filter{$0.pinned}[indexPath.row]
                        case 1:
                            note = self.currentUser.noteDataSource.notes.filter{!$0.pinned}[indexPath.row]
                        default:
                            note = nil
                        }
                    }
                    else {
                        note = self.currentUser.noteDataSource.notes[indexPath.row]
                    }
                    destination.delegate = self
                    destination.noteDataSource = self.currentUser.noteDataSource
                    destination.noteStore = self.userStore.user?.noteStore
                    destination.note = note
                }
            }
        default:
            return
        }
    }
    
    func notifyReloadData() {
        self.reloadData()
    }
    
    func reloadData() {
        self.currentUser.noteDataSource.notes.sort{$0.editDate > $1.editDate}
        self.tableView.reloadData()
    }
    
    func securedViewCover(enable: Bool) {
        var blurEffectStyle: UIBlurEffect.Style = .light
        if #available(iOS 13, *) {
            if UIScreen.main.traitCollection.userInterfaceStyle == .dark {
                blurEffectStyle = .dark
            }
        }
        let blurEffect = UIBlurEffect(style: blurEffectStyle)
        let blurredEffectView = UIVisualEffectView(effect: blurEffect)
        blurredEffectView.frame = UIApplication.shared.windows.first!.frame
        blurredEffectView.translatesAutoresizingMaskIntoConstraints = false
        let rootController = UIApplication.shared.windows.first!
        let tag = 1
        if enable {
            blurredEffectView.tag = tag
            rootController.addSubview(blurredEffectView)
        }
        else {
            let view = rootController.viewWithTag(tag)!
            UIView.animate(withDuration: 0.2, delay: 0.3, options: .curveLinear, animations: {
                view.alpha = 0
            }, completion: {
                result in
                view.removeFromSuperview()
            })
        }
    }
}
