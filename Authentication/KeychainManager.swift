//
//  KeychainManager.swift
//  StringEditorFramework
//
//  Created by Henry Cooper on 05/03/2020.
//  Copyright © 2020 Henry Cooper. All rights reserved.
//

import Foundation
import KeychainAccess

class KeychainManager {
    
    // MARK: - Private Properties
    private var serviceName = "com.SixEye.strings"
    
    // MARK: - Exposed Properties
    static let shared = KeychainManager()
    
    enum KeychainDataType: String {
        case credentials
    }
    
    var credentials: String? {
        let keychain = Keychain(service: serviceName)
        return keychain[KeychainDataType.credentials.rawValue]
    }
    
    // MARK: - Exposed Methods
    func storeCredentials(username: String, password: String) -> Bool {
        let keychain = Keychain(service: serviceName)
        guard let encoded = String.formattedForBasicAuthorization(username: username, password: password) else {
            return false
        }
        keychain[KeychainDataType.credentials.rawValue] = encoded
        return true
    }
    
    func deleteCredentials() {
        let keychain = Keychain(service: serviceName)
        do {
            try keychain.remove(KeychainDataType.credentials.rawValue)
        }
        catch let error {
            print(error)
        }
    }
    
}
