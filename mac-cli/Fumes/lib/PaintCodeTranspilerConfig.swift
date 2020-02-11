//
//  PaintCodeTranspilerConfig.swift
//  Fumes
//
//  Created by Christopher Ladd on 2/6/20.
//  Copyright © 2020 Better Notes, LLC. All rights reserved.
//

import Foundation

public enum PaintCodeSourceLanguage {
    case swift, objc
}

public struct PaintCodeTranspilerConfig {
    /**
     The class name
     */
    public var className = "UIView"
    
    /**
     The language of the source code.
     
     Currently, only .swift is supported
     */
    public var language: PaintCodeSourceLanguage = .swift
    
    /**
     An initializer for a background color
     */
    public var bg: String?
}
