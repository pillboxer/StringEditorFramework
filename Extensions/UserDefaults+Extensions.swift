//
//  UserDefaults+Extensions.swift
//  StringEditorFramework
//
//  Created by Henry Cooper on 08/03/2020.
//  Copyright © 2020 Henry Cooper. All rights reserved.
//

import Foundation

public extension UserDefaults {
    
    static var selectedPlatform: Platform {
        let rawValue = standard.string(forKey: "SelectedPlatform") ?? ""
        let platform = Platform(rawValue: rawValue) ?? .ios
        return platform
    }
    
    static func storePlatform(_ platform: Platform) {
        standard.set(platform.rawValue, forKey: "SelectedPlatform")
    }
    
}
