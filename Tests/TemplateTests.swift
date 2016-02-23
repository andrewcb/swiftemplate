//
//  TemplateTests.swift
//  swiftemplate
//
//  Created by acb on 21/02/2016.
//  Copyright © 2016 Kineticfactory. All rights reserved.
//

import XCTest

class TemplateTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    // ---------------
    
    func testSimplifyTemplateElements() {
        let input = [
            TemplateElement.Literal(text:"<h1>Heading</h1>"),
            TemplateElement.Literal(text:"<p>this is some text</p>"),
            TemplateElement.Literal(text:"<ul>"),
            TemplateElement.Code(code:"for i in items {"),
            TemplateElement.Literal(text:"<li>\\(i)</li>"),
            TemplateElement.Code(code:"}"),
            TemplateElement.Literal(text:"<br/>")
        ]
        let desiredOutput = [
            TemplateElement.Literal(text:"<h1>Heading</h1>\n<p>this is some text</p>\n<ul>"),
            TemplateElement.Code(code:"for i in items {"),
            TemplateElement.Literal(text:"<li>\\(i)</li>"),
            TemplateElement.Code(code:"}"),
            TemplateElement.Literal(text:"<br/>")
        ]
        XCTAssertEqual(simplifyTemplateElements(input), desiredOutput)
    }
    
    // ---------------
    
    func testTemplateElementAsCode() {
        
        XCTAssertEqual(TemplateElement.Literal(text:"abcd").asCode, "r.append(\"abcd\")")

        XCTAssertEqual(TemplateElement.Literal(text:"<a href=\"/\">Back</a>").asCode, "r.append(\"<a href=\\\"/\\\">Back</a>\")")
        
        
        XCTAssertEqual(TemplateElement.Code(code:"if i<0 {").asCode, "if i<0 {")
        
        XCTAssertEqual(TemplateElement.Expression(code:"2+3").asCode, "r.append(String(2+3))")
        XCTAssertEqual(TemplateElement.Expression(code:"\"abc\".characters.count").asCode, "r.append(String(\"abc\".characters.count))")
    }
    
    func testTemplateAsCode() {
        let t1 = Template(spec: "f1(a:[Int])", elements: [
            TemplateElement.Literal(text:"<h1>this is a test</h1>"),
            TemplateElement.Code(code:"if a.isEmpty {"),
            TemplateElement.Literal(text:"<p>Zilch</p>"),
            TemplateElement.Code(code:"} else {"),
            TemplateElement.Expression(code: "a.count"),
            TemplateElement.Code(code:"}"),
        ])
        XCTAssertEqual(t1.asCode, "func f1(a:[Int]) -> String {\nvar r=[String]()\nr.append(\"<h1>this is a test</h1>\")\nif a.isEmpty {\nr.append(\"<p>Zilch</p>\")\n} else {\nr.append(String(a.count))\n}\nreturn r.joinWithSeparator(\" \")\n}\n")
    }

}
