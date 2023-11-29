//
//  FrameVariable.swift
//  Fumes
//
//  Created by Christopher Ladd on 11/29/23.
//  Copyright © 2023 Better Notes, LLC. All rights reserved.
//

import Foundation

struct FrameVariable: Variable {
    var visibility: Visibility
    
    var groupName: String
    
    /// the name of the variable used in code by the group
    var groupVariableName: String
    
    enum FrameType {
        case text
        case bezierPath
    }
    
    var type: FrameType
    
    let typeName: String = "CGRect"
    
    init(visibility: Visibility, groupName: String, type: FrameType) {
        self.visibility = visibility
        self.groupName = groupName
        self.groupVariableName = groupName.prefix(1).lowercased() + groupName.dropFirst()
        self.type = type
    }
    
    func variableName() -> String {
        return "\(variableName(suffix: "Frame"))"
    }
    
    func variableValue() -> String {
        return ".zero"
    }
}
