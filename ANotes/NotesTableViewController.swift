//
//  NotesTableViewController.swift
//  ANotes
//
//  Created by Dmitry Teplyakov on 27.10.2020.
//

import UIKit

class NotesTableViewController: UITableViewController {
    var userDataSource = UserDataSource()
    var userStore: UserStore!
    var currentUser: User!
    @IBOutlet var lastUpdateDateLabel: BarLabelItem!
    var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.doesRelativeDateFormatting = true
        return formatter
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.delegate = self
        self.currentUser = self.userStore.user
        self.userDataSource.user = self.userStore.user
        self.tableView.dataSource = self.currentUser.noteDataSource
        self.syncData()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.updateLastSyncDate(date: self.currentUser.noteDataSource.lastSyncDate)
    }
        
    /// Update last updated date label
    /// - Parameter date: Date for display in format: Updated Today at 12:34
    private func updateLastSyncDate(date: Date?) {
        if let date = date {
            self.lastUpdateDateLabel.text = self.dateFormatter.string(from: date)
        }
        else {
            self.lastUpdateDateLabel.text = nil
        }
    }
    
    /// Restore and backup local storage with backend
    func syncData() {
        AnotesApi.fetchNotes(for: currentUser) {
            (result) in
            
            OperationQueue.main.addOperation {
                switch result {
                case let .FetchSuccess(notesArray):
                    self.currentUser.noteDataSource.notes = notesArray
                    self.currentUser.noteDataSource.lastSyncDate = Date()
                    self.updateLastSyncDate(date: self.currentUser.noteDataSource.lastSyncDate)
                    self.tableView.reloadData()
                case let .Failure(error):
                    switch error {
                    case AnotesError.AuthError:
                        let alert = UIAlertController(title: ErrorTitleLocalized.syncFailed, message: ErrorMessageLocalized.AuthenticationTokenError, preferredStyle: .actionSheet)
                        alert.addAction(UIAlertAction(title: ButtonLabelLocalized.cancel, style: .cancel, handler: nil))
                        alert.addAction(UIAlertAction(title: ButtonLabelLocalized.logout, style: .destructive) {
                            (action) in
                            
                            let wipeAccountAlert = UIAlertController(title: TitleLocalized.confirmLogout, message: MessagesLocalized.wipeAccountMessage, preferredStyle: .actionSheet)
                            wipeAccountAlert.addAction(UIAlertAction(title: ButtonLabelLocalized.cancel, style: .cancel, handler: nil))
                            wipeAccountAlert.addAction(UIAlertAction(title: ButtonLabelLocalized.confirmWipeAccount, style: .destructive) {
                                (action) in
                                
                                self.logout()
                            })
                            self.present(wipeAccountAlert, animated: true, completion: nil)
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
            }
        }
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
}
