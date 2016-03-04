//
//  CodeGenerationTests.swift
//  swiftemplate
//
//  Created by acb on 03/03/2016.
//  Copyright © 2016 Kineticfactory. All rights reserved.
//

import XCTest

class CodeGenerationTests: XCTestCase {

    func testTemplateElementLiteralAsCode() {
        let options = CodeGenerationOptions()
        
        XCTAssertEqual(TemplateElement.Literal(text:"abcd").asCode(options), "_ℜ.append(\"abcd\")")
        
        XCTAssertEqual(TemplateElement.Literal(text:"<a href=\"/\">Back</a>").asCode(options), "_ℜ.append(\"<a href=\\\"/\\\">Back</a>\")")
    }
    
    func testTemplateElementCodeAsCode() {
        let options = CodeGenerationOptions()
        XCTAssertEqual(TemplateElement.Code(code:"if i<0 {").asCode(options), "if i<0 {")
    }
    
    func testTemplateElementExpressionAsCodeQuotingDisabled() {
        let options = CodeGenerationOptions(htmlQuoteExpressions: false)
        
        XCTAssertEqual(TemplateElement.Expression(code:"2+3", unfiltered:false).asCode(options), "_ℜ.append(String(2+3))")
        XCTAssertEqual(TemplateElement.Expression(code:"\"abc\".characters.count", unfiltered:false).asCode(options), "_ℜ.append(String(\"abc\".characters.count))")
        XCTAssertEqual(TemplateElement.Expression(code:"2+3", unfiltered:true).asCode(options), "_ℜ.append(String(2+3))")
        XCTAssertEqual(TemplateElement.Expression(code:"\"abc\".characters.count", unfiltered:true).asCode(options), "_ℜ.append(String(\"abc\".characters.count))")
    }
    
    func testTemplateElementExpressionAsCodeQuotingEnabled() {
        let options = CodeGenerationOptions(htmlQuoteExpressions: true)
        
        XCTAssertEqual(TemplateElement.Expression(code:"2+3", unfiltered:false).asCode(options), "_ℜ.append(String(2+3).HTMLQuote)")
        XCTAssertEqual(TemplateElement.Expression(code:"\"abc\".characters.count", unfiltered:false).asCode(options), "_ℜ.append(String(\"abc\".characters.count).HTMLQuote)")
        XCTAssertEqual(TemplateElement.Expression(code:"2+3", unfiltered:true).asCode(options), "_ℜ.append(String(2+3))")
        XCTAssertEqual(TemplateElement.Expression(code:"\"abc\".characters.count", unfiltered:true).asCode(options), "_ℜ.append(String(\"abc\".characters.count))")
    }
    
    func testTemplateAsCode() {
        let options = CodeGenerationOptions(htmlQuoteExpressions: true)

        let t1 = Template(spec: "f1(a:[Int])", elements: [
            TemplateElement.Literal(text:"<h1>this is a test</h1>"),
            TemplateElement.Code(code:"if a.isEmpty {"),
            TemplateElement.Literal(text:"<p>Zilch</p>"),
            TemplateElement.Code(code:"} else {"),
            TemplateElement.Expression(code: "a.count", unfiltered:false),
            TemplateElement.Code(code:"}"),
            ])
        XCTAssertEqual(t1.asCode(options), "func f1(a:[Int]) -> String {\nvar _ℜ=[String]()\n_ℜ.append(\"<h1>this is a test</h1>\")\nif a.isEmpty {\n_ℜ.append(\"<p>Zilch</p>\")\n} else {\n_ℜ.append(String(a.count).HTMLQuote)\n}\nreturn _ℜ.joinWithSeparator(\" \")\n}\n")
    }
}
