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
        let config = config ?? PaintCodeTranspilerConfig()

        guard config.language == .swift else {
            print("Error: unsupported source type")
            return nil
        }
        
        var source = sourceCode;
        
        if let className = classNameFrom(source) {
            source = removeClassFunctionsFrom(source, className: className)
        }
        
        source = source.replacingOccurrences(of: ": NSObject {", with: ": \(config.className) {")
        
        source = insertInitializersIn(source: source, bgColor: config.bg)
        
        // MARK: Colors
        
        let colorResult = replaceColorVariables(source)
        var usedVariableNames = [String]()
        (source, usedVariableNames) = insertVariables(source: colorResult.source, variables: colorResult.color, existing: usedVariableNames, config: config)

        // MARK: Bezier Paths
        
        // get bezier path variables via fill color variables
        var frameVariables = [FrameVariable]()
        for color in colorResult.color {
            guard color.type == .fill else { continue }
            frameVariables.append(FrameVariable(visibility: color.visibility,
                                                 groupName: color.groupName,
                                                 type: .bezierPath))
        }
        
        // insert bezier path frame variable assignment
        source = insertBezierPathFrameAssignments(variables: frameVariables, source: source)
        (source, usedVariableNames) = insertVariables(source: source, variables: frameVariables, existing: usedVariableNames, config: config)

        // MARK: Text
        
        let textResult = replaceTextVariables(source)
        (source, usedVariableNames) = insertVariables(source: textResult.source, variables: textResult.variables, existing: usedVariableNames, config: config)
        
        let fontResult = replaceFontVariables(source)
        (source, usedVariableNames) = insertVariables(source: fontResult.source, variables: fontResult.variables, existing: usedVariableNames, config: config)
        
        source = insertDrawRectIn(source: source)
        
        return source
    }
    
    func insertBezierPathFrameAssignments(variables: [FrameVariable], source: String) -> String {
        var updatedLines = [String]()
        
        source.enumerateLines { (line, stop) in
            updatedLines.append(line)
            
            for variable in variables {
                // find a matching fill call for the groupName
                // note the space here
                if line.contains(" \(variable.groupVariableName).fill()") {
                    let assignment = "        \(variable.variableName()) = convertRectToViewSpace(\(variable.groupVariableName).bounds, context: context)"
                    updatedLines.append(assignment)
                    break
                }
            }
        }
        
        return updatedLines.joined(separator: "\n")
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
            updatedLines.append(line)
            
            if line.starts(with: "class ") {
                updatedLines.append(initializers)
            }
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

    func convertRectToViewSpace(_ rect: CGRect, context: CGContext) -> CGRect {
        return context.convertToDeviceSpace(rect).applying(CGAffineTransformMakeScale(1 / UIScreen.main.scale, 1 / UIScreen.main.scale))
    }

    override func sizeThatFits(_ size: CGSize) -> CGSize {
        // scale the size to the given width
         let nativeRect = \(rectValue)
         let aspect = size.width / nativeRect.width
         let height = nativeRect.height * aspect
    
         return CGSize(width: size.width, height: height)
    }

    class func sizeThatFits(_ size: CGSize) -> CGSize {
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
        var lastGroupName: String? = nil
        var lastVariable: TextVariable? = nil
        // NSMutableAttributedString(string:
        source.enumerateSubstrings(in: source.startIndex..<source.endIndex, options: [.byLines]) { (line, enclosingRange, range, _) in
            if var mutableLine = line {
                // convert the initializer to use the variable name
                if let stringValue = self.boundedValueFromString(mutableLine, left: "NSMutableAttributedString(string: \"", right: "\")") {
                    if let groupName = self.nameForGroupIn(source: source, before: range) {
                        let variable = TextVariable(groupName: groupName, text: stringValue)
                        stringVariables.append(variable)
                        lastGroupName = groupName
                        lastVariable = variable
                        mutableLine = mutableLine.replacingOccurrences(of: "\"\(stringValue)\"", with: variable.variableName())
                    }
                }
                else if let lastGroupName = lastGroupName, let lastVariable = lastVariable {
                    // FIND the line where our target group is being drawn
                    if mutableLine.contains("\(lastGroupName).draw(in: ") {

                        // EXTRACT the CGRect where it is being drawn
                        // and assign the translated version to our frame variable
                        
                        if let labelRect = extractCGRectFrom(line: mutableLine) {
                            let frameLine = "        \(lastVariable.variableName(suffix: "Frame")) = convertRectToViewSpace(\(labelRect), context: context)"
                            updatedLines.append(frameLine)
                        }
                        
                        // insert attributed string drawing override right before
                        let attributedStringDrawing = """
                                    // if explicit text for \(lastGroupName) was defined, use that
                                    if let attributedText = \(lastVariable.variableName(suffix: "AttributedText")) {
                                        \(lastGroupName).setAttributedString(attributedText)
                                    }
                        """

                        updatedLines.append(attributedStringDrawing)
                    }
                }
                
                updatedLines.append(mutableLine)
            }
        }
        
        return (updatedLines.joined(separator: "\n"), stringVariables)
    }
    
    func extractCGRectFrom(line: String) -> String? {
        // label2.draw(in: CGRect(x: 68.97, y: 5, width: 45, height: 15))
        if let startRange = line.range(of: "CGRect(x:"), let endRange = line.range(of: "))") {
            let substring = line[startRange.lowerBound..<endRange.lowerBound]
            return "\(substring))"
        }
        
        return nil
    }
    
    // MARK: Fonts
    
    func replaceFontVariables(_ source: String) -> (source: String, variables: [FontVariable]) {
        var fontVariables = [FontVariable]()
        var updatedLines = [String]()
        
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

    func insertVariables(source: String, variables: [Variable], existing existingVariableNames: [String], config: PaintCodeTranspilerConfig) -> (source: String, placedVariables: [String]) {
        var updatedLines = [String]()
        var updatedVariableNames = existingVariableNames
        
        source.enumerateLines { (line, stop) in
            updatedLines.append(line)
            
            if line.starts(with: "class ") {
                for variable in variables {
                    let variableName = variable.variableName()
                    guard updatedVariableNames.contains(variableName) == false else {
                        if config.verbose {
                            print("WARNING: duplicate variable named \(variableName). Consider renaming your source files.")
                        }
                        continue
                    }
                    
                    let varLine = "    \(variable.variableKeyword()) \(variable.variableName()): \(variable.typeName) = \(variable.variableValue())"
                    updatedVariableNames.append(variableName)
                    updatedLines.append(varLine)

                    // TextVariable(visibility: FumesTests.Visibility._public, groupName: "label2", text: "circle")

                    // is this a string? if so, add an attributed variable as well.
                    if let textVariable = variable as? TextVariable {
                        let varLine = "    \(textVariable.variableKeyword()) \(textVariable.attributedVariableName()): NSAttributedString? = nil"
                        updatedLines.append(varLine)
                        
                        // and add a frame value
                        let frameLine = "    \(textVariable.variableKeyword()) \(textVariable.variableName(suffix: "Frame")): CGRect = .zero"
                        updatedLines.append(frameLine)
                    }
                }
            }
        }
        
        return (updatedLines.joined(separator: "\n"), updatedVariableNames)
    }
    
    
}
