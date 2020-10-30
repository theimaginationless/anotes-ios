//
//  LoginAndRegisterViewController.swift
//  ANotes
//
//  Created by Dmitry Teplyakov on 26.10.2020.
//

import UIKit

class LoginViewController: UIViewController, ContinuousLoginDelegate {
    @IBOutlet var usernameTextField: UITextField!
    @IBOutlet var passwordTextField: UITextField!
    @IBOutlet var loginButton: UIRoundedButton!
    var userStore: UserStore!
    override open var shouldAutorotate: Bool {
        return false
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let dismissKeyboardGesture = UISwipeGestureRecognizer(target: self, action: #selector(hideKeyboard))
        dismissKeyboardGesture.direction = .down
        self.view.addGestureRecognizer(dismissKeyboardGesture)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    @IBAction func loginButtonAction(_ sender: Any) {
        self.hideKeyboard()
        
        guard
            let username = self.usernameTextField.text,
            let password = self.passwordTextField.text else {
            return
        }
        
        if username.isEmpty || password.isEmpty {
            let alert = UIAlertController(title: ErrorTitleLocalized.incorrectUsernamePassword, message: NSLocalizedString("Username or password cannot be empty. \nPlease enter and try again.", comment: "Message for empty username or password fields when log in"), preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: NSLocalizedString("Ok", comment: "Ok for close UIAlert when username or password is empty"), style: .cancel, handler: nil))
            self.present(alert, animated: true, completion: nil)
            return
        }
        
        self.authenticateWith(username: username, password: password)
    }
    
    /// Authenticate with passed username and log in
    /// - Parameter username: name of user that needs authenticate
    /// - Parameter password: password of user that needs authenticate
    func authenticateWith(username: String, password: String) {
        self.loginButton.isEnabled = false
        AnotesApi.authenticate(username: username, password: password) {
            (result) in
            
            OperationQueue.main.addOperation {
                switch result {
                case let .AuthSuccess(token):
                    let user = User(username: username, password: password, fullname: "", authToken: token)
                    print("Authentication successfull!")
                    self.login(for: user)
                    
                case let .Failure(error):
                    switch error {
                    case AnotesError.AuthError:
                        print("Authentication error: \(error)")
                        let alert = UIAlertController(title: ErrorTitleLocalized.accessDenied , message: ErrorMessageLocalized.authenticationError, preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: NSLocalizedString("Ok", comment: "Ok for close UIAlert when username or password is invalid"), style: .cancel, handler: nil))
                        self.present(alert, animated: true, completion: nil)
                    default:
                        print("Unexpected error: \(error)")
                        let alert = UIAlertController(title: ErrorTitleLocalized.networkError, message: ErrorMessageLocalized.networkError, preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: NSLocalizedString("Ok", comment: "Ok for close UIAlert when network error"), style: .cancel, handler: nil))
                        self.present(alert, animated: true, completion: nil)
                    }
                default:
                    print("Nothing scenatio for \(result)")
                    let alert = UIAlertController(title: ErrorTitleLocalized.networkError, message: ErrorMessageLocalized.networkError, preferredStyle: .actionSheet)
                    alert.addAction(UIAlertAction(title: NSLocalizedString("Ok", comment: "Ok for close UIAlert when network error"), style: .cancel, handler: nil))
                    self.present(alert, animated: true, completion: nil)
                }
                
                self.loginButton.isEnabled = true
            }
        }
    }
    
    /// Method for log in specified user and go to main application ViewController
    /// - Parameter user: user for log in
    func login(for user: User) {
        userStore.user = user
        let mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
        guard let mainNC = mainStoryboard.instantiateViewController(identifier: "MainNavigationController") as? MainNavigationController,
              let notesVC = mainNC.children.first as? NotesTableViewController else {
            print("Error when instantiate mainNC and notesVC")
            return
        }
        
        notesVC.userStore = self.userStore
        mainNC.modalPresentationStyle = .overCurrentContext
        mainNC.modalTransitionStyle = .flipHorizontal
        self.present(mainNC, animated: true)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "SignUpSegue" {
            if let destinationVC = segue.destination as? RegisterViewController {
                destinationVC.userStore = self.userStore
                destinationVC.continuousLoginDelegate = self
            }
        }
    }
    
    @objc func hideKeyboard() {
        self.view.endEditing(true)
    }
}
