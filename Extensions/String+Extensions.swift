//
//  String+Extensions.swift
//  StringEditorFramework
//
//  Created by Henry Cooper on 05/03/2020.
//  Copyright © 2020 Henry Cooper. All rights reserved.
//

import Foundation

extension String {
    
    // MARK: - Private Properties
    private var base64Encoded: String? {
        guard let data = data(using: .utf8) else {
            return nil
        }
        return data.base64EncodedString()
    }
    
    // MARK: - Exposed Methods
    public static func formattedForBasicAuthorization(username: String, password: String) -> String? {
        return "\(username):\(password)".base64Encoded
    }
    
}
