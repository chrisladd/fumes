//
//  FontVariable.swift
//  Fumes
//
//  Created by Christopher Ladd on 2/6/20.
//  Copyright © 2020 Better Notes, LLC. All rights reserved.
//

import Foundation


struct FontVariable: Variable {
    var visibility: Visibility
    let groupName: String
    let text: String

    func variableValue() -> String {
        return text
    }
    
    init(groupName: String, text: String) {
        self.groupName = groupName
        self.text = text
        
        if groupName.starts(with: "_") {
            visibility = ._private
        }
        else {
            visibility = ._public
        }
    }
    
    func variableName() -> String {
        let trimmed = groupName.trimmingCharacters(in: CharacterSet(charactersIn: "_"))
        let firstWord = trimmed.prefix(1).lowercased() + trimmed.dropFirst()
        
        return firstWord + "Font"
    }
}
