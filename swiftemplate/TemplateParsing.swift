//
//  TemplateParsing.swift
//  swiftemplate
//
//  Created by acb on 19/02/2016.
//  Copyright © 2016 Kineticfactory. All rights reserved.
//

import Foundation

extension Character {
    var isspace: Bool {
        return self == " " || self == "\t"
    }
}

extension String {
    func firstIndexMatching(predicate: (Character)->Bool, from: String.CharacterView.Index) -> String.CharacterView.Index? {
        var index = from
        while index != self.characters.endIndex && !predicate(self.characters[index]) {
            index = index.successor()
        }
        return (index != self.characters.endIndex) ? index : nil
    }
    
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
    
    // these return optionals because, this not being Python, we can.
    var lstrip: String? {
        return self.firstIndexMatching{ !$0.isspace }.map { self.substringFromIndex($0) }
    }
    
    var rstrip: String? {
        return self.lastIndexNotMatching { !$0.isspace }.map { self.substringToIndex($0) }
    }
    
    var strip: String? {
        return self.lstrip?.rstrip
    }
    
    /** if the string starts with an escape sequence (%%, with only whitespace before), return what follows, trimmed of whitespace. 
    */
    var textAfterEscape: String? {
        guard let firstNonSpace = (self.firstIndexMatching { !$0.isspace }) else { return nil }
        
        if self.substringFromIndex(firstNonSpace).hasPrefix("%%") {
            let afterEsc = self.firstIndexMatching({!$0.isspace}, from:firstNonSpace.advancedBy(2))
            return afterEsc.flatMap { self.substringFromIndex($0).rstrip }
        }
        return nil
    }
    
    var firstWordAndRest: (String, String)? {
        guard let firstWordStartIndex = (self.firstIndexMatching { !$0.isspace})
        else { 
            return nil 
        }
        let firstWordEndIndex = (self.firstIndexMatching({$0.isspace}, from:firstWordStartIndex)) ?? self.characters.endIndex
        let restStartIndex = (self.firstIndexMatching({!$0.isspace}, from:firstWordEndIndex)) ?? self.characters.endIndex

        return (self.substringWithRange(firstWordStartIndex..<firstWordEndIndex), self.substringFromIndex(restStartIndex))
    }
}

enum TemplateParseError: ErrorType {
    case InvalidDirective(line: String)
    case UnexpectedAtTopLevel(line: TemplateLine)
    case UnexpectedInTemplate(line: TemplateLine)
}

/* A line from the file, as read at parsing time. This is not to be confused with the internal representation of a template.t */
enum TemplateLine: Equatable {
    
    case Text(text: String)
    case TemplateStart(spec: String)
    case TemplateEnd
    case ForStart(variable: String, iterable: String)
    case ForEnd
    case IfStart(expression: String)
    case IfElif(expression: String) 
    case IfElse    
    case IfEnd
    
    init(line: String) throws {
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
                    throw TemplateParseError.InvalidDirective(line: rest)
                }
            case "endfor": self = ForEnd
            case "template": self = TemplateStart(spec: rest)
            case "endtemplate": self = TemplateEnd
                
            default: 
                throw TemplateParseError.InvalidDirective(line: rest)
            }
        } else {
            self = Text(text:line)
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


struct TemplateParser<S: SequenceType where S.Generator.Element == String> {
    var input: S
}

func parseTemplate<S: SequenceType where S.Generator.Element == String>(input: S) throws -> Template? {
    var g = input.generate()
    
    // scan forward to the TemplateStart
    
    var l: String? = g.next()
    
    while l != nil && l! == "" {
        l = g.next()
    }
    if l == nil { return nil }
    
    let tl = try TemplateLine(line: l!)
    guard case let TemplateLine.TemplateStart(spec) = tl else { throw TemplateParseError.UnexpectedAtTopLevel(line: tl) }
    
    var elements: [TemplateElement] = []
    
    l = g.next()
    
    while l != nil {
        
        let tl2 = try TemplateLine(line: l!)
        
        switch(tl2) {
        case .Text(let text): elements.append(.Literal(text:text))
        case .TemplateStart: throw TemplateParseError.UnexpectedInTemplate(line: tl2)
        case .TemplateEnd: break
        case .ForStart(let variable, let iterable): elements.append(.Code(code:"for \(variable) in \(iterable) {"))
        case .ForEnd: elements.append(.Code(code:"}"))
        case .IfStart(let expression): elements.append(.Code(code:"if \(expression) {"))
        case .IfElif(let expression): elements.append(.Code(code:"} else if \(expression) {"))
        case .IfElse: elements.append(.Code(code:"} else {"))
        case .IfEnd: elements.append(.Code(code:"}"))
        }
        
        l = g.next()
    }
    
    return Template(spec: spec, elements: simplifyTemplateElements(elements))
}

