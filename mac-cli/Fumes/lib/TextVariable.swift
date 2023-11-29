//
//  TextVariable.swift
//  Fumes
//
//  Created by Christopher Ladd on 2/6/20.
//  Copyright © 2020 Better Notes, LLC. All rights reserved.
//

import Foundation

struct TextVariable: Variable {
    var visibility: Visibility
    let groupName: String
    let text: String
    let typeName: String = "String"
    
    func variableValue() -> String {
        return "\"" + text + "\""
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
        return variableName(suffix: "Text")
    }
    
    func attributedVariableName() -> String {
        return variableName(suffix: "AttributedText")
    }
}
