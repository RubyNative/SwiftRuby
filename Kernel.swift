//
//  Kernel.swift
//  SwiftRuby
//
//  Created by John Holdsworth on 27/09/2015.
//  Copyright © 2015 John Holdsworth. All rights reserved.
//
//  $Id: //depot/SwiftRuby/Kernel.swift#14 $
//
//  Repo: https://github.com/RubyNative/SwiftRuby
//
//  See: http://ruby-doc.org/core-2.2.3/Kernel.html
//

import Foundation

@_silgen_name("_try")
public func _try( _ tryBlock: () -> () )

@_silgen_name("_catch")
public func _catch( _ catchBlock: (_ ex: NSException) -> () )

@_silgen_name("_throw")
public func _throw( _ ex: NSException )

public func U<T>( _ toUnwrap: T?, name: String? = nil, file: StaticString = #file, line: UInt = #line ) -> T {
    if toUnwrap == nil {
        let msg = name != nil ? "Forced unwrap of \(name) fail" : "Forced unwrap fail"
        _throw( NSException( name: NSExceptionName(rawValue: msg), reason: "\(file), \(line)", userInfo: ["msg": msg, "file": String(describing: file), "line": "\(line)"] ) )
    }
    return toUnwrap!
}

public enum WarningDisposition {
    case ignore, warn, `throw`, fatal
}

public var WARNING_DISPOSITION: WarningDisposition = .warn
public var LAST_WARNING: String?

public func SRLog( _ msg: String, file: StaticString = #file, line: UInt = #line ) {
    LAST_WARNING = msg+" at \(file)#\(line)"
    if WARNING_DISPOSITION == .throw {
        _throw( NSException( name: NSExceptionName(rawValue: msg), reason: LAST_WARNING, userInfo: ["msg": msg, "file": String(describing: file), "line": "\(line)"] ) )
    }
    if WARNING_DISPOSITION != .ignore {
        STDERR.print( "SwiftRuby: \(U(LAST_WARNING))\n" )
    }
    if WARNING_DISPOSITION == .fatal {
        fatalError()
    }
}

public func SRError( _ msg: String, file: StaticString, line: UInt ) {
    let error = String( validatingUTF8: strerror( errno ) ) ?? "Undecodable strerror"
    SRLog( msg+": \(error)", file: file, line: line )
}

public func SRFatal( _ msg: String, file: StaticString, line: UInt ) {
    SRLog( msg, file: file, line: line )
    fatalError()
}

public func SRNotImplemented( _ what: String, file: StaticString, line: UInt ) {
    SRFatal( "\(what) not implemented", file: file, line: line )
}

@_silgen_name("execArgv")
func execArgv( _ executable: NSString, _ argv: NSArray )

@_silgen_name("spawnArgv")
func spawnArgv( _ executable: NSString, _ argv: NSArray ) -> pid_t

open class Kernel: RubyObject {

    open class func open( _ path: string_like, _ mode: string_like = "r", _ perm: Int = 0o644, file: StaticString = #file, line: UInt = #line ) -> IO? {
        let path = path.to_s
        let index1 = path.characters.index(path.startIndex, offsetBy: 1)

        if path.substring( to: index1 ) == "|" {
            return IO.popen( path.substring( from: index1 ), mode, file: file, line: line )
        }
        else {
            return File.open( path, mode, perm, file: file, line: line )
        }
    }

    open class func exec( _ command: string_like ) {
        exec( "/bin/bash", ["-c", command.to_s] )
    }

    open class func exec( _ executable: string_like, _ arguments: array_like ) {
        exec( [executable.to_s, executable.to_s], arguments.to_a )
    }

    open class func exec( _ executable: array_like, _ arguments: array_like ) {
        execArgv( executable.to_a[0].to_s as NSString, [executable.to_a[1]]+arguments.to_a as NSArray )
    }

    open class func spawn( _ command: string_like ) -> Int {
        return Int(spawnArgv( "/bin/bash", ["/bin/bash", "-c", command.to_s] ))
    }

}
