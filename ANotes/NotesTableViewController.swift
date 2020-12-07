//
//  NotesTableViewController.swift
//  ANotes
//
//  Created by Dmitry Teplyakov on 27.10.2020.
//

import UIKit

class NotesTableViewController: UITableViewController, NotifyReloadDataDelegate, UIPopoverPresentationControllerDelegate, ApplicationLockBiometricAuthenticationDelegate {
    var userDataSource = UserDataSource()
    var userStore: UserStore!
    var currentUser: User!
    let isBiometricAuthEnabled = true
    var alreadyUsing: Bool {
        get {
            UserDefaults.standard.bool(forKey: "AlreadyUsing")
        }
        set {
            UserDefaults.standard.setValue(newValue, forKey: "AlreadyUsing")
        }
    }
    @IBOutlet var lastRestoreDateLabel: BarLabelItem!
    @IBOutlet var userButton: UIBarButtonItem!
    @IBOutlet weak var backupButton: UIBarButtonItem!
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
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if !self.alreadyUsing {
            self.firstStart()
            self.alreadyUsing = true
        }
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
    
    func firstStart() {
        let appLockSetupAlert = UIAlertController(title: "Application lock", message: "Can you set up pass code for accessing to this application?", preferredStyle: .alert)
        let acceptLockSetup = UIAlertAction(title: "Yes", style: .default) {
            (action) in
            let pinPassStoryBoard = UIStoryboard(name: "PinPass", bundle: nil)
            guard let pinPassVC = pinPassStoryBoard.instantiateViewController(identifier: "PinPassViewController") as? PinPassViewController else {
                print("Instantiate 'PinPassViewController' from 'PinPass' storyboard failed.")
                return
            }
            pinPassVC.modalPresentationStyle = .fullScreen
            pinPassVC.setUp = true
            pinPassVC.delegate = self
            self.present(pinPassVC, animated: true, completion: nil)
        }
        appLockSetupAlert.addAction(acceptLockSetup)
        let declineLockSetup = UIAlertAction(title: "No", style: .cancel)
        appLockSetupAlert.addAction(declineLockSetup)
        self.present(appLockSetupAlert, animated: true)
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
                            if let popoverPresentationController = alert.popoverPresentationController {
                                self.preparePopoverPresentationFrame(popoverPC: popoverPresentationController, view: self.backupButton.value(forKey: "view") as! UIView, arrowDirection: .down)
                            }
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
                        if let popoverPresentationController = alert.popoverPresentationController {
                            self.preparePopoverPresentationFrame(popoverPC: popoverPresentationController, view: self.backupButton.value(forKey: "view") as! UIView, arrowDirection: .down)
                        }
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
                            if let popoverPresentationController = alert.popoverPresentationController {
                                self.preparePopoverPresentationFrame(popoverPC: popoverPresentationController, view: self.backupButton.value(forKey: "view") as! UIView, arrowDirection: .down)
                            }
                            self.present(alert, animated: true, completion: nil)
                        default:
                            self.operationQueue.addOperation {
                                self.vibrate(occured: .error)
                            }
                            let alert = UIAlertController(title: ErrorTitleLocalized.networkError, message: ErrorMessageLocalized.networkError, preferredStyle: .actionSheet)
                            alert.addAction(UIAlertAction(title: NSLocalizedString("Ok", comment: "Ok for close network error alert"), style: .cancel, handler: nil))
                            if let popoverPresentationController = alert.popoverPresentationController {
                                self.preparePopoverPresentationFrame(popoverPC: popoverPresentationController, view: self.backupButton.value(forKey: "view") as! UIView, arrowDirection: .down)
                            }
                            self.present(alert, animated: true, completion: nil)
                        }
                    default:
                        self.operationQueue.addOperation {
                            self.vibrate(occured: .error)
                        }
                        let alert = UIAlertController(title: ErrorTitleLocalized.networkError, message: ErrorMessageLocalized.networkError, preferredStyle: .actionSheet)
                        alert.addAction(UIAlertAction(title: NSLocalizedString("Ok", comment: "Ok for close network error alert"), style: .cancel, handler: nil))
                        if let popoverPresentationController = alert.popoverPresentationController {
                            self.preparePopoverPresentationFrame(popoverPC: popoverPresentationController, view: self.backupButton.value(forKey: "view") as! UIView, arrowDirection: .down)
                        }
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
    
    @objc func logoutWithConfirm() {
        let wipeAccountAlert = UIAlertController(title: TitleLocalized.confirmLogout, message: MessagesLocalized.wipeAccountMessage, preferredStyle: .actionSheet)
        wipeAccountAlert.addAction(UIAlertAction(title: ButtonLabelLocalized.cancel, style: .cancel, handler: nil))
        wipeAccountAlert.addAction(UIAlertAction(title: ButtonLabelLocalized.confirmWipeAccount, style: .destructive) {
            (action) in
            self.logout()
        })
        if let popoverPresentationController = wipeAccountAlert.popoverPresentationController {
            self.preparePopoverPresentationFrame(popoverPC: popoverPresentationController, view: self.navigationItem.rightBarButtonItem!.value(forKey: "view") as! UIView, arrowDirection: .up)
        }
        self.present(wipeAccountAlert, animated: true, completion: nil)
    }
    
    func popoverPresentationController(_ popoverPresentationController: UIPopoverPresentationController, willRepositionPopoverTo rect: UnsafeMutablePointer<CGRect>, in view: AutoreleasingUnsafeMutablePointer<UIView>) {
        let frame = popoverPresentationController.presentingViewController.view.frame
        let deltaX = frame.height - rect.pointee.midX
        let deltaY = frame.width - rect.pointee.midY
        if rect.pointee.maxY < frame.height/2 {
            rect.pointee = CGRect(x: frame.width - deltaX, y: rect.pointee.maxY, width: 0, height: 0)
        }
        else {
            rect.pointee = CGRect(x: rect.pointee.minX, y: frame.height - deltaY, width: 0, height: 0)
        }
    }
    
    func preparePopoverPresentationFrame(popoverPC: UIPopoverPresentationController, view: UIView, arrowDirection: UIPopoverArrowDirection) {
        popoverPC.sourceView = self.view
        popoverPC.delegate = self
        let frame = view.frame
        let convertedFrame = self.view.convert(frame, from: view)
        var popoverOffsetX: CGFloat
        var popoverOffsetY: CGFloat
        switch arrowDirection {
        case .up:
            popoverOffsetY = 20
            popoverOffsetX = CGFloat.zero
        case .down:
            popoverOffsetY = -20
            popoverOffsetX = CGFloat.zero
        case .left:
            popoverOffsetX = 20
            popoverOffsetY = CGFloat.zero
        case .right:
            popoverOffsetX = -20
            popoverOffsetY = CGFloat.zero
        default:
            popoverOffsetX = CGFloat.zero
            popoverOffsetY = CGFloat.zero
        }
        popoverPC.sourceRect = CGRect(x: convertedFrame.midX + popoverOffsetX, y: convertedFrame.midY + popoverOffsetY, width: 0, height: 0)
        popoverPC.permittedArrowDirections = arrowDirection
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
    
    func setPasscode(passcode: String) {
        User.passcode = passcode
        User.appLocked = true
    }
    
    func setSuccessedUnlock() {
        self.currentUser.unlocked = true
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
        if self.currentUser.noteDataSource.notes.count == 0 {
            self.backupButton.isEnabled = false
        }
        else {
            self.backupButton.isEnabled = true
        }
        
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
