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
}
