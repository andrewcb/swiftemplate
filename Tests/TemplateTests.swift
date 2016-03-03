//  TemplateTests.swift
//  swiftemplate - a compile-time template system for Swift
//  https://github.com/andrewcb/swiftemplate/
//  Created by acb on 21/02/2016.
//  Licenced under the Apache Licence.

import XCTest

class TemplateTests: XCTestCase {

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

}
