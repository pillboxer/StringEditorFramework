//
//  NSObject+Extensions.swift
//  StringEditorFramework
//
//  Created by Henry Cooper on 05/03/2020.
//  Copyright © 2020 Henry Cooper. All rights reserved.
//

import Foundation

public extension NSObject {
    
    var classNibName: String {
        let classNameNeedingSplit = NSStringFromClass(type(of: self))
        return String(classNameNeedingSplit.split(separator: ".")[1])
    }
}
