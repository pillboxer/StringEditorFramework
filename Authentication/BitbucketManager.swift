//
//  BitbucketAuthenticator.swift
//  StringChanger
//
//  Created by Henry Cooper on 16/02/2020.
//  Copyright © 2020 Henry Cooper. All rights reserved.
//

import Foundation
import KeychainAccess

public enum LoginError: Error {
    case badCredentials
    case keychainError
    case requestError(RequestError)
    
    public var localizedDescription: String {
        switch self {
        case .badCredentials:
            return RequestError.badCredentials.localizedDescription
        case .keychainError:
            return "Could not save to keychain"
        case .requestError(let error):
            return error.localizedDescription
        }
    }
}

public enum StringEditError: Error {
    case requestError(RequestError)
    case noStringsExist
    case keyAlreadyExists(String)
    
    public var localizedDescription: String {
        switch self {
        case .requestError(let error):
            return error.localizedDescription
        case .noStringsExist:
            return "Request returned no strings"
        case .keyAlreadyExists(let key):
            return "\"\(key)\" already exists in the json"
        }
    }
    
}

public enum LoadingState {
    case fetching
    case pulling
    case pushing
    case complete
    case error(RequestError)
}

public enum Platform: String {
    case ios
    case android
    
    func platformPath(withHash hash: String) -> String {
        switch self {
        case .ios:
            return "src/\(hash)\(fileLocation)"
        case .android:
            return "src/\(hash)\(fileLocation)"
        }
    }
    
    var fileLocation: String {
        switch self {
        case .ios:
            return "/ios/strings/V1/ios-strings-base.json"
        default:
            return "/android/strings/strings.json"
        }
    }
}

public protocol BitbucketManagerDelegate: class {
    func bitbucketManagerLoadingStateDidChange(_ newState: LoadingState)
}

public class BitbucketManager {
    
    public static let shared = BitbucketManager()
    
    // MARK: - Private Properites
    private var hash: String?
    // MARK: - Exposed Properties
    var platform: Platform = UserDefaults.selectedPlatform
    
    public var latestStrings: StringsFile?
    public var latestMessage: String?
    
    public weak var delegate: BitbucketManagerDelegate?
    
    // MARK: - Exposed Methods
    public func load(completion: @escaping (RequestError?) -> Void) {
        guard let _ = KeychainManager.shared.credentials else {
            return completion(.noCredentials)
        }
        getLatestCommit { (error, commit) in
            if let error = error {
                switch error {
                case .badCredentials:
                    KeychainManager.shared.deleteCredentials()
                    self.delegate?.bitbucketManagerLoadingStateDidChange(.error(.badCredentials))
                    return completion(error)
                default:
                    return completion(error)
                }
            }
            self.hash = commit?.hash
            self.latestMessage = commit?.commitMessage
            
            self.getLatestStrings { (error) in
                if let error = error {
                    return completion(error)
                }
                self.delegate?.bitbucketManagerLoadingStateDidChange(.complete)
                return completion(nil)
            }
        }
    }
    
    public func addToStrings(keysAndValues: [KeyAndValue], editedStrings: [String : KeyAndValue]?, completion: @escaping (StringEditError?) -> Void) {
        load { (error) in
            if let error = error {
                return completion(.requestError(error))
            }
            guard let strings = self.latestStrings else {
                return completion(.noStringsExist)
            }
            
            let endpoint = Endpoint.src
            var request = URLRequest(endpoint: endpoint)
            if let string = strings.addKeysAndValues(keysAndValues) {
                return completion(.keyAlreadyExists(string))
            }
            if let editedStrings = editedStrings {
                strings.editKeysAndValues(fromDict: editedStrings)
            }
            
            self.delegate?.bitbucketManagerLoadingStateDidChange(.pushing)
            request.postWithData(data: strings.dataReadyForFormRequest(formKey: endpoint.formKey)) { (error) in
                if let error = error {
                    return completion(.requestError(error))
                }
                completion(nil)
            }
        }
    }
    
    public func changePlatformTo(_ newPlatform: Platform, completion: @escaping (RequestError?) -> Void) {
        platform = newPlatform
        UserDefaults.storePlatform(newPlatform)
        getLatestStrings { (error) in
            if let error = error {
                return completion(error)
            }
            completion(nil)
        }
    }
    
    public func storeCredentials(username: String, password: String) -> Bool {
        guard KeychainManager.shared.storeCredentials(username: username, password: password) else {
            return false
        }
        return true
    }
    
    public func checkCredentials(username: String, password: String, completion: @escaping (LoginError?) -> Void) {
        // Store in Keychain
        guard KeychainManager.shared.storeCredentials(username: username, password: password) else {
            return completion(.keychainError)
        }
        load { (error) in
            if let error = error {
                KeychainManager.shared.deleteCredentials()
                switch error {
                case .badCredentials, .noCredentials:
                    return completion(.badCredentials)
                default:
                    return completion(.requestError(error))
                }
            }
            else {
                return completion(nil)
            }
        }
    }
    
    // MARK: - Private Methods
    private func getLatestStrings(completion: @escaping (RequestError?) -> Void) {
        delegate?.bitbucketManagerLoadingStateDidChange(.pulling)
        guard let hash = hash else {
            return
        }
        let endpoint = Endpoint.strings(hash)
        let request = URLRequest(endpoint: endpoint)
        request.getDecodable(decoding: StringsFile.self) { (error, stringsFile) in
            if let error = error {
                return completion(error)
            }
            self.latestStrings = stringsFile
            completion(nil)
        }
    }
    
    private func getLatestCommit(completion: @escaping (RequestError?, RepositoryCommit?) -> Void) {
        delegate?.bitbucketManagerLoadingStateDidChange(.fetching)
        let endpoint = Endpoint.commits
        let request = URLRequest(endpoint: endpoint)
        starPrint(request)
        
        request.getDecodable(decoding: RepositoryCommitSource.self) { (error, commitJSON) in
            if let error = error {
                return completion(error, nil)
            }
            else {
                let latest = commitJSON?.values?.first
                completion(nil, latest)
            }
        }
    }
    
    
}
