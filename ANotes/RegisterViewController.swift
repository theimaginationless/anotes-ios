//
//  RegisterViewController.swift
//  ANotes
//
//  Created by Dmitry Teplyakov on 26.10.2020.
//

import UIKit

protocol ContinuousLoginDelegate {
    func login(for: User)
}

class RegisterViewController: UIViewController {
    var userStore: UserStore!
    var continuousLoginDelegate: ContinuousLoginDelegate!
    
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
    }
    
    @IBAction func register(_ sender: Any) {
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
                        self.continuousLoginDelegate.login(for: user)
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
                    self.setErrorMessage(message: ErrorMessageLocalized.unknownError)
                    break
                }
                
                self.registerButton.isEnabled = true
            }
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
