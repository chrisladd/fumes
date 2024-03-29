//
//  ColorVariable.swift
//  Fumes
//
//  Created by Christopher Ladd on 2/6/20.
//  Copyright © 2020 Better Notes, LLC. All rights reserved.
//

import Foundation

struct ColorVariable: Variable {
    var visibility: Visibility
    
    enum ColorType {
        case stroke, fill, text
    }
    
    let groupName: String
    let color: String
    let type: ColorType
    let typeName: String = "UIColor"
    
    init(groupName: String, color: String, type: ColorType) {
        self.groupName = groupName
        self.color = color
        self.type = type
        
        if groupName.starts(with: "_") {
            visibility = ._private
        }
        else {
            visibility = ._public
        }
    }

    func variableValue() -> String {
        return color
    }
    
    func variableName() -> String {
        let trimmed = groupName.trimmingCharacters(in: CharacterSet(charactersIn: "_"))
        let firstWord = trimmed.prefix(1).lowercased() + trimmed.dropFirst()
        
        if type == .text {
            return safeVariableName(with: firstWord) + "TextColor"
        }
        else if type == .stroke {
            return safeVariableName(with: firstWord) + "StrokeColor"
        }
        else {
            return safeVariableName(with: firstWord) + "FillColor"
        }
    }
}
