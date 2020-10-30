//
//  NotesTableViewController.swift
//  ANotes
//
//  Created by Dmitry Teplyakov on 27.10.2020.
//

import UIKit
import LocalAuthentication

class NotesTableViewController: UITableViewController {
    var userDataSource = UserDataSource()
    var userStore: UserStore!
    var currentUser: User!
    var isBiometricAuthEnabled: Bool {
        get {
            UserDefaults.standard.bool(forKey: SettingKeys.BiometricAuth)
        }
        set {
            UserDefaults.standard.setValue(false, forKey: SettingKeys.BiometricAuth)
        }
    }
    @IBOutlet var lastUpdateDateLabel: BarLabelItem!
    @IBOutlet var userButton: UIBarButtonItem!
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
        self.tableView.dataSource = self.currentUser.noteDataSource
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.updateLastSyncDate(date: self.currentUser.noteDataSource.lastSyncDate)
        self.syncData()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if isBiometricAuthEnabled {
            self.biometricAuthentication()
        }
    }
        
    /// Update last updated date label
    /// - Parameter date: Date for display in format: Updated Today at 12:34
    private func updateLastSyncDate(date: Date?) {
        if let date = date {
            self.lastUpdateDateLabel.date = self.dateFormatter.string(from: date)
        }
        else {
            self.lastUpdateDateLabel.date = nil
        }
    }
    
    /// Restore and backup local storage with backend
    func syncData() {
        let previousStatus = self.lastUpdateDateLabel.text
        self.lastUpdateDateLabel.text = NSLocalizedString("Updating...", comment: "Updating status")
        AnotesApi.fetchNotes(for: currentUser) {
            (result) in
            
            OperationQueue.main.addOperation {
                switch result {
                case let .FetchSuccess(notesArray):
                    self.currentUser.noteDataSource.notes = notesArray
                    self.currentUser.noteDataSource.lastSyncDate = Date()
                    self.updateLastSyncDate(date: self.currentUser.noteDataSource.lastSyncDate)
                    self.tableView.reloadData()
                    return
                case let .Failure(error):
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
                    let alert = UIAlertController(title: ErrorTitleLocalized.networkError, message: ErrorMessageLocalized.networkError, preferredStyle: .actionSheet)
                    alert.addAction(UIAlertAction(title: NSLocalizedString("Ok", comment: "Ok for close network error alert"), style: .cancel, handler: nil))
                    self.present(alert, animated: true, completion: nil)
                }
                
                self.lastUpdateDateLabel.text = previousStatus
            }
        }
    }
    
    @IBAction func logoutAction(_ sender: Any) {
        self.logoutWithConfirm()
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
        self.currentUser.noteDataSource.notes.removeAll()
        let loginAndRegisterStoryboard = UIStoryboard(name: "LoginAndRegister", bundle: nil)
        guard let loginVC = loginAndRegisterStoryboard.instantiateViewController(identifier: "LoginViewController") as? LoginViewController else {
            print("Cannot instantiate LoginViewController")
            return
        }
        
        self.userDataSource.user = nil
        loginVC.userStore = self.userStore
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
        let reason = "FaceID authentication"
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
    
    func securedViewCover(enable: Bool) {
        let blurEffect = UIBlurEffect(style: .light)
        
        let blurredEffectView = UIVisualEffectView(effect: blurEffect)
        blurredEffectView.frame = self.view.window!.frame
        blurredEffectView.translatesAutoresizingMaskIntoConstraints = false
        let rootController = self.view.window!.rootViewController!
        let tag = 1
        if enable {
            blurredEffectView.tag = tag
            rootController.view.addSubview(blurredEffectView)
        }
        else {
            let view = rootController.view.viewWithTag(tag)!
            UIView.animate(withDuration: 0.3, delay: 0.4, options: .curveLinear, animations: {
                view.alpha = 0
            }, completion: {
                result in
                view.removeFromSuperview()
            })
        }
    }
}
