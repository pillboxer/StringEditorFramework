//
//  EndpointType.swift
//  StringChanger
//
//  Created by Henry Cooper on 22/02/2020.
//  Copyright © 2020 Henry Cooper. All rights reserved.
//

import Foundation

enum Header {
    case authorization(String)
    
    static func authorizationHeader() -> Header {
        guard let credentials = KeychainManager.shared.credentials else {
            return .authorization("")
        }
        return .authorization(credentials)
    }
}

enum EndpointResource {
    case commits
    case strings(String)
    case src
    
    var path: String {
        switch self {
        case .commits:
            return "commits"
        case .strings(let hash):
            let currentPlatform = BitbucketManager.shared.platform
            return currentPlatform.platformPath(withHash: hash)
        case .src:
            return "src"
        }
    }
    
}

protocol EndpointType {
    var baseURL: URL { get }
    var resource: EndpointResource { get }
    var url: URL { get }
}

extension EndpointType {
    
    var baseURL: URL {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "api.bitbucket.org"
        components.path = path
        return components.url!
    }
    
    var header: Header {
        return Header.authorizationHeader()
    }
    
    private var path: String {
        return Environment.isDev ? "/2.0/repositories/pillboxer/henry-test-repo" : "/2.0/repositories/touchnote-team/mobile-cms"
    }
    
}
