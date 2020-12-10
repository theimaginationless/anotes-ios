//
//  RegisterViewController.swift
//  ANotes
//
//  Created by Dmitry Teplyakov on 26.10.2020.
//

import UIKit

protocol ContinuousLoginDelegate {
    func backWithLogin(for: User)
}

class RegisterViewController: UIViewController, UITextFieldDelegate {
    var userStore: UserStore!
    var continuousLoginDelegate: ContinuousLoginDelegate!
    var currentEditedTextField: UITextField?
    
    @IBOutlet var usernameTextField: UITextField!
    @IBOutlet var passwordTextField: UITextField!
    @IBOutlet var registerButton: UIRoundedButton!
    @IBOutlet var errorMessageLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        usernameTextField.addTarget(self, action: #selector(usernamePasswordTextDidChange(_:)), for: .editingChanged)
        passwordTextField.addTarget(self, action: #selector(usernamePasswordTextDidChange(_:)), for: .editingChanged)
        let dismissKeyboardTap = UITapGestureRecognizer(target: self, action: #selector(self.hideKeyboard))
        self.view.addGestureRecognizer(dismissKeyboardTap)
        self.usernameTextField.delegate = self
        self.passwordTextField.delegate = self
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillDismiss(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        NotificationCenter.default.removeObserver(self)
    }
    
    @IBAction func register(_ sender: Any? = nil) {
        guard
            let username = self.usernameTextField.text,
            let password = self.passwordTextField.text else {
            return
        }
        
        if username.isEmpty || password.isEmpty {
            self.setErrorMessage(message: NSLocalizedString("Username or password cannot be empty.", comment: "Error message for empty username or password on register page"))
            return
        }
        
        self.registerButton.isEnabled = false
        AnotesApi.register(username: username, password: password) {
            (result) in
            
            OperationQueue.main.addOperation {
                switch(result) {
                case let .AuthSuccess(token):
                    print("Register successful!")
                    let user = User(username: username, password: password, fullname: "", authToken: token)
                    self.userStore.user = user
                    usleep(20)
                    self.dismiss(animated: true) {
                        self.continuousLoginDelegate.backWithLogin(for: user)
                    }
                case let .Failure(error):
                    switch error {
                    case AnotesError.UserExistsError:
                        self.setErrorMessage(message: ErrorMessageLocalized.userExists)
                        break
                    default:
                        self.setErrorMessage(message: ErrorMessageLocalized.networkError)
                        break
                    }
                default:
                    self.setErrorMessage(message: ErrorTitleLocalized.unknownError + ErrorMessageLocalized.unknownError)
                    break
                }
                
                self.registerButton.isEnabled = true
            }
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        switch textField.returnKeyType {
        case .next:
            self.usernameTextField.resignFirstResponder()
            self.passwordTextField.becomeFirstResponder()
        case .join:
            self.passwordTextField.resignFirstResponder()
            self.register()
        default:
            break
        }
        
        return true
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        self.currentEditedTextField = textField
    }
    
    @objc func keyboardWillShow(_ notification: Notification) {
        guard let keyboardFrame = Utils.keyboardFrame(notification),
              let textField = self.currentEditedTextField else {
            return
        }
        
        
        // padding: -10 as compensation offset when using self.view like modal ViewController
        // Animate prevent ugly bouncing view.
        let deltaY = Utils.calculateViewByKeyboardDeltaY(sourceView: textField, targetView: self.view.window!.rootViewController!.view, keyboardFrame: keyboardFrame, padding: -10)
        if self.view.frame.origin.y == 0 && deltaY > 0 {
            UIView.animate(withDuration: 0.2) {
                self.view.frame.origin.y -= deltaY
            }
        }
    }
    
    @objc func keyboardWillDismiss(_ notification: Notification) {
        if self.view.frame.origin.y != 0 {
            self.view.frame.origin.y = 0
        }
    }
    
    @objc func usernamePasswordTextDidChange(_ textField: UITextField) {
        self.errorMessageLabel.isHidden = true
    }
    
    func setErrorMessage(message: String) {
        errorMessageLabel.text = message
        errorMessageLabel.isHidden = false
    }
    
    @objc func hideKeyboard() {
        self.view.endEditing(true)
    }
}
