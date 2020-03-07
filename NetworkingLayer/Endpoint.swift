//
//  Endpoint.swift
//  StringChanger
//
//  Created by Henry Cooper on 22/02/2020.
//  Copyright © 2020 Henry Cooper. All rights reserved.
//

import Foundation
import Cocoa

enum Endpoint: EndpointType {
    
    case commits
    case strings(String)
    case src
    
    var resource: EndpointResource {
        switch self {
        case .commits:
            return .commits
        case .strings(let hash):
            return .strings(hash)
        case .src:
            return .src
        }
    }
    
    var formKey: String {
        let currentPlatform = BitbucketManager.shared.platform
        return currentPlatform.fileLocation
    }

    var url: URL {
        return baseURL.appendingPathComponent(resource.path)
    }
}
