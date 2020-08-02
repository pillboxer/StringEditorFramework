//
//  Environment.swift
//  StringEditorFramework
//
//  Created by Henry Cooper on 29/03/2020.
//  Copyright © 2020 Henry Cooper. All rights reserved.
//

import Foundation

public class Environment {
    
    public static var isDev = true
    
    public static func setEnvironment(_ bool: Bool) {
        isDev = bool
    }
    
    public static var branchName: String {
        return isDev ? "develop" : "master"
    }
}
