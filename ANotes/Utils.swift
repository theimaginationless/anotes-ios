//
//  Utils.swift
//  ANotes
//
//  Created by Dmitry Teplyakov on 08.12.2020.
//

import UIKit
import LocalAuthentication

class Utils {
    class func checkAvailableBiometryAuthentication(for policy: LAPolicy) -> Bool {
        let context = LAContext()
        
        var error: NSError?
        let result = context.canEvaluatePolicy(policy, error: &error)
        
        guard error == nil else {
            Swift.debugPrint(error!.description)
            return false
        }
        
        return result
    }
    
    class func keyboardFrame(_ notification: Notification) -> CGRect? {
        guard let userInfo = notification.userInfo,
              let keyboardSize = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else {
            return nil
        }
        
        let keyboardFrame = keyboardSize.cgRectValue
        return keyboardFrame
    }
    
    class func calculateViewByKeyboardDeltaY(sourceView: UIView, targetView: UIView, keyboardFrame: CGRect, padding: CGFloat = 0) -> CGFloat {
        let textFieldCoords = targetView.convert(sourceView.frame, from: sourceView)
        let deltaY = textFieldCoords.maxY - keyboardFrame.minY + padding
        return deltaY
    }
}
