//
//  FumesTests.swift
//  FumesTests
//
//  Created by Christopher Ladd on 2/6/20.
//  Copyright © 2020 Better Notes, LLC. All rights reserved.
//

import XCTest

class FumesTests: XCTestCase {
    let transpiler = PaintCodeTranspiler()
    
    // MARK: - Fixtures
    
    func pathForFixture(_ fixtureName: String) -> String? {
        let bundle = Bundle(for: type(of: self))
        return bundle.path(forResource: fixtureName, ofType: nil, inDirectory: "fixtures")
    }
    
    func resultForFixture(_ fixtureName: String) -> String? {
        guard let path = pathForFixture(fixtureName) else { return nil }
        guard let source = try? String(contentsOfFile: path) else { return nil }
        
        return transpiler.transpile(source)
    }
    
    // MARK: - Tests
    
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
        
        XCTAssertFalse(result.contains("CircleSquare.draw"))
    }
    
    func testNamedColorsAreInserted() {
        let result = resultForFixture("CircleSquare.swift")!

        XCTAssertTrue(result.contains("var dotFillColor = UIColor.white"))
        XCTAssertTrue(result.contains("var dotStrokeColor = UIColor(hue: 0.068, saturation: 0.837, brightness: 0.769, alpha: 1)"))
    }
    
    func testTextColorIsExtracted() {
        let result = resultForFixture("CircleSquare.swift")!

        XCTAssertTrue(result.contains("var label2TextColor = UIColor(hue: 0.45, saturation: 0.919, brightness: 0.835, alpha: 1)"))
    }
    
    func testPrivateColorVariablesAreInserted() {
        let result = resultForFixture("CircleSquare.swift")!
        XCTAssertTrue(result.contains("let triangleFillColor = UIColor(white: 0.73, alpha: 1)"))
    }
    
    func testTextContents() {
        let result = resultForFixture("CircleSquare.swift")!
        XCTAssertTrue(result.contains("var label2Text = \"circle\""))
    }
    
    func testFontsAreExtracted() {
        let result = resultForFixture("CircleSquare.swift")!
        
        XCTAssertTrue(result.contains("var label2Font = UIFont(name: \"Helvetica\", size: 11)"))
        XCTAssertFalse(result.contains("label2.addAttribute(.font, value: UIFont(name: \"Helvetica\", size: 11)!"))
    }
    
    func testFontsAreNilCoalescedNotForceUnwrapped() {
        let result = resultForFixture("CircleSquare.swift")!
        
        XCTAssertTrue(result.contains("var label2Font = UIFont(name: \"Helvetica\", size: 11) ?? UIFont.systemFont(ofSize: 11.0)"))
        XCTAssertFalse(result.contains("label2Font = UIFont(name: \"Helvetica\", size: 11)!"))
    }
    
    func testDrawingCodeIsCreated() {
        let result = resultForFixture("CircleSquare.swift")!
        
        XCTAssertTrue(result.contains("override func draw("))
        XCTAssertTrue(result.contains("drawCircle_square(frame: rect)"))
    }
    
    func testSizeGettersAreCreated() {
        let result = resultForFixture("CircleSquare.swift")!
        
        XCTAssertTrue(result.contains("override func sizeThatFits(_ size: CGSize) -> CGSize"))
        XCTAssertTrue(result.contains("class func sizeThatFits"))
    }
    
    func testInitializersAndBackgroundColor() {
        let result = resultForFixture("CircleSquare.swift")!
        /*
         func commonInit() {
             backgroundColor = .clear
         }
         
         override init(frame: CGRect) {
             super.init(frame: frame)
             commonInit()
         }
         
         required init?(coder: NSCoder) {
             super.init(coder: coder)
             commonInit()
         }

         */
        XCTAssertTrue(result.contains("required init?(coder: NSCoder) {"))
        XCTAssertTrue(result.contains("override init(frame: CGRect) {"))
        XCTAssertTrue(result.contains("backgroundColor = .clear"))
    }
    
}
