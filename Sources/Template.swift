//
//  Template.swift
//  swiftemplate
//
//  Created by acb on 21/02/2016.
//  Copyright © 2016 Kineticfactory. All rights reserved.
//

import Foundation

extension String {
    var swiftLiteralQuoted: String {
        var r: String = "\""
        for ch in self.characters {
            switch(ch) {
            //case "\\": r.appendContentsOf("\\\\")
            case "\"": r.appendContentsOf("\\\"")
            case "\r": r.appendContentsOf("\\r")
            case "\n": r.appendContentsOf("\\n")
            case "\t": r.appendContentsOf("\\t")
            case "\0": r.appendContentsOf("\\0")
            default: r.append(ch)
            }
        }
        r.append(Character("\""))
        return r
    }
}

/** A single element of a template; this corresponds 1-to-1 to code being emitted */
enum TemplateElement : Equatable {
    /// A block of HTML text to emit literally
    case Literal(text: String)
    /// a block of Swift code
    case Code(code: String)
    
    var asCode: String {
        switch(self) {
        case .Literal(let text): return "r.append(\(text.swiftLiteralQuoted))"
        case .Code(let code): return code
        }
    }
}

func ==(lhs: TemplateElement, rhs: TemplateElement) -> Bool {
    switch((lhs, rhs)) {
    case (.Literal(let ltext), .Literal(let rtext)): return ltext == rtext
    case (.Code(let lcode), .Code(let rcode)): return lcode == rcode
    default: return false
    }
}

func simplifyTemplateElements<S: SequenceType where S.Generator.Element == TemplateElement>(input: S) -> [TemplateElement] {
    // amalgamate any adjacent .Literals, to reduce the number of lines of code in the generated function
    var literalsSeen = [String]()
    var result = [TemplateElement]()
    
    for elem in input {
        if case let TemplateElement.Literal(text) = elem {
            literalsSeen.append(text)
        } else {
            if !literalsSeen.isEmpty {
                result.append(TemplateElement.Literal(text:literalsSeen.joinWithSeparator("\n")))
                literalsSeen.removeAll()
            }
            result.append(elem)
        }
    }
    if !literalsSeen.isEmpty {
        result.append(TemplateElement.Literal(text:literalsSeen.joinWithSeparator("\n")))
    }
    return result
}

struct Template {
    /** the name and arguments of the template */
    let spec: String
    
    /** the elements making up the template */
    let elements: [TemplateElement]
    
    init(spec: String, elements: [TemplateElement]) {
        self.spec = spec
        self.elements = elements
    }
    
    /** Emit the Swift code for a template */
    var asCode: String {
        let start: String = "func \(spec) -> String {\nvar r=[String]()\n"
        let end: String = "\nreturn r.joinWithSeparator(\" \")\n}\n"
        return start + (self.elements.map { $0.asCode}).joinWithSeparator("\n")  + end
    }
}