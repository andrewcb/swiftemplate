//  swiftemplate - a compile-time template system for Swift
//  https://github.com/andrewcb/swiftemplate/
//  Created by acb on 19/02/2016.
//  Licenced under the Apache Licence.

import Foundation

extension String {
    var swiftLiteralQuoted: String {
        var r: String = "\""
        for ch in self.characters {
            switch(ch) {
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

extension TemplateElement {
    var asCode: String {
        switch(self) {
        case .Literal(let text): return "_ℜ.append(\(text.swiftLiteralQuoted))"
        case .Code(let code): return code
        case .Expression(let code): return "_ℜ.append(String(\(code)))"
        }
    }
}

extension Template {
    /** Emit the Swift code for a template */
    var asCode: String {
        let start: String = "func \(spec) -> String {\nvar _ℜ=[String]()\n"
        let end: String = "\nreturn _ℜ.joinWithSeparator(\" \")\n}\n"
        return start + (self.elements.map { $0.asCode}).joinWithSeparator("\n")  + end
    }
}