//  swiftemplate - a compile-time template system for Swift
//  https://github.com/andrewcb/swiftemplate/
//  Created by acb on 21/02/2016.
//  Licenced under the Apache Licence.

import Foundation

/** A single element of a template; this corresponds 1-to-1 to code being emitted */
enum TemplateElement : Equatable {
    /// A block of HTML text to emit literally
    case Literal(text: String)
    /// a block of Swift code
    case Code(code: String)
    /// a string expression to be added to the buffer
    case Expression(code: String)
}

func ==(lhs: TemplateElement, rhs: TemplateElement) -> Bool {
    switch((lhs, rhs)) {
    case (.Literal(let ltext), .Literal(let rtext)): return ltext == rtext
    case (.Code(let lcode), .Code(let rcode)): return lcode == rcode
    case (.Expression(let lcode), .Expression(let rcode)): return lcode == rcode
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
    
}
