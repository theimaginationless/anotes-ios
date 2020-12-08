//
//  PinPassViewController.swift
//  ANotes
//
//  Created by Dmitry Teplyakov on 07.12.2020.
//

import UIKit
import LocalAuthentication

@objc protocol ApplicationLockBiometricAuthenticationDelegate {
    func setSuccessedUnlock()
    func setPasscode(passcode: String)
    @objc optional func completionIfSuccess(vc: UIViewController?)
}

class PinPassViewController: UIViewController {
    var delegate: ApplicationLockBiometricAuthenticationDelegate?
    var userStore: UserStore!
    @IBOutlet weak var pinTextField: UITextField!
    @IBOutlet weak var deleteButton: UIButton!
    @IBOutlet weak var faceIDButton: UIButton!
    var animationSpeed: TimeInterval! = 0.2
    private var passcodeComplete: Bool {
        get {
            self.pinTextField.text?.count == 4 ? true : false
        }
    }
    var originPasscode: String?
    private var confirmPasscode: String?
    var setUp: Bool!
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if self.setUp {
            self.faceIDButton.alpha = .zero
        }
        else {
            guard #available(iOS 8.0, *) else {
                self.faceIDButton.alpha = .zero
                return
            }
            
            self.faceIDButton.isEnabled = Utils.checkAvailableBiometryAuthentication(for: .deviceOwnerAuthenticationWithBiometrics)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if !self.setUp {
            self.biometricAuthentication()
        }
    }
    
    /// Append character to passcode field
    /// - Parameter characted: digit character
    private func appendPasscode(character: Character) -> Bool {
        UIView.transition(with: self.pinTextField, duration: animationSpeed, options: .transitionCrossDissolve) {
            self.pinTextField.text?.append(character)
        }
        return self.passcodeComplete
    }
    
    private func removeLastPasscodeCharacter() {
        UIView.transition(with: self.pinTextField, duration: animationSpeed, options: .transitionCrossDissolve) {
            if !self.pinTextField.text!.isEmpty {
                self.pinTextField.text!.removeLast()
            }
        }
    }
    
    private func biometricAuthentication() {
        guard #available(iOS 8.0, *) else {
            return
        }
        let context = LAContext()
        
        guard Utils.checkAvailableBiometryAuthentication(for: .deviceOwnerAuthenticationWithBiometrics) else {
            return
        }
        
        let reason = NSLocalizedString("Needs for unlock application", comment: "Reason FaceID using request")
        context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) {
            isAuthorized, error in
            guard isAuthorized == true else {
                return
            }
            
            OperationQueue.main.addOperation {
                self.allChecksPassed()
            }
        }
    }
    
    @IBAction func faceIdButton(_ sender: Any) {
        self.biometricAuthentication()
    }
    
    @IBAction func deleteButton(_ sender: Any) {
        self.removeLastPasscodeCharacter()
    }
    
    @IBAction func oneDigitButton(_ sender: Any) {
        if self.appendPasscode(character: "1") {
            self.passcodeCompletion()
        }
    }
    @IBAction func twoDigitButton(_ sender: Any) {
        if self.appendPasscode(character: "2") {
            self.passcodeCompletion()
        }
    }
    @IBAction func threeDigitButton(_ sender: Any) {
        if self.appendPasscode(character: "3") {
            self.passcodeCompletion()
        }
    }
    @IBAction func fourDigitButton(_ sender: Any) {
        if self.appendPasscode(character: "4") {
            self.passcodeCompletion()
        }
    }
    @IBAction func fiveDigitButton(_ sender: Any) {
        if self.appendPasscode(character: "5") {
            self.passcodeCompletion()
        }
    }
    @IBAction func sixDigitButton(_ sender: Any) {
        if self.appendPasscode(character: "6") {
            self.passcodeCompletion()
        }
    }
    @IBAction func sevenDigitButton(_ sender: Any) {
        if self.appendPasscode(character: "7") {
            self.passcodeCompletion()
        }
    }
    @IBAction func eightDigitButton(_ sender: Any) {
        if self.appendPasscode(character: "8") {
            self.passcodeCompletion()
        }
    }
    @IBAction func nineDigitButton(_ sender: Any) {
        if self.appendPasscode(character: "9") {
            self.passcodeCompletion()
        }
    }
    @IBAction func zeroDigitButton(_ sender: Any) {
        if self.appendPasscode(character: "0") {
            self.passcodeCompletion()
        }
    }
    
    private func passcodeCompletion() {
        if self.setUp {
            if !self.setup() {return}
            self.delegate?.setPasscode(passcode: self.originPasscode!)
        }
        else {
            if self.originPasscode == self.pinTextField.text! {
                self.vibrate(occured: .success)
            }
            else {
                self.vibrate(occured: .error)
                UIView.transition(with: self.pinTextField, duration: self.animationSpeed, options: .transitionCrossDissolve) {
                    self.pinTextField.text = ""
                }
                self.confirmPasscode = nil
                return
            }
        }
        
        self.allChecksPassed()
    }
    
    private func allChecksPassed() {
        self.delegate?.setSuccessedUnlock()
        self.delegate?.setPasscode(passcode: self.originPasscode!)
        self.dismiss(animated: true) {
            self.delegate?.completionIfSuccess?(vc: self)
        }
    }
    
    /// Set up application lock
    /// - Returns: true is setup completed successfuly, false otherwise.
    private func setup() -> Bool {
        if self.originPasscode == nil {
            self.originPasscode = self.pinTextField.text
        }
        else {
            self.confirmPasscode = self.pinTextField.text
        }
        
        usleep(UInt32(self.animationSpeed * 100))
        if self.setUp && self.confirmPasscode == nil {
            UIView.transition(with: self.pinTextField, duration: animationSpeed, options: .transitionCrossDissolve) {
                self.pinTextField.text = ""
            }
            return false
        }
        
        if self.originPasscode == self.confirmPasscode {
            self.vibrate(occured: .success)
        }
        else {
            self.vibrate(occured: .error)
            self.pinTextField.text = ""
            self.originPasscode = nil
            self.confirmPasscode = nil
            return false
        }
        
        return true
    }
    
    private func vibrate(occured: UINotificationFeedbackGenerator.FeedbackType) {
        let feedbackGenerator = UINotificationFeedbackGenerator()
        feedbackGenerator.notificationOccurred(occured)
    }
}
