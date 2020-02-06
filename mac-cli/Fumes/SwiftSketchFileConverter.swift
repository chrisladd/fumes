//
//  SwiftSketchFileConverter.swift
//  Fumes
//
//  Created by Christopher Ladd on 2/6/20.
//  Copyright © 2020 Better Notes, LLC. All rights reserved.
//

import Foundation

public struct SwiftConverterConfig {
    public var className = "UIView"
}

public struct SwiftSketchFileConverter {
    public init() {
        
    }

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

                if let namedColor = namedColor {
                    namedColors.append(namedColor)
                    mutableLine = mutableLine.replacingOccurrences(of: namedColor.color, with: "self.\(namedColor.variableName())")
                }
                
                updatedLines.append(mutableLine)
            }
        }
        
        return (updatedLines.joined(separator: "\n"), namedColors)
    }
    
    func replaceTextVariables(_ source: String) -> (source: String, variables: [TextVariable]) {
        var stringVariables = [TextVariable]()
        var updatedLines = [String]()
        // NSMutableAttributedString(string:
        source.enumerateSubstrings(in: source.startIndex..<source.endIndex, options: [.byLines]) { (line, enclosingRange, range, _) in
            if var mutableLine = line {
                if mutableLine.contains("NSMutableAttributedString(string: ") {
                    
                    let stringValue = mutableLine.components(separatedBy: "NSMutableAttributedString(string: \"")[1].replacingOccurrences(of: "\")", with: "")
                    
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
    
    public func convertFileAt(path: String, config: SwiftConverterConfig) -> String? {
        guard var source = try? String(contentsOfFile: path) else { return nil }
        
        if let className = classNameFrom(source) {
            print(className)
            source = removeClassFunctionsFrom(source, className: className)
        }
        
        source = source.replacingOccurrences(of: ": NSObject {", with: ": \(config.className) {")
        
        let colorResult = replaceColorVariables(source)
        source = insertVariables(source: colorResult.source, variables: colorResult.color)
        
        let textResult = replaceTextVariables(source)
        source = insertVariables(source: textResult.source, variables: textResult.variables)
        
        return source
    }
    
}
