//
//  TemplateParsingTests.swift
//  swiftemplate
//
//  Created by acb on 20/02/2016.
//  Copyright © 2016 Kineticfactory. All rights reserved.
//

import XCTest

func == <A : Equatable, B : Equatable>(lhs: (A, B), rhs: (A, B)) -> Bool
{
    return (lhs.0 == rhs.0) && (lhs.1 == rhs.1)
}

class TemplateParsingTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testStringLstrip() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        
        XCTAssertEqual("abc".lstrip, "abc")
        XCTAssertEqual("  abc".lstrip, "abc")
        XCTAssertEqual("\t abc".lstrip, "abc")
        XCTAssertEqual("\t a b c".lstrip, "a b c")
        XCTAssertEqual("    ".lstrip, nil)
    }
    
    func testStringRstrip() {
        XCTAssertEqual("abc".rstrip, "abc")
        XCTAssertEqual("abc  ".rstrip, "abc")
        XCTAssertEqual("abc\t ".rstrip, "abc")
        XCTAssertEqual("a b c \t".rstrip, "a b c")
        XCTAssertEqual("    ".rstrip, nil)
    }
    
    func testStringTextAfterEscape() {
        
        XCTAssertEqual("   %% foo(bar)".textAfterEscape, "foo(bar)")
        XCTAssertEqual("   %%".textAfterEscape, nil)
        XCTAssertEqual("   %%   ".textAfterEscape, nil)
        XCTAssertEqual(" Hello world".textAfterEscape, nil)
        XCTAssertEqual("this is not an escape   %% foo(bar)".textAfterEscape, nil)
    }
    
    func testStringFirstWordAndRest() {
        
        let v1: (String,String)? = "foo bar baz".firstWordAndRest
        XCTAssert(v1 != nil && v1! == ("foo", "bar baz"))
        
        let v2: (String,String)? = "foo ".firstWordAndRest
        XCTAssert(v2 != nil && v2! == ("foo", ""))
        
        let v3: (String,String)? = "foo".firstWordAndRest
        XCTAssert(v3 != nil && v3! == ("foo", ""))

        let v4: (String,String)? = "   foo bar baz".firstWordAndRest
        XCTAssert(v4 != nil && v4! == ("foo", "bar baz"))        
    }
    
    // ---------------
    
    func testTemplateLineConstruct() {
        do {
            let tl1 = try TemplateLine(line:"Hello world")
            XCTAssertEqual(tl1, TemplateLine.Text(text:"Hello world"))

            let tl2 = try TemplateLine(line:" %% template foo(v1:String, v2:[Int])")
            XCTAssertEqual(tl2, TemplateLine.TemplateStart(spec:"foo(v1:String, v2:[Int])"))
            
            let tl2a = try TemplateLine(line:"%% endtemplate")
            XCTAssertEqual(tl2a, TemplateLine.TemplateEnd)
            
            let tl3 = try TemplateLine(line:"%% for i in items")
            XCTAssertEqual(tl3, TemplateLine.ForStart(variable:"i", iterable:"items"))
            
            let tl4 = try TemplateLine(line:"%% endfor")
            XCTAssertEqual(tl4, TemplateLine.ForEnd)
            
            let tl5 = try TemplateLine(line:"%% if foo==bar")
            XCTAssertEqual(tl5, TemplateLine.IfStart(expression: "foo==bar"))
            
            let tl6 = try TemplateLine(line:"%% elif foo==bar")
            XCTAssertEqual(tl6, TemplateLine.IfElif(expression: "foo==bar"))
            
            let tl6a = try TemplateLine(line:"%% else if foo==bar")
            XCTAssertEqual(tl6a, TemplateLine.IfElif(expression: "foo==bar"))
            
            let tl7 = try TemplateLine(line:"%% else")
            XCTAssertEqual(tl7, TemplateLine.IfElse)
            
            let tl8 = try TemplateLine(line:"%% endif")
            XCTAssertEqual(tl8, TemplateLine.IfEnd)
            
            
        } catch {
            XCTFail("error thrown")
        }
    }
    
    // ---------------
    
    func testParseTemplate() {
        let input: [String] = [
            "%% template foo(items:[String])",
            "<h1>Heading</h1>",
            "<p>Hello world</p>",
            "%% if items.isEmpty",
            "<p>There are no items</p>",
            "%% else",
            "<ul>",
            "%% for item in items",
            "<li>\\"+"(item)</li>",
            "%% endfor",
            "</ul>",
            "%% endif"
        ]
        var g = input.generate()
        do {
            
            if let tmpl = try parseTemplate(&g) {
                XCTAssertEqual(tmpl.spec, "foo(items:[String])")
                XCTAssertEqual(tmpl.elements, [
                    TemplateElement.Literal(text: "<h1>Heading</h1>\n<p>Hello world</p>"),
                    TemplateElement.Code(code: "if items.isEmpty {"),
                    TemplateElement.Literal(text:"<p>There are no items</p>"),
                    TemplateElement.Code(code: "} else {"),
                    TemplateElement.Literal(text: "<ul>"),
                    TemplateElement.Code(code: "for item in items {"),
                    TemplateElement.Literal(text: "<li>\\"+"(item)</li>"),
                    TemplateElement.Code(code: "}"),
                    TemplateElement.Literal(text: "</ul>"),
                    TemplateElement.Code(code: "}")
                    ])
            } else {
                XCTFail("parseTemplate returned null")
            }
        } catch {
            XCTFail("error thrown")
        }
    }
    
    func testParseTemplates() {
        let input:[String] = [
            "%% template foo()",
            "<p>This is a template</p>",
            "%% endtemplate",
            "",
            "%% template greeting(name:String)",
            "<p>Hello, \\(name)</p>",
            "%% endtemplate",
        ]
        do {
            let parsed = try parseTemplates(input)
            XCTAssertEqual(parsed.count, 2)
            XCTAssertEqual(parsed[0].spec, "foo()")
            XCTAssertEqual(parsed[0].elements, [TemplateElement.Literal(text:"<p>This is a template</p>")])
            XCTAssertEqual(parsed[1].spec, "greeting(name:String)")
            XCTAssertEqual(parsed[1].elements, [TemplateElement.Literal(text:"<p>Hello, \\(name)</p>")])
        } catch {
            XCTFail("error thrown: \(error)")
        }            
        
    }
    
}