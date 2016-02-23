//
//  main.swift
//  swiftemplate
//
//  Created by acb on 19/02/2016.
//  Copyright © 2016 Kineticfactory. All rights reserved.
//

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

while let arg = arggen.next() {
    switch(arg) {
    case "-o": outputName = arggen.next()
    default: infiles.append(arg)
    }
}

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
        return try parseTemplates(contents.characters.split("\n").map { String($0) })
    } else {
        throw Error(message:"Contents of \(path) are not a valid string")
    }
    
}

if infiles.isEmpty {
    print("usage: \(execName) [-o output] input ...")
} else {
    do {
        let templates = try infiles.flatMap(parseFile)
        
        let outfd = outputName.map { open($0, O_CREAT, 0o644) } ?? STDOUT_FILENO
        if outfd<0 {
            throw Error(message:"unable to open \(outputName!) for writing")
        }
        //defer { close(outfd) }
        for template in templates {
            let code = template.asCode
            guard let bytes = code.cStringUsingEncoding(NSUTF8StringEncoding) else {
                throw Error(message:"unable to encode template to UTF-8?!")
            }
            let written = write(outfd, UnsafePointer(bytes), bytes.count)
            if written < bytes.count {
                throw Error(message:"error writing to file")
            }
            
        }
        
    } catch {
        print("An error occurred: \(error)")
    }
}