//
//  Environment.swift
//  StringEditorFramework
//
//  Created by Henry Cooper on 29/03/2020.
//  Copyright © 2020 Henry Cooper. All rights reserved.
//

import Foundation

public class Environment {
    
    public static var isDev: Bool {
        #if DEV
            return true
        #else
            return false
        #endif
    }
    
}
