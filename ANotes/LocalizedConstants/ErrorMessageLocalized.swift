//
//  ErrorMessageLocalized.swift
//  ANotes
//
//  Created by Dmitry Teplyakov on 29.10.2020.
//

import Foundation

struct ErrorMessageLocalized {
    public static let networkError = NSLocalizedString("Check your network connection and try again ", comment: "Message for network error")
    public static let authenticationError = NSLocalizedString("Authentication error.\nCheck username and password and try it again.", comment: "Message for authentication error")
    public static let userExists = NSLocalizedString("User is already exists.", comment: "Error message for user already exists on register page")
    public static let unknownError = NSLocalizedString("Unknown error.", comment: "Error message for unknown error on register page")
    public static let AuthenticationTokenError = NSLocalizedString("Authentication token isn't valid. Try log out and in again.", comment: "Authentication token error")
}
