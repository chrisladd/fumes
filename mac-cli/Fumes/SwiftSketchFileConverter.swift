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
    
    struct NamedColor {
        enum ColorType {
            case stroke, fill
        }
        
        enum Visibility {
            case _public, _private
        }
        
        let groupName: String
        let color: String
        let type: ColorType
        let visibility: Visibility
        
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
        
        func variableKeyword() -> String {
            if visibility == ._private {
                return "let"
            }
            
            return "public var"
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
    
    func insertColorVariables(source: String, colors: [NamedColor]) -> String {
        var updatedLines = [String]()
        
        source.enumerateLines { (line, stop) in
            updatedLines.append(line)
            
            if line.starts(with: "class ") {
                for color in colors {
                    let colorLine = "    \(color.variableKeyword()) \(color.variableName()) = \(color.color)"
                    updatedLines.append(colorLine)
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
        source = colorResult.source
        
        source = insertColorVariables(source: source, colors: colorResult.color)
        
        return source
    }
    
}
