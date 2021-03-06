//  swiftemplate - a compile-time template system for Swift
//  https://github.com/andrewcb/swiftemplate/
//  Created by acb on 19/02/2016.
//  Licenced under the Apache Licence.

import Foundation
#if os(Linux)
import Glibc
#else
import Darwin
#endif

// parse the command-line arguments here

var arggen = Process.arguments.generate()
let execName = arggen.next()

var infiles = [String]()
var outputName: String?
var htmlQuoteExpressions = true

while let arg = arggen.next() {
    switch(arg) {
    case "-o": outputName = arggen.next()
    case "--no-htmlquote": htmlQuoteExpressions = false
    default: infiles.append(arg)
    }
}

let options = CodeGenerationOptions(htmlQuoteExpressions:htmlQuoteExpressions)

struct Error: ErrorType, CustomStringConvertible {
    let message: String
    var description:String { return message }
}

func parseFile(path: String) throws -> [Template] {
    let fd = open(path, O_RDONLY)
    guard (fd >= 0) else { throw Error(message: "Cannot open \(path)") }
    defer { close(fd) }
    var stb = stat()
    if (fstat(fd, &stb) != 0) { throw Error(message: "Cannot stat \(path)") }
    let size = Int(stb.st_size)
    var buf = [UInt8](count: size+1, repeatedValue: 0)
    if read(fd, &buf, size)<size { throw Error(message: "Error reading \(path)") }
    if let contents = String.fromCString(UnsafePointer(buf)) {
        return try parseTemplates(contents.characters.split("\n", allowEmptySlices:true).map { String($0) }, filename:path)
    } else {
        throw Error(message:"Contents of \(path) are not a valid string")
    }
}

if infiles.isEmpty {
    print("usage: \(execName) [-o output] [--no-htmlquote] input ...")
} else {
    do {
        let templates = try infiles.flatMap(parseFile)
        
        let outfd = outputName.map { open($0, O_CREAT | O_WRONLY | O_TRUNC, 0o644) } ?? STDOUT_FILENO
        if outfd<0 {
            throw Error(message:"Unable to open \(outputName!) for writing")
        }
        defer { close(outfd) }
        for template in templates {
            let code = template.asCode(options)
            let bytes = [UInt8](code.utf8)
            
            let written = write(outfd, UnsafePointer(bytes), bytes.count)
            if written < bytes.count {
                throw Error(message:"Error writing to file")
            }
        }
    } catch {
        print(error)
    }
}
