//  swiftemplate - a compile-time template system for Swift
//  https://github.com/andrewcb/swiftemplate/
//  Created by acb on 19/02/2016.
//  Licenced under the Apache Licence.

import Foundation

//  Tokens to look for

let TokenLineEscape = "%%"
let TokenExprOpen = "<%="  // start of an inline expression
let TokenExprClose = "%>"  // end of an inline expression
let TokenCodeOpen = "<%"   // start of a code block
let TokenCodeClose = "%>"  // end of a code block

extension Character {
    var isspace: Bool {
        return self == " " || self == "\t"
    }
}

extension String {
    /** Return the first index at or after a point where the character meets a criterion  */
    func firstIndexMatching(predicate: (Character)->Bool, from: String.CharacterView.Index) -> String.CharacterView.Index? {
        var index = from
        while index != self.characters.endIndex && !predicate(self.characters[index]) {
            index = index.successor()
        }
        return (index != self.characters.endIndex) ? index : nil
    }
    
    /** Return the last index not matching a criterion, following one which matches */
    func lastIndexNotMatching(predicate: (Character)->Bool, to: String.CharacterView.Index) -> String.CharacterView.Index? {
        var index = to
        while index != self.characters.startIndex && !predicate(self.characters[index.predecessor()]) {
            index = index.predecessor()
        }
        return (index != self.characters.startIndex) ? index : nil
    }
    
    func firstIndexMatching(predicate: (Character)->Bool) -> String.CharacterView.Index? {
        return self.firstIndexMatching(predicate, from:self.characters.startIndex)
    }
    
    func lastIndexNotMatching(predicate: (Character)->Bool) -> String.CharacterView.Index? {
        return self.lastIndexNotMatching(predicate, to:self.characters.endIndex)
    }
    
    /** Find the first occurrence of a substring in the string */
    func findSubstring(substring: String, from: String.CharacterView.Index) -> String.CharacterView.Index? {
        var index = from
        while index != self.characters.endIndex && !self[index..<self.endIndex].hasPrefix(substring) {
            index = index.successor()
        }
        return (index != self.characters.endIndex) ? index : nil
    }
    
    func findSubstring(substring: String) -> String.CharacterView.Index? { 
        return self.findSubstring(substring, from: self.characters.startIndex)
    }
    
    // these return optionals because, this not being Python, we can.
    /** Return the string with leading whitespace stripped, or nil if empty */
    var lstrip: String? {
        return self.firstIndexMatching{ !$0.isspace }.map { self[$0..<self.endIndex] }
    }
    
    /** Return the string with trailing whitespace stripped, or nil if empty */
    var rstrip: String? {
        return self.lastIndexNotMatching { !$0.isspace }.map { self[self.startIndex..<$0] }
    }
    
    var strip: String? {
        return self.lstrip?.rstrip
    }
    
    /** if the string starts with an escape sequence (%%, with only whitespace before), return what follows, trimmed of whitespace. 
    */
    var textAfterEscape: String? {
        guard let firstNonSpace = (self.firstIndexMatching { !$0.isspace }) else { return nil }
        
        if self[firstNonSpace..<self.endIndex].hasPrefix(TokenLineEscape) {
            let afterEsc = self.firstIndexMatching({!$0.isspace}, from:firstNonSpace.advancedBy(2))
            return afterEsc.flatMap { self[$0..<self.endIndex].rstrip }
        }
        return nil
    }
    
    /** Return the first word and the remainder of the string, if available */
    var firstWordAndRest: (String, String)? {
        guard let firstWordStartIndex = (self.firstIndexMatching { !$0.isspace})
        else { 
            return nil 
        }
        let firstWordEndIndex = (self.firstIndexMatching({$0.isspace}, from:firstWordStartIndex)) ?? self.characters.endIndex
        let restStartIndex = (self.firstIndexMatching({!$0.isspace}, from:firstWordEndIndex)) ?? self.characters.endIndex
        return (self[firstWordStartIndex..<firstWordEndIndex], self[restStartIndex..<self.endIndex])
    }
}

enum TemplateParseError: ErrorType, CustomStringConvertible {
    case InvalidDirective(filename: String, ln: Int, line: String)
    case UnexpectedAtTopLevel(filename: String, ln: Int, line: TemplateLine)
    case UnexpectedInTemplate(filename: String, ln: Int, line: TemplateLine)
    case UnclosedExpression(filename: String, ln: Int, line: String)
    case UnclosedCodeBlock(filename: String, ln: Int)
    
    var description: String {
        switch(self) {
        case InvalidDirective(let fn, let ln, let line): return "\(fn):\(ln): Invalid directive: \(line)"
        case UnexpectedAtTopLevel(let fn, let ln, let line): return "\(fn):\(ln): Unexpected at top level: \(line)"
        case UnexpectedInTemplate(let fn, let ln, let line): return "\(fn):\(ln): Unexpected directive in template: \(line)"
        case UnclosedExpression(let fn, let ln, let line): return "\(fn):\(ln): No closing tag for expression in template: \(line)"
        case UnclosedCodeBlock(let fn, let ln): return "\(fn):\(ln): No closing tag for code block in template"
        }
    }
}

/* A line from the file, as read at parsing time. This is not to be confused with the internal representation of a template.t */
enum TemplateLine: Equatable, CustomStringConvertible {
    case Text(text: String)
    case TemplateStart(spec: String)
    case TemplateEnd
    case ForStart(variable: String, iterable: String)
    case ForEnd
    case IfStart(expression: String)
    case IfElif(expression: String) 
    case IfElse    
    case IfEnd
    
    init(line: String, filename: String, ln: Int) throws {
        if let (word, rest) = line.textAfterEscape?.firstWordAndRest {
            switch(word) {
            case "if": self = IfStart(expression:rest)
            // We allow "elif" or "else if"
            case "elif": self = IfElif(expression:rest)
            case "else": if let (r1, r2) = rest.firstWordAndRest where r1 == "if" {
                self = IfElif(expression:r2)
                } else {
                    self = IfElse
                }
            case "endif": self = IfEnd
            case "for": 
                if let (variable, rest2) = rest.firstWordAndRest, 
                    let (inliteral, iterable) = rest2.firstWordAndRest
                    where inliteral == "in" {
                        self = ForStart(variable: variable, iterable: iterable)
                } else {
                    throw TemplateParseError.InvalidDirective(filename:filename, ln:ln, line: "for \(rest)")
                }
            case "endfor": self = ForEnd
            case "template": self = TemplateStart(spec: rest)
            case "endtemplate": self = TemplateEnd
                
            default: 
                throw TemplateParseError.InvalidDirective(filename:filename, ln:ln, line: word)
            }
        } else {
            self = Text(text:line)
        }
    }
    
    var description: String {
        switch(self) {
        case .Text(let text): return text
        case .TemplateStart(let spec): return "template \(spec)"
        case .TemplateEnd: return "endtemplate"
        case .ForStart(let variable, let iterable): return "for \(variable) in \(iterable)"
        case .ForEnd: return "endfor"
        case .IfStart(let expr): return "if \(expr)"
        case .IfElif(let expr): return "else if \(expr)"
        case .IfElse: return "else"
        case .IfEnd: return "endif"
        }
    }
}

func ==(lhs: TemplateLine, rhs:TemplateLine) -> Bool {
    switch(lhs, rhs) {
    case (.Text(let ltext), .Text(let rtext)): return (ltext == rtext)
    case (.TemplateStart(let lspec), .TemplateStart(let rspec)): return (lspec == rspec)
    case (.TemplateEnd, .TemplateEnd): return true
    case (.ForStart(let lv, let li), .ForStart(let rv, let ri)): return (lv==rv) && (li==ri)
    case (.ForEnd, .ForEnd): return true
    case (.IfStart(let lexp), .IfStart(let rexp)): return (lexp == rexp)
    case (.IfElif(let lexp), .IfElif(let rexp)): return (lexp == rexp)
    case (.IfElse, .IfElse): return true
    case (.IfEnd, .IfEnd): return true
    default: return false
    }
}

/** Return a list of template elements for a line of literal text. This will be a single .Literal, unless 
 the text contains embedded <%= %> / <%=! %> expressions. */
func templateElementsForLiteralLine(line: String, filename: String, ln: Int) throws -> [TemplateElement] {
    if let openStartIndex = line.findSubstring(TokenExprOpen) {
        let openEndIndex = openStartIndex.advancedBy(TokenExprOpen.characters.count)
        let exprUnfiltered = (line.characters[openEndIndex] == "!")
        let exprStartIndex = exprUnfiltered ? openEndIndex.successor() : openEndIndex
        guard let closeStartIndex = line.findSubstring(TokenExprClose, from: exprStartIndex) else {
            throw TemplateParseError.UnclosedExpression(filename:filename, ln:ln, line: line)
        }
        let closeEndIndex = closeStartIndex.advancedBy(TokenExprClose.characters.count)
        
        let initialText:String? = (openStartIndex > line.startIndex) ? line[line.startIndex..<openStartIndex] : nil
        let exprText = (exprStartIndex < closeStartIndex) ? line[exprStartIndex..<closeStartIndex].strip : nil
        let theseElements: [TemplateElement] = [
            initialText.map { TemplateElement.Literal(text: $0) }, 
            exprText.map { TemplateElement.Expression(code: $0, unfiltered: exprUnfiltered ) }
        ].flatMap { $0 }
        
        return theseElements + ((closeEndIndex<line.endIndex) ? try templateElementsForLiteralLine(line[closeEndIndex..<line.endIndex], filename:filename, ln:ln) : [TemplateElement]())
        
    } else {
        return [.Literal(text:line)]
    }
}

func parseTemplate<G: GeneratorType where G.Element == (Int, String)>(inout input: G, filename: String) throws -> Template? {
    
    // scan forward to the TemplateStart
    var l: (Int, String)? = input.next()
    while let (_, line) = l where (line.lstrip?.hasPrefix("//") ?? true) {
        l = input.next()
    }
    guard let (ln, line) = l else { return nil }
    
    let tl = try TemplateLine(line: line, filename:filename, ln: ln)
    guard case let TemplateLine.TemplateStart(spec) = tl else { throw TemplateParseError.UnexpectedAtTopLevel(filename:filename, ln:ln, line: tl) }
    
    var elements: [TemplateElement] = []
    
    l = input.next()
    inTemplateLoop: while let (ln, line) = l {
        
        if line.strip == TokenCodeOpen {
            // consume all lines until the code close token, and build a code block from them
            var codelines: [String] = []
            
            var l2: (Int, String)? = input.next()
            while let (_, line2) = l2 {
                if line2.strip == TokenCodeClose { break }
                codelines.append(line2)                
                l2 = input.next()
            }
            if l2 == nil { throw TemplateParseError.UnclosedCodeBlock(filename:filename, ln:ln) }
            elements.append(.Code(code:codelines.joinWithSeparator("\n")))
        } else {
            // allow %% // line comments
            if !(line.textAfterEscape?.lstrip?.hasPrefix("//") ?? false) {
                let tl2 = try TemplateLine(line: line, filename:filename, ln:ln)
                
                switch(tl2) {
                case .Text(let text): try elements.appendContentsOf(templateElementsForLiteralLine(text, filename:filename, ln:ln))
                case .TemplateStart: throw TemplateParseError.UnexpectedInTemplate(filename:filename, ln:ln, line: tl2)
                case .TemplateEnd: break inTemplateLoop
                case .ForStart(let variable, let iterable): elements.append(.Code(code:"for \(variable) in \(iterable) {"))
                case .ForEnd: elements.append(.Code(code:"}"))
                case .IfStart(let expression): elements.append(.Code(code:"if \(expression) {"))
                case .IfElif(let expression): elements.append(.Code(code:"} else if \(expression) {"))
                case .IfElse: elements.append(.Code(code:"} else {"))
                case .IfEnd: elements.append(.Code(code:"}"))
                }
            }
        }
        l = input.next()
    }
    return Template(spec: spec, elements: simplifyTemplateElements(elements))
}

func parseTemplates<S: SequenceType where S.Generator.Element == String>(input: S, filename: String) throws -> [Template] {
    var g = input.generate()
    var line: Int = 1
    var r = [Template]()
    var g2 = anyGenerator { g.next().map { (line++, $0) } }
    
    var parsed = try parseTemplate(&g2, filename: filename)
    while let template = parsed {
        r.append(template)
        parsed = try parseTemplate(&g2, filename: filename)
    }
    return r
}
