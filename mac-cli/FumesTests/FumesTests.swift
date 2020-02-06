//
//  FumesTests.swift
//  FumesTests
//
//  Created by Christopher Ladd on 2/6/20.
//  Copyright © 2020 Better Notes, LLC. All rights reserved.
//

import XCTest

class FumesTests: XCTestCase {
    let converter = SwiftSketchFileConverter()
    
    func pathForFixture(_ fixtureName: String) -> String? {
        let bundle = Bundle(for: type(of: self))
        return bundle.path(forResource: fixtureName, ofType: nil, inDirectory: "fixtures")
    }
    
    func resultForFixture(_ fixtureName: String) -> String? {
        guard let path = pathForFixture(fixtureName) else { return nil }
        return converter.convertFileAt(path: path, config: SwiftConverterConfig())
    }
    
    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testFixturePathsExist() {
        XCTAssertNotNil(pathForFixture("CircleSquare.swift"))
    }
    
    func resultHasClass(_ result: String, className: String) -> Bool {
        return result.contains(": \(className) {")
    }
    
    func testConvertsToView() {
        let result = resultForFixture("CircleSquare.swift")
        XCTAssertNotNil(result)
        XCTAssertTrue(resultHasClass(result!, className: "UIView"))
    }

    func testClassMethodsAreReplacedByInstanceMethods() {
        let result = resultForFixture("CircleSquare.swift")!
        
        XCTAssertFalse(result.contains("class func"))
        XCTAssertFalse(result.contains("CircleSquare.draw"))
    }
    
    func testNamedColorsAreInserted() {
        let result = resultForFixture("CircleSquare.swift")!

        XCTAssertTrue(result.contains("var dotFillColor = UIColor.white"))
        XCTAssertTrue(result.contains("var dotStrokeColor = UIColor(hue: 0.068, saturation: 0.837, brightness: 0.769, alpha: 1)"))
    }
    
    func testPrivateColorVariablesAreInserted() {
        let result = resultForFixture("CircleSquare.swift")!
        XCTAssertTrue(result.contains("let triangleFillColor = UIColor(white: 0.73, alpha: 1)"))
    }
    
    func testTextContents() {
        let result = resultForFixture("CircleSquare.swift")!
        XCTAssertTrue(result.contains("var label2TextValue = \"circle\""))
    }
    
    func testFontsAreExtracted() {
        let result = resultForFixture("CircleSquare.swift")!
        
        XCTAssertTrue(result.contains("var label2Font = UIFont(name: \"Helvetica\", size: 11)!"))
        
        XCTAssertFalse(result.contains("label2.addAttribute(.font, value: UIFont(name: \"Helvetica\", size: 11)!"))
    }
    
    func testDrawingCodeIsCreated() {
        let result = resultForFixture("CircleSquare.swift")!
        
        XCTAssertTrue(result.contains("override func draw("))
        XCTAssertTrue(result.contains("drawCircle_square(frame: rect)"))
        XCTAssertTrue(result.contains("override func sizeThatFits(_ size: CGSize) -> CGSize"))
    }
}
