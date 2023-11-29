//
//  Variable.swift
//  Fumes
//
//  Created by Christopher Ladd on 2/6/20.
//  Copyright © 2020 Better Notes, LLC. All rights reserved.
//

import Foundation

enum Visibility {
    case _public, _private
}

protocol Variable {
    var visibility: Visibility { get set }
    var groupName: String { get }
    var typeName: String { get }
    func variableName() -> String
    func variableKeyword() -> String
    func variableValue() -> String
}

extension Variable {
    func variableKeyword() -> String {
        if visibility == ._private {
            return "let"
        }
        
        return "public var"
    }
    
    func variableName(suffix: String, typeName: String? = nil) -> String {
        let trimmed = groupName.trimmingCharacters(in: CharacterSet(charactersIn: "_"))
        let firstWord = trimmed.prefix(1).lowercased() + trimmed.dropFirst()
        
        var result = safeVariableName(with: firstWord) + suffix
        
        if let typeName = typeName {
            result += ": \(typeName)"
        }
        
        return result
    }
    
    func safeVariableName(with name: String) -> String {
        return name.replacingOccurrences(of: " ", with: "")
    }
}
