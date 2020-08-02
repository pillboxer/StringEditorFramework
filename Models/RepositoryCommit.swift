//
//  RepositoryCommit.swift
//  StringChanger
//
//  Created by Henry Cooper on 22/02/2020.
//  Copyright © 2020 Henry Cooper. All rights reserved.
//

import Foundation

public struct KeyAndValue: Equatable {
    
    public let key: String
    public let value: String
    public var language: Language?
    
    public init(key: String, value: String, language: Language? = nil) {
        self.key = key
        self.value = value
        self.language = language
    }
    
    public enum Language: String, CaseIterable {
        case en
        case gb = "en-GB"
        case us = "en-US"
        case de
        case fr
        
        public init?(title: String) {
            for language in Language.allCases {
                if title.lowercased() == language.rawValue.lowercased() {
                    self = language
                    return
                }
            }
            return nil
        }
    }
    
    static func contentVersion(value: String) -> KeyAndValue {
        return KeyAndValue(key: "content_version", value: value)
    }
    
    static func separatorWithLanguage(language: Language?) -> KeyAndValue? {
        guard let language = language else {
            return nil
        }
        return KeyAndValue(key: language.rawValue.uppercased(), value: "", language: language)
    }
    
    public var isSeparator: Bool {
        guard let language = language else {
            return false
        }
        return language.rawValue.uppercased() == key
    }
}

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

public protocol StringsFile: Codable {
    var displayTuples: [KeyAndValue] { get }
    func editKeysAndValues(fromDict dict: [String : KeyAndValue])
    func dataReadyForFormRequest(formKey: String, commitMessage: String) -> Data?
    func addKeysAndValues(_ keysAndValues: [KeyAndValue]) -> String?
    func keyAlreadyExists(_ key: String, inDict dict: [String: String]) -> Bool
}

public extension StringsFile {
    
    func dataReadyForFormRequest(formKey: String, commitMessage: String) -> Data? {
        let encoder = JSONEncoder()
        if #available(OSX 10.15, *) {
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        } else {
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        }
        var data: Data?
        do {
            let encoded = try encoder.encode(self)
            if let prettyString = String(data: encoded, encoding: .utf8),
                let percentEncoded = prettyString.addingPercentEncoding(withAllowedCharacters: .alphanumerics) {
                let formatted = "\(formKey)=\(percentEncoded)&message=\(commitMessage)&branch=\(Environment.branchName)"
                data = formatted.data(using: .utf8)
            }
            return data
        }
        catch let error {
            print(error.localizedDescription)
            return nil
        }
    }
    
    func keyAlreadyExists(_ key: String, inDict dict: [String : String]) -> Bool {
        return dict.containsKey(key)
    }
    
}

class AndroidStringsFile: StringsFile {

    func addKeysAndValues(_ keysAndValues: [KeyAndValue]) -> String? {
        for keyAndValue in keysAndValues {
            
            guard let language = keyAndValue.language,
                let correctTranslationDict = dictForLanguage(language) else {
                return "Missing a language or the dictionary does not exist"
            }
            
            let key = keyAndValue.key
            let value = keyAndValue.value
            if !keyAlreadyExists(keyAndValue.key, inDict: correctTranslationDict.map) {
                correctTranslationDict.map[key] = value
            }
            else {
                return key
            }
        }
        return nil
    }
    
    func editKeysAndValues(fromDict dict: [String : KeyAndValue]) {
        for edit in dict {
            if edit.key == "content_version" {
                let currentContentVersion = contentVersion
                contentVersion = Int(edit.value.value) ?? currentContentVersion
                continue
            }
            
            guard let language = edit.value.language, let correctTranslationDict = dictForLanguage(language) else {
                print("Error: edit missing language!")
                continue
            }
            
            let oldKey = edit.key
            let newKey = edit.value.key
            let newValue = edit.value.value
            correctTranslationDict.map.removeValue(forKey: oldKey)
            correctTranslationDict.map[newKey] = newValue
        }
        return
    }
    
    
    var contentVersion: Int
    var translationDictionaries: [TranslationDictionary]
    
    enum CodingKeys: String, CodingKey {
        case contentVersion = "content_version"
        case translationDictionaries = "translation_dictionaries"
    }
    
    class TranslationDictionary: Codable {
        let lang: String
        var map: [String: String]
    }
    
    var displayTuples: [KeyAndValue] {
        var tuples = [KeyAndValue]()
        
        let contentVersionKeyAndValue = KeyAndValue.contentVersion(value: "\(contentVersion)")
        tuples.append(contentVersionKeyAndValue)
        
        for translationDictionary in translationDictionaries {
            let sorted = translationDictionary.map.sorted() { $0.key < $1.key }
            let language = KeyAndValue.Language(rawValue: translationDictionary.lang)
            let dictAsKeysAndValues = sorted.map() { KeyAndValue(key: $0.key, value: $0.value, language: language) }

            if let separator = KeyAndValue.separatorWithLanguage(language: language) {
                tuples.append(separator)
            }
            tuples.append(contentsOf: dictAsKeysAndValues)
        }
        return tuples
    }
    
    private func dictForLanguage(_ language: KeyAndValue.Language) -> TranslationDictionary? {
        return (translationDictionaries.filter() { $0.lang == language.rawValue }).first
    }
    
}


class IosStringsFile: StringsFile {
    
    // MARK: - Private Properties
    private var language: String?
    private var strings: [String: String]
    
    var displayTuples: [KeyAndValue] {
        starPrint(strings.count)
        let sortedKeysAndValues = strings.sorted() { $0.key < $1.key }
        let keysAndValues = sortedKeysAndValues.map() { KeyAndValue(key: $0.key, value: $0.value) }
        return keysAndValues
    }
    
    // MARK: - Private Methods
    private func contains(key: String) -> Bool {
        return strings.containsKey(key)
    }
    
    @discardableResult private func add(key: String, value: String) -> Bool {
        guard !contains(key: key) else {
            return false
        }
        strings[key] = value
        return true
    }
    
    // MARK: - Exposed Methods
    func editKeysAndValues(fromDict dict: [String : KeyAndValue]) {
        for edit in dict {
            let oldKey = edit.key
            let newKey = edit.value.key
            let newValue = edit.value.value
            strings.removeValue(forKey: oldKey)
            strings[newKey] = newValue
        }
    }
    
    @discardableResult func addKeysAndValues(_ keysAndValues: [KeyAndValue]) -> String? {
        for keyAndValue in keysAndValues {
            if !add(key: keyAndValue.key, value: keyAndValue.value) {
                return keyAndValue.key
            }
        }
        return nil
    }
}

extension Dictionary where Key == String {
    
    func containsKey(_ key: String) -> Bool {
        return contains() { $0.key.trimmingCharacters(in: .whitespaces) == key }
    }
    
}
