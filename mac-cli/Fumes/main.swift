//
//  main.swift
//  Fumes
//
//  Created by Christopher Ladd on 2/6/20.
//  Copyright © 2020 Better Notes, LLC. All rights reserved.
//

import Foundation
import DashDashSwift

extension CommandLineParser {
    func stringFor(key: String, or index: Int) -> String? {
        if let result = stringFor(key: key) {
            return result
        }
        
        let unflaggedArgs = unflaggedArguments()
        
        if unflaggedArgs.count > index {
            return unflaggedArgs[index]
        }
        
        return nil
    }
    
    func printHelp(_ message: String? = nil) {
        if let message = message {
            print("\n")
            print(message)
            print("\n\n")
        }
        
        printHelp()
    }
}

func parse() -> Bool {
    var parser = CommandLineParser(title: "Fumes", description: "Fumes transpiles PaintCode's static objects into configurable views.")
    parser.arguments = CommandLine.arguments

    parser.register(key: "input", shortKey: "i", description: "a path to get the .swift source code")
    parser.register(key: "output", shortKey: "o", description: "a path to write the transpiled code")

    guard parser.boolForKey("help") == false else { parser.printHelp(); return false }
    guard let input = parser.stringFor(key: "input", or:0) else { print("ERROR: No input specified."); return false }
    guard let output = parser.stringFor(key: "output", or:1) else { print("ERROR: No output specified."); return false }
    
    let fm = FileManager.default
    
    guard let data = fm.contents(atPath: input) else { print("ERROR: Unable to find data at input path \(input)."); return false }
    guard let source = String(data: data, encoding: .utf8) else { print("ERROR: Unable to create a string with data at input path \(input)."); return false }
    
    let transpiler = PaintCodeTranspiler()
    guard let updated = transpiler.transpile(source) else { print("ERROR: Unable to transpile source code"); return false; }

    guard ((try? updated.write(toFile:output, atomically: true, encoding: .utf8)) != nil) else { print("ERROR: Unable to write transpiled code to output \(output)"); return false }

    return true
}


if (!parse()) {
    // do something
}
