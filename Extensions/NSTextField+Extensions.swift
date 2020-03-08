//
//  NSTextField+Extensions.swift
//  StringEditorFramework
//
//  Created by Henry Cooper on 08/03/2020.
//  Copyright © 2020 Henry Cooper. All rights reserved.
//

import Cocoa

public extension NSTextField {
    
    var isKeyTextField: Bool {
        guard let cell = superview as? NSTableCellView else {
            return false
        }
        return cell.identifier == NSUserInterfaceItemIdentifier("KeyView")
    }
    
}
