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
}
