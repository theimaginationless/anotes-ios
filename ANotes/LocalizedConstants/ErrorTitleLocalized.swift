//
//  ErrorTitleLocalized.swift
//  ANotes
//
//  Created by Dmitry Teplyakov on 29.10.2020.
//

import Foundation

struct ErrorTitleLocalized {
    public static let networkError = NSLocalizedString("Network error", comment: "Title for network error alert")
    public static let syncFailed = NSLocalizedString("Sync failed", comment: "Title for sync failed alert")
    public static let incorrectUsernamePassword = NSLocalizedString("Incorrect username or password", comment: "Title for empty username or password fields when log in")
    public static let accessDenied = NSLocalizedString("Access denied", comment: "Title for authentication error")
    public static let restoreFromLocalFailed = NSLocalizedString("Restore error", comment: "Title for restore from local error")
    public static let unknownError = NSLocalizedString("Unknown error", comment: "Title for unknown error")
}
