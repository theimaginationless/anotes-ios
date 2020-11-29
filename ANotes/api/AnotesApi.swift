//
//  AnotesApi.swift
//  ANotes
//
//  Created by Dmitry Teplyakov on 25.10.2020.
//

import Foundation
import CoreData

enum Endpoint: String {
    case login = "/login"
    case register = "/register"
    case backup = "/api/backup"
    case restore = "/api/restore"
}

enum AnotesResult {
    case AuthSuccess(String)
    case RestoreSuccess([Note])
    case DataRestoreSuccess(Data?)
    case BackupSuccess
    case JSONFromDataSuccess([String:AnyObject])
    case Failure(Error)
}

enum AnotesError: Error {
    case InvalidJSONFormat
    case NothingRestore
    case EmptyJSONData
    case JSONFromDataError
    case AuthError
    case UserExistsError
    case BadResponse
    case NetworkError(String)
    case UnknownError(String)
}

enum RequestType: String {
    case POST = "POST"
    case GET = "GET"
}

enum Operation {
    case Restore
    case Backup
}

struct AnotesApi {
    private static var baseUrlString: String! {
        get {
            UserDefaults.standard.string(forKey: SettingKeys.Backend) ?? ""
        }
    }
    private static let session: URLSession = {
        let config = URLSessionConfiguration.default
        return URLSession(configuration: config)
    }()
    
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        return formatter
    }()
    
    private static func anotesUrl(endpoint: Endpoint) -> URL? {
        guard let components = URLComponents(string: baseUrlString + endpoint.rawValue) else {
            return nil
        }
        
        print("anotesUrl generated: \(components.url?.description ?? "")")
        return components.url
    }
    
    /// Fetch result to completion
    /// - Parameter url: URL for request
    /// - Parameter requestType: Type of request
    /// - Parameter jsonBody: JSON Body for request
    /// - Parameter headerParams: Additional http header parameters for request
    /// - Parameter completion: Completion handler for use response
    private static func fetchRequestResult(url: URL, type requestType: RequestType, jsonBody: [String:String]?, headerParams: [String:String]?, completion: @escaping (AnotesResult) -> Void) {
        var request = URLRequest(url: url)
        request.httpMethod = requestType.rawValue
        request.addValue("application/json", forHTTPHeaderField: "Content-Tyoe")
        headerParams?.forEach{request.addValue($0.key, forHTTPHeaderField: $0.value)}
                
        if let jsonBody = jsonBody,
           let jsonBodyData = try? JSONSerialization.data(withJSONObject: jsonBody, options: []) {
            request.httpBody = jsonBodyData
        }
        else {
            return
        }
        
        let task = session.dataTask(with: request) {
            (data, response, error) in
            
            let result = self.JSONFrom(data: data)
            completion(result)
        }
        
        task.resume()
    }
    
    /// Fetch authentication token for specific user.
    /// - Parameter url: url for request
    /// - Parameter username: contains username for authentication
    /// - Parameter password: password for this user
    /// - Parameter completion: Completion handler for setting up authentication token
    private static func fetchAuthenticationResult(url: URL, jsonBody: [String:String], completion: @escaping (AnotesResult) -> Void) {
        var request = URLRequest(url: url)
        request.httpMethod = RequestType.POST.rawValue
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let jsonBodyData = try? JSONSerialization.data(withJSONObject: jsonBody, options: []) {
            request.httpBody = jsonBodyData
        }
        
        let task = session.dataTask(with: request) {
            (data, response, error) in
            
            let result = self.authHeaderProcessing(header: response)
            completion(result)
        }
        
        task.resume()
    }

    
    /// Authenticate specific user and returns authentication token through completion handler
    /// - Parameter username: username for authentication
    /// - Parameter password: password for authentication
    /// - Parameter completion: completion handler for operating with authentication token
    static func authenticate(username: String, password: String, completion: @escaping (AnotesResult) -> Void) {
        guard let url = self.anotesUrl(endpoint: .login) else {
            return
        }
        
        let dict = ["nickname":username,
                    "password":password]
        
        self.fetchAuthenticationResult(url: url, jsonBody: dict, completion: completion)
    }
    
    /// Register user with throwing credentials and returns authentication token through completion handler
    /// - Parameter username:username
    /// - Parameter password;  password
    /// - Parameter completion: completion handler for operating with authentication token
    /// - Warning: Now this method uses same logic that authenticate method.
    static func register(username: String, password: String, completion: @escaping (AnotesResult) -> Void) {
        guard let url = self.anotesUrl(endpoint: .register) else {
            return
        }
        
        let dict = ["nickname":username,
                    "password":password]
        
        self.fetchAuthenticationResult(url: url, jsonBody: dict, completion: completion)
    }
    
    /// Extract authentication token from response's header
    /// - Parameter header: header with authentication token
    /// - Returns: AnotesResult with token or error
    private static func authHeaderProcessing(header: URLResponse?) -> AnotesResult {
        guard let responseHeader = header as? HTTPURLResponse else {
            return .Failure(AnotesError.BadResponse)
        }
        
        switch responseHeader.statusCode {
        case 200...299:
            if let authToken = responseHeader.allHeaderFields["Authorization"] as? String {
                return .AuthSuccess(authToken)
            }
        case 403:
            return .Failure(AnotesError.AuthError)
        case 400:
            return .Failure(AnotesError.UserExistsError)
        default:
            return .Failure(AnotesError.UnknownError(""))
        }

        return .Failure(AnotesError.BadResponse)
    }
    
    private static func JSONFrom(data: Data?) -> AnotesResult {
        guard let jsonData = data else {
            return .Failure(AnotesError.EmptyJSONData)
        }
        
        return jsonFromData(from: jsonData)
    }
    
    /// Extract note instance from JSON dictionary representation
    /// - Parameter object: JSONised dictionary
    /// - Parameter inContext: CoreData context
    private static func noteFromJSON(object: [String:AnyObject], inContext context: NSManagedObjectContext) -> Note? {
        guard
            let title = object["title"] as? String,
            let text = object["text"] as? String,
            let pinned = object["pinned"] as? Bool,
            let creationDateString = object["creationDate"] as? String,
            let editDateString = object["editDate"] as? String,
            let creationDate = dateFormatter.date(from: creationDateString),
            let editDate = dateFormatter.date(from: editDateString) else {
            
            return nil
        }
        
        var reminderDate: Date? = nil
        let reminderDateString = object["reminderDate"] as? String
        if reminderDateString != nil {
            reminderDate = dateFormatter.date(from: reminderDateString!)
        }
        
        var note: Note!
        context.performAndWait {
            note = (NSEntityDescription.insertNewObject(forEntityName: "Note", into: context) as! Note)
            note.title = title
            note.text = text
            note.pinned = pinned
            note.reminderDate = reminderDate
            note.creationDate = creationDate
            note.editDate = editDate
        }
        
        return note
    }
    
    private static func jsonFromData(from data: Data) -> AnotesResult {
        do {
            let jsonObject: Any = try JSONSerialization.jsonObject(with: data, options: [])
            
            guard let jsonDict = jsonObject as? [String:AnyObject] else {
                return .Failure(AnotesError.JSONFromDataError)
            }
            
            return AnotesResult.JSONFromDataSuccess(jsonDict)
        }
        catch let error {
            return .Failure(error)
        }
    }
    
    /// Fetch data from backend
    /// - Parameter for: user
    /// - Parameter completion: completion for using fetched data
    /// - Description: Make request to backend and return last snapshot
    static func fetchNotesData(for user: User, completion: @escaping (AnotesResult) -> Void) {
        guard let url = self.anotesUrl(endpoint: .restore) else {
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = RequestType.GET.rawValue
        request.addValue(user.authToken, forHTTPHeaderField: "Authorization")
        let task = self.session.dataTask(with: request) {
            (data, response, error) in
            
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.Failure(AnotesError.BadResponse))
                return
            }
            
            switch httpResponse.statusCode {
            case 200...299:
                completion(.DataRestoreSuccess(data))
                return
            case 403:
                print("Status code: \(httpResponse.statusCode). Token expired? Try to refresh it!")
                self.authenticate(username: user.username, password: user.password) {
                    (result) in
                    switch result {
                    case let .AuthSuccess(token):
                        print("Authentication succesful!")
                        user.authToken = token
                        self.fetchNotesData(for: user, completion: completion)
                    default:
                        completion(.Failure(AnotesError.AuthError))
                    }
                }
                return
            case 404:
                completion(.Failure(AnotesError.NetworkError("")))
                return
            default:
                completion(.Failure(AnotesError.UnknownError("\(NSLocalizedString("Status code:", comment: "Body for Unknown error")) \(httpResponse.statusCode)")))
                return
            }
        }
        
        task.resume()
    }
    
//    /// Restore notes from backend
//    /// - Parameter for: user
//    /// - Parameter completion: completion for using fetched notes
//    /// - Parameter inContext: CoreData context
//    /// - Description: Make request to backend and return last snapshot
//    static func restoreNotes(for user: User, inContext context: NSManagedObjectContext completion: @escaping (AnotesResult) -> Void) {
//        guard let url = self.anotesUrl(endpoint: .restore) else {
//            return
//        }
//
//        var request = URLRequest(url: url)
//        request.httpMethod = RequestType.GET.rawValue
//        request.addValue(user.authToken, forHTTPHeaderField: "Authorization")
//        let task = self.session.dataTask(with: request) {
//            (data, response, error) in
//
//            guard let httpResponse = response as? HTTPURLResponse else {
//                completion(.Failure(AnotesError.BadResponse))
//                return
//            }
//
//            switch httpResponse.statusCode {
//            case 200...299:
//                let fetchResult = self.notesFrom(data: data, inContext: context)
//                completion(fetchResult)
//                return
//            case 403:
//                print("Status code: \(httpResponse.statusCode). Token expired? Try to refresh it!")
//                self.authenticate(username: user.username, password: user.password) {
//                    (result) in
//                    switch result {
//                    case let .AuthSuccess(token):
//                        print("Authentication succesful!")
//                        user.authToken = token
//                        self.restoreNotes(for: user, completion: completion)
//                    default:
//                        completion(.Failure(AnotesError.AuthError))
//                    }
//                }
//                return
//            case 404:
//                completion(.Failure(AnotesError.NetworkError("")))
//                return
//            default:
//                completion(.Failure(AnotesError.UnknownError("\(NSLocalizedString("Status code:", comment: "Body for Unknown error")) \(httpResponse.statusCode)")))
//                return
//            }
//        }
//
//        task.resume()
//    }
    
    /// Backing up notes to backend
    /// - Parameter for: authenticated user
    /// - Parameter with: array of notes which needs backup
    /// - Parameter completion: completion for using result
    static func backupNotes(for user: User, with notes: [Note], completion: @escaping (AnotesResult) -> Void) {        
        guard let url = self.anotesUrl(endpoint: .backup) else {
            return
        }
        
        var request = URLRequest(url: url)
        request.addValue("Application/json", forHTTPHeaderField: "Content-Type")
        request.addValue(user.authToken, forHTTPHeaderField: "Authorization")
        let notesDict = self.jsonFromNotes(notes: notes)
        print("\(notesDict)")
        guard let jsonBody = try? JSONSerialization.data(withJSONObject: notesDict, options: []) else {
            completion(.Failure(AnotesError.InvalidJSONFormat))
            return
        }
        
        request.httpMethod = RequestType.POST.rawValue
        request.httpBody = jsonBody
        let task = self.session.dataTask(with: request) {
            (data, response, error) in
            
            guard let httpResponse = response as? HTTPURLResponse else {
                completion(.Failure(AnotesError.BadResponse))
                return
            }
            
            switch httpResponse.statusCode {
            case 200...299:
                completion(.BackupSuccess)
                return
            case 403:
                print("Status code: \(httpResponse.statusCode). Token expired? Try to refresh it!")
                self.authenticate(username: user.username, password: user.password) {
                    (result) in
                    switch result {
                    case let .AuthSuccess(newToken):
                        print("Authentication successful!")
                        user.authToken = newToken
                        self.backupNotes(for: user, with: notes, completion: completion)
                    default:
                        completion(.Failure(AnotesError.AuthError))
                    }
                }
            case 404:
                print("Code: \(httpResponse.statusCode)")
                completion(.Failure(AnotesError.NetworkError("")))
                return
            default:
                let errorMessage = "\(NSLocalizedString("Status code:", comment: "Body for Unknown error")) \(httpResponse.statusCode)"
                print(errorMessage)
                completion(.Failure(AnotesError.UnknownError(errorMessage)))
                return
            }
        }
        
        task.resume()
    }
    
    /// Make JSON from Note instance
    /// - Parameter note: note for transforming to json
    private static func jsonFromNote(note: Note) -> [String:AnyObject] {
        var noteDict =
            ["title":note.title,
             "text":note.text,
             "pinned":String(note.pinned),
             "creationDate":dateFormatter.string(from: note.creationDate),
             "editDate":dateFormatter.string(from: note.editDate)]
        
        if let reminderDate = note.reminderDate {
            noteDict["reminderDate"] = dateFormatter.string(from: reminderDate)
        }
        
        return noteDict as [String:AnyObject]
    }
    
    private static func jsonFromNotes(notes: [Note]) -> [String:AnyObject] {
        let notesDict = notes.map{self.jsonFromNote(note: $0)}
        return ["notes": notesDict] as [String:AnyObject]
    }
    
    /// Extract note instances from json data representation
    /// - Parameter data: JSONised data with notes
    /// - Parameter inContext: CoreData context
    static func notesFrom(data: Data?, inContext context: NSManagedObjectContext) -> AnotesResult {
        guard let jsonData = data else {
            return .Failure(AnotesError.EmptyJSONData)
        }
        
        do {
            let jsonObject: Any = try JSONSerialization.jsonObject(with: jsonData, options: [])
            
            guard
                let jsonDict = jsonObject as? [String:AnyObject],
                let notes = jsonDict["notes"] as? [AnyObject],
                let notesArray = notes as? [[String:AnyObject]] else {
                return .Failure(AnotesError.InvalidJSONFormat)
            }
                        
            var resultNotes = [Note]()
            for note in notesArray {
                if let note = self.noteFromJSON(object: note, inContext: context) {
                    resultNotes.append(note)
                }
            }
            
            print(resultNotes)
            
            return .RestoreSuccess(resultNotes)
        }
        catch let error {
            return .Failure(error)
        }
    }
}
