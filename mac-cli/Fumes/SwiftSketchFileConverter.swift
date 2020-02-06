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
    
    
    
    struct NamedColor: Variable {
        var visibility: Visibility
        
        enum ColorType {
            case stroke, fill
        }
        
        
        let groupName: String
        let color: String
        let type: ColorType
        
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
            
            if type == .stroke {
                return firstWord + "StrokeColor"
            }
            else {
                return firstWord + "FillColor"
            }
        }
    }
    
    func replaceNamedColors(_ source: String) -> (source: String, color: [NamedColor]) {
        var updatedLines = [String]()
        var namedColors = [NamedColor]()
        
        source.enumerateSubstrings(in: source.startIndex..<source.endIndex, options: [.byLines]) { (line, enclosingRange, range, _) in
            if var mutableLine = line {
                var namedColor: NamedColor?
                
                if mutableLine.contains(".setStroke()") {
                    let color = mutableLine.replacingOccurrences(of: ".setStroke()", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
                    
                    if let name = self.nameForGroupIn(source: source, before: range) {
                        namedColor = NamedColor(groupName: name, color: color, type: .stroke)
                    }
                }
                
                if mutableLine.contains(".setFill()") {
                    let color = mutableLine.replacingOccurrences(of: ".setFill()", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
                    
                    if let name = self.nameForGroupIn(source: source, before: range) {
                        namedColor = NamedColor(groupName: name, color: color, type: .fill)
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
    
    struct StringVariable: Variable {
        var visibility: Visibility
        let groupName: String
        let text: String

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
            let trimmed = groupName.trimmingCharacters(in: CharacterSet(charactersIn: "_"))
            let firstWord = trimmed.prefix(1).lowercased() + trimmed.dropFirst()
            
            return firstWord + "TextValue"
        }
    }
    
    func replaceRawStringValues(_ source: String) -> (source: String, variables: [StringVariable]) {
        var stringVariables = [StringVariable]()
        var updatedLines = [String]()
        // NSMutableAttributedString(string:
        source.enumerateSubstrings(in: source.startIndex..<source.endIndex, options: [.byLines]) { (line, enclosingRange, range, _) in
            if var mutableLine = line {
                if mutableLine.contains("NSMutableAttributedString(string: ") {
                    
                    let stringValue = mutableLine.components(separatedBy: "NSMutableAttributedString(string: \"")[1].replacingOccurrences(of: "\")", with: "")
                    
                    if let groupName = self.nameForGroupIn(source: source, before: range) {
                        let variable = StringVariable(groupName: groupName, text: stringValue)
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
        
        let colorResult = replaceNamedColors(source)
        source = insertVariables(source: colorResult.source, variables: colorResult.color)
        
        let textResult = replaceRawStringValues(source)
        source = insertVariables(source: textResult.source, variables: textResult.variables)
        
        return source
    }
    
}