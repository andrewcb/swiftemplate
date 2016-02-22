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

    func testTemplateElementAsCode() {
        
        XCTAssertEqual(TemplateElement.Literal(text:"abcd").asCode, "r.append(\"abcd\")")

        XCTAssertEqual(TemplateElement.Literal(text:"<a href=\"/\">Back</a>").asCode, "r.append(\"<a href=\\\"/\\\">Back</a>\")")
        
        
        XCTAssertEqual(TemplateElement.Code(code:"if i<0 {").asCode, "if i<0 {")
    }
    
    func testTemplateAsCode() {
        let t1 = Template(spec: "f1(a:Int)", elements: [
            TemplateElement.Literal(text:"<h1>this is a test</h1>"),
            TemplateElement.Code(code:"if a==0 {"),
            TemplateElement.Literal(text:"<p>Zilch</p>"),
            TemplateElement.Code(code:"}"),
        ])
        XCTAssertEqual(t1.asCode, "func f1(a:Int) {\nvar r=[String]()\nr.append(\"<h1>this is a test</h1>\")\nif a==0 {\nr.append(\"<p>Zilch</p>\")\n}\nreturn r.joinWithSeparator(\" \")\n}\n")
    }

}
