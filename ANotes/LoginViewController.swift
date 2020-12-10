//
//  LoginAndRegisterViewController.swift
//  ANotes
//
//  Created by Dmitry Teplyakov on 26.10.2020.
//

import UIKit

class LoginViewController: UIViewController, ContinuousLoginDelegate, UITextFieldDelegate {
    @IBOutlet var usernameTextField: UITextField!
    @IBOutlet var passwordTextField: UITextField!
    @IBOutlet var loginButton: UIRoundedButton!
    var userStore: UserStore!
    var currentEditedTextField: UITextField?
    override open var shouldAutorotate: Bool {
        return false
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let dismissKeyboardGesture = UISwipeGestureRecognizer(target: self, action: #selector(hideKeyboard))
        dismissKeyboardGesture.direction = .down
        self.view.addGestureRecognizer(dismissKeyboardGesture)
        self.usernameTextField.delegate = self
        self.passwordTextField.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillDismiss(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    @IBAction func loginButtonAction(_ sender: Any? = nil) {
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
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        switch textField.returnKeyType {
        case .next:
            self.usernameTextField.resignFirstResponder()
            self.passwordTextField.becomeFirstResponder()
        case .join:
            self.passwordTextField.resignFirstResponder()
            self.loginButtonAction()
        default:
            break
        }
        
        return true
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        self.currentEditedTextField = textField
    }
    
    @objc private func keyboardWillShow(_ notification: Notification) {
        guard let keyboardFrame = Utils.keyboardFrame(notification),
              let textField = self.currentEditedTextField else {
            return
        }
        
        let deltaY = Utils.calculateViewByKeyboardDeltaY(sourceView: textField, targetView: self.view, keyboardFrame: keyboardFrame, padding: 8)
        if self.view.frame.origin.y == 0 && deltaY > 0 {
            self.view.frame.origin.y -= deltaY
        }
    }
    
    @objc private func keyboardWillDismiss(_ notification: Notification) {
        if self.view.frame.origin.y != 0 {
            self.view.frame.origin.y = 0
        }
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
        self.userStore.user = user
        User.saveSession(for: user)
        self.showNotesTableViewControllerWith(userStore: self.userStore)
    }
    
    func showNotesTableViewControllerWith(userStore: UserStore) {
        let mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
        guard let mainNC = mainStoryboard.instantiateViewController(identifier: "MainNavigationController") as? MainNavigationController,
              let notesVC = mainNC.children.first as? NotesTableViewController else {
            print("Error when instantiate mainNC and notesVC")
            return
        }
        
        notesVC.userStore = userStore
        mainNC.modalPresentationStyle = .fullScreen
        mainNC.modalTransitionStyle = .flipHorizontal
        self.present(mainNC, animated: true)
    }
    
    func backWithLogin(for user: User) {
        self.loginButton.isEnabled = false
        self.userStore.user = user
        self.setTextFieldWithAnimation(text: self.userStore.user!.username, field: self.usernameTextField, animationDuring: 0.3)
        self.setTextFieldWithAnimation(text: self.userStore.user!.password, field: self.passwordTextField, animationDuring: 0.3)
        self.loginButton.isEnabled = true
        User.saveSession(for: user)
        self.showNotesTableViewControllerWith(userStore: self.userStore)
    }
    
    func setTextFieldWithAnimation(text: String, field: UITextField, animationDuring: TimeInterval) {
        UIView.transition(with: self.usernameTextField, duration: 0.3, options: .transitionCrossDissolve) {
            for character in text {
                field.text!.append(character)
            }
        }
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
