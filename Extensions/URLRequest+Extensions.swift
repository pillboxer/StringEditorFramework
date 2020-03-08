//
//  URLRequest+Extensions.swift
//  StringChanger
//
//  Created by Henry Cooper on 16/02/2020.
//  Copyright © 2020 Henry Cooper. All rights reserved.
//

import Foundation

typealias Parameters = [String:Any]

public enum RequestError: Error {
    case badResponseCode(Int)
    case couldNotDecode(String)
    case noResponse
    case dataTaskError(String)
    case badCredentials
    case noCredentials
    
    public var localizedDescription: String {
        switch self {
        case .badResponseCode(let code):
            return "Received response code: \(code)"
        case .couldNotDecode(let description):
            return "Could not decode: \(description)"
        case .noResponse:
            return "No response"
        case .dataTaskError(let description):
            return "Request error: \(description)"
        case .badCredentials:
            return "Incorrect username or password"
        case .noCredentials:
            return "User has no credentials stored"
        }
    }
}

enum ContentType: String {
    case formUrlEncoded = "application/x-www-form-urlencoded"
}

extension URLRequest {
    
    init(endpoint: Endpoint) {
        self.init(url: endpoint.url)
        addHeader(endpoint.header)
    }
    
    func getDecodable<Decoding: Decodable>(decoding: Decoding.Type, completion: @escaping (_ error: RequestError?, _ decoding: Decoding?) -> Void) {
        let config = URLSessionConfiguration.default
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        let session = URLSession(configuration: config)
        session.dataTask(with: self) { (data, response, error) in
            var decodedJSON: Decoding?
            if let error = error {
                return completion(.dataTaskError(error.localizedDescription), nil)
            }
            else if let response = response as? HTTPURLResponse {
                if response.isBadCredentialResponse {
                    return completion(.badCredentials, nil)
                }
                if !response.isSuccess {
                    return completion(.badResponseCode(response.statusCode), nil)
                }
            }
            if let data = data {
                do {
                    decodedJSON = try JSONDecoder().decode(decoding.self, from: data)
                    return completion(nil, decodedJSON)
                }
                catch let error {
                    return completion(.couldNotDecode(error.localizedDescription), nil)
                }
            }
            else {
                return completion(.noResponse, nil)
            }
        }.resume()
    }
    
    mutating func postWithData(data: Data?, completion: @escaping (_ success: RequestError?) -> Void) {
        let config = URLSessionConfiguration.default
        config.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        let session = URLSession(configuration: config)
        httpMethod = "POST"
        httpBody = data
        setContentType(.formUrlEncoded)
        session.uploadTask(with: self, from: data) { (data, response, error) in
            if let error = error {
                return completion(.dataTaskError(error.localizedDescription))
            }
            else if let response = response as? HTTPURLResponse {
                if response.isBadCredentialResponse {
                    return completion(.badCredentials)
                }
                if !response.isSuccess {
                    return completion(.badResponseCode(response.statusCode))
                }
            }
            completion(nil)
        }.resume()
    }
    
    mutating func addHeader(_ header: Header) {
        switch header {
        case .authorization(let encodedString):
            setValue("Basic \(encodedString)", forHTTPHeaderField: "Authorization")
        }
    }
    
    mutating func setContentType(_ contentType: ContentType) {
        setValue(contentType.rawValue, forHTTPHeaderField: "Content-Type")
    }
    
}

extension HTTPURLResponse {
    
    var isBadCredentialResponse: Bool {
        return statusCode == 401
    }
    
    var isSuccess: Bool {
        return statusCode >= 200 && statusCode < 300
    }
    
}
