//
//  PaintCodeTranspiler.swift
//  Fumes
//
//  Created by Christopher Ladd on 2/6/20.
//  Copyright © 2020 Better Notes, LLC. All rights reserved.
//

import Foundation


public struct PaintCodeTranspiler {
    
    // MARK: - Public
    
    public func transpile(_ sourceCode: String, config: PaintCodeTranspilerConfig? = nil) -> String? {
        let internalConfig: PaintCodeTranspilerConfig;
        if let config = config {
            internalConfig = config
        }
        else {
            internalConfig = PaintCodeTranspilerConfig()
        }

        guard internalConfig.language == .swift else {
            print("Error: unsupported source type")
            return nil
        }
        
        var source = sourceCode;
        
        if let className = classNameFrom(source) {
            source = removeClassFunctionsFrom(source, className: className)
        }
        
        source = source.replacingOccurrences(of: ": NSObject {", with: ": \(internalConfig.className) {")
        
        source = insertInitializersIn(source: source, bgColor: config?.bg)
        
        let colorResult = replaceColorVariables(source)
        source = insertVariables(source: colorResult.source, variables: colorResult.color)
        
        let textResult = replaceTextVariables(source)
        source = insertVariables(source: textResult.source, variables: textResult.variables)
        
        let fontResult = replaceFontVariables(source)
        source = insertVariables(source: fontResult.source, variables: fontResult.variables)
        
        source = insertDrawRectIn(source: source)
        
        return source
    }
    
    
    // MARK: UIView
    
    func removeClassFunctionsFrom(_ source: String, className: String) -> String {
        var result = source.replacingOccurrences(of: "class func", with: "func")
        result = result.replacingOccurrences(of: className + ".", with: "")
        
        return result
    }
    
    func classNameFrom(_ source: String) -> String? {
        // class CircleSquare: NSObject
        
        guard let regex = try? NSRegularExpression(pattern: #"class (?<className>[\w]+): NSObject"#, options: []) else { return nil }
        
        guard let match = regex.firstMatch(in: source, options: [], range: NSRange(source.startIndex..<source.endIndex, in: source)) else { return nil }
        
        let range = match.range(withName: "className")
        if range.location != NSNotFound, let substringRange = Range(range, in:source) {
            return String(source[substringRange])
        }
        
        return nil
    }
    
    func insertInitializersIn(source: String, bgColor: String?) -> String {
        let bg = bgColor ?? ".clear"
        let initializers = """
            func commonInit() {
                backgroundColor = \(bg)
            }
            
            override init(frame: CGRect) {
                super.init(frame: frame)
                commonInit()
            }
            
            required init?(coder: NSCoder) {
                super.init(coder: coder)
                commonInit()
            }
        """
        
        var updatedLines = [String]()
        source.enumerateLines { (line, stop) in

            if line.starts(with: "class ") {
                updatedLines.append(initializers)
            }
            
            updatedLines.append(line)
        }
        
        return updatedLines.joined(separator: "\n")
    }
    
    // MARK: Drawing
        
    func insertDrawRectIn(source: String) -> String {
        var updatedLines = [String]()
        source.enumerateLines { (line, stop) in
            if let functionName = self.boundedValueFromString(line, left: "func draw", right: "(frame targetFrame: ") {
                if let rectValue = self.boundedValueFromString(line, left: "targetFrame: CGRect = ", right: ", resizing") {
                    
                    let drawRectCall = """
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        draw\(functionName)(frame: rect)
    }
    
    override func sizeThatFits(_ size: CGSize) -> CGSize {
        // scale the size to the given width
         let nativeRect = \(rectValue)
         let aspect = size.width / nativeRect.width
         let height = nativeRect.height * aspect
    
         return CGSize(width: size.width, height: height)
    }

                    
"""

                    updatedLines.append(drawRectCall)
                }
            }
            
            updatedLines.append(line)
        }
        
        return updatedLines.joined(separator: "\n")
    }

    
    // MARK: Groups
    
    func nameForGroupIn(source: String, before range: Range<String.Index>) -> String? {
        var groupName: String?
        
        source.enumerateSubstrings(in: source.startIndex..<range.lowerBound, options: [.byLines, .reverse]) { (line, enclosingRange, range, stop) in
            if let line = line {
                if line.contains(#"/// "#) {
                    groupName = line.replacingOccurrences(of: #"/// "#, with: "").trimmingCharacters(in: .whitespacesAndNewlines)
                    stop = true
                }
            }
        }
        
        return groupName
    }
    
    // MARK: Colors
    
    func replaceColorVariables(_ source: String) -> (source: String, color: [ColorVariable]) {
        var updatedLines = [String]()
        var namedColors = [ColorVariable]()
        
        source.enumerateSubstrings(in: source.startIndex..<source.endIndex, options: [.byLines]) { (line, enclosingRange, range, _) in
            if var mutableLine = line {
                var namedColor: ColorVariable?
                
                if mutableLine.contains(".setStroke()") {
                    let color = mutableLine.replacingOccurrences(of: ".setStroke()", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
                    
                    if let name = self.nameForGroupIn(source: source, before: range) {
                        namedColor = ColorVariable(groupName: name, color: color, type: .stroke)
                    }
                }
                
                if mutableLine.contains(".setFill()") {
                    let color = mutableLine.replacingOccurrences(of: ".setFill()", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
                    
                    if let name = self.nameForGroupIn(source: source, before: range) {
                        namedColor = ColorVariable(groupName: name, color: color, type: .fill)
                    }
                }
                
                if mutableLine.contains(".addAttribute(.foregroundColor, value: UIColor") {
                    if let color = self.boundedValueFromString(mutableLine, left: ".addAttribute(.foregroundColor, value: ", right: ", range") {
                        if let name = self.nameForGroupIn(source: source, before: range) {
                            namedColor = ColorVariable(groupName: name, color: color, type: .text)
                        }
                    }
                }

                if let namedColor = namedColor {
                    namedColors.append(namedColor)
                    mutableLine = mutableLine.replacingOccurrences(of: namedColor.color, with: "self.\(namedColor.variableName())")
                }
                
                updatedLines.append(mutableLine)
            }
        }
        
        return (updatedLines.joined(separator: "\n"), namedColors)
    }
    
    // MARK: Text
    
    func replaceTextVariables(_ source: String) -> (source: String, variables: [TextVariable]) {
        var stringVariables = [TextVariable]()
        var updatedLines = [String]()
        // NSMutableAttributedString(string:
        source.enumerateSubstrings(in: source.startIndex..<source.endIndex, options: [.byLines]) { (line, enclosingRange, range, _) in
            if var mutableLine = line {
                if let stringValue = self.boundedValueFromString(mutableLine, left: "NSMutableAttributedString(string: \"", right: "\")") {
                    if let groupName = self.nameForGroupIn(source: source, before: range) {
                        let variable = TextVariable(groupName: groupName, text: stringValue)
                        stringVariables.append(variable)
                        
                        mutableLine = mutableLine.replacingOccurrences(of: "\"\(stringValue)\"", with: variable.variableName())
                    }
                }
                
                updatedLines.append(mutableLine)
            }
        }
        
        return (updatedLines.joined(separator: "\n"), stringVariables)
    }
    
    // MARK: Fonts
    
    func replaceFontVariables(_ source: String) -> (source: String, variables: [FontVariable]) {
        var fontVariables = [FontVariable]()
        var updatedLines = [String]()
        // NSMutableAttributedString(string:
        source.enumerateSubstrings(in: source.startIndex..<source.endIndex, options: [.byLines]) { (line, enclosingRange, range, _) in
            if var mutableLine = line {
                if let stringValue = self.boundedValueFromString(mutableLine, left: ".addAttribute(.font, value: ", right: ", range: ") {
                    if let groupName = self.nameForGroupIn(source: source, before: range) {
                        let variable = FontVariable(groupName: groupName, text: stringValue)
                        fontVariables.append(variable)
                        
                        mutableLine = mutableLine.replacingOccurrences(of: stringValue, with: variable.variableName())
                    }
                }
                
                updatedLines.append(mutableLine)
            }
        }
        
        return (updatedLines.joined(separator: "\n"), fontVariables)
    }

    // MARK: - Utility
    
    func boundedValueFromString(_ string: String, left: String, right: String) -> String? {
        guard string.contains(left) else { return nil }
        let components = string.components(separatedBy: left)
        guard components.count > 1 else { return nil }
        return components[1].components(separatedBy: right).first
    }

    func insertVariables(source: String, variables: [Variable]) -> String {
        var updatedLines = [String]()
        
        source.enumerateLines { (line, stop) in
            updatedLines.append(line)
            
            if line.starts(with: "class ") {
                for variable in variables {
                    let varLine = "    \(variable.variableKeyword()) \(variable.variableName()) = \(variable.variableValue())"
                    updatedLines.append(varLine)
                }
            }
        }
        
        return updatedLines.joined(separator: "\n")
    }
    
    
}
