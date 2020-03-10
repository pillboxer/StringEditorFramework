//
//  RepositoryCommit.swift
//  StringChanger
//
//  Created by Henry Cooper on 22/02/2020.
//  Copyright © 2020 Henry Cooper. All rights reserved.
//

import Foundation

public typealias KeyAndValue = (key: String, value: String)


struct RepositoryCommitSource: Decodable {
    
    let values: [RepositoryCommit]?
    
}

struct RepositoryCommit: Decodable {
    
    let hash: String
    let rendered: RepositoryRendered
    
    var commitMessage: String {
        return rendered.message.raw
    }
    
}

struct RepositoryRendered: Decodable {
    
    let message: RepositoryMessage
    
    struct RepositoryMessage: Decodable {
        let raw: String
    }
    
}



public class StringsFile: Codable {
    
    var language: String?
    var contentVersion: String?
    
    public var strings: [String: String]
    
    public var displayTuples: [KeyAndValue] {
        return strings.sorted() { $0.key < $1.key }
    }
    
    func contains(key: String) -> Bool {
        return strings.contains() { $0.key.trimmingCharacters(in: .whitespaces) == key }
    }
    
    @discardableResult public func addKeysAndValues(_ keysAndValues: [KeyAndValue]) -> String? {
        for keyAndValue in keysAndValues {
            if !add(key: keyAndValue.key, value: keyAndValue.value) {
                return keyAndValue.key
            }
        }
        return nil
    }
    
    func editKeysAndValues(fromDict dict: [String : KeyAndValue]) {
        for edit in dict {
            let oldKey = edit.key
            let newKey = edit.value.key
            let newValue = edit.value.value
            strings.removeValue(forKey: oldKey)
            strings[newKey] = newValue
        }
    }
    
    @discardableResult func add(key: String, value: String) -> Bool {
        guard !contains(key: key) else {
            return false
        }
        strings[key] = value
        return true
    }
    
    func dataReadyForFormRequest(formKey: String, commitMessage: String) -> Data? {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        var data: Data?
        do {
            let encoded = try encoder.encode(self)
            if let prettyString = String(data: encoded, encoding: .utf8),
                let percentEncoded = prettyString.addingPercentEncoding(withAllowedCharacters: .alphanumerics) {
                let formatted = "\(formKey)=\(percentEncoded)&message=\(commitMessage)"
                data = formatted.data(using: .utf8)
            }
            return data
        }
        catch let error {
            print(error.localizedDescription)
            return nil
        }
    }
}
