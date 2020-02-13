//
//  main.swift
//  Fumes
//
//  Created by Christopher Ladd on 2/6/20.
//  Copyright © 2020 Better Notes, LLC. All rights reserved.
//

import Foundation
import DashDashSwift
import Cocoa

func parse() -> String? {
    var parser = CommandLineParser(title: "Fumes", description: """
Fumes transpiles PaintCode's static objects into configurable views using layer names to create variables for color fills, strokes, text, fonts, and more.
""")
    parser.arguments = CommandLine.arguments

    parser.register(key: "input", shortKey: "i", index: 0, description: "a path to get the .swift source code")
    parser.register(key: "output", shortKey: "o", index: 1, description: "a path to write the transpiled code")
    parser.register(key: "bg", description: "a string to set the background UIColor for the view. `.clear` by default")
    parser.register(key: "super", description: "an optional superclass for the resulting class. UIView by default.")
    parser.register(key: "verbose", shortKey: "v", description: "whether to output transpiler warnings.")
    parser.register(key: "help", shortKey: "h", description: "show this help message")
    parser.register(key: "copy", shortKey: "c", description: "copy source code to clipboard")
    
    if parser.bool(forKey: "help") {
        parser.printHelp()
        return nil;
    }
    
    guard let input = parser.string(forKey: "input") else { print("ERROR: No input specified."); return nil }
    
    guard input.contains(".swift") else { print("ERROR: Unsupported file type.\nIt looks like your input and output files don't end in `.swift`\nIs there a chance you mistyped something?"); return nil }
    
    let fm = FileManager.default
    
    guard let data = fm.contents(atPath: input) else { print("ERROR: Unable to find data at input path \(input)."); return nil }
    guard let source = String(data: data, encoding: .utf8) else { print("ERROR: Unable to create a string with data at input path \(input)."); return nil }
    
    let transpiler = PaintCodeTranspiler()
    var config = PaintCodeTranspilerConfig()
    
    config.bg = parser.string(forKey: "bg")
    config.className = parser.string(forKey: "super") ?? "UIView"
    config.verbose = parser.bool(forKey: "verbose")
    
    guard let updated = transpiler.transpile(source, config: config) else { print("ERROR: Unable to transpile source code"); return nil }
    guard let output = parser.string(forKey: "output") else {
        if parser.bool(forKey: "copy") {
            let pb = NSPasteboard.general
            pb.declareTypes([.string], owner: nil)
            pb.setString(updated, forType: .string)
            print("Source code has been copied to your clipboard.")
            print("It has been my pleasure to serve you.")
        }
        else {
            print("ERROR: No output specified.");
        }
        
        return nil
    }
    
    guard ((try? updated.write(toFile:output, atomically: true, encoding: .utf8)) != nil) else { print("ERROR: Unable to write transpiled code to output \(output)"); return nil }

    return output
}


if let output = parse() {
    print("\nTranspiled source code has been written to")
    print(output)
    print("\nIt has been my pleasure to serve you.")
}
