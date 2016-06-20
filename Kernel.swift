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
public func _try( tryBlock: () -> () )

@_silgen_name("_catch")
public func _catch( catchBlock: (ex: NSException) -> () )

@_silgen_name("_throw")
public func _throw( ex: NSException )

public func U<T>( toUnwrap: T?, name: String? = nil, file: StaticString = #file, line: UInt = #line ) -> T {
    if toUnwrap == nil {
        let msg = name != nil ? "Forced unwrap of \(name) fail" : "Forced unwrap fail"
        _throw( NSException( name: msg, reason: "\(file), \(line)", userInfo: ["msg": msg, "file": String(file), "line": "\(line)"] ) )
    }
    return toUnwrap!
}

public enum WarningDisposition {
    case Ignore, Warn, Throw, Fatal
}

public var WARNING_DISPOSITION: WarningDisposition = .Warn
public var LAST_WARNING: String?

public func SRLog( msg: String, file: StaticString = #file, line: UInt = #line ) {
    LAST_WARNING = msg+" at \(file)#\(line)"
    if WARNING_DISPOSITION == .Throw {
        _throw( NSException( name: msg, reason: LAST_WARNING, userInfo: ["msg": msg, "file": String(file), "line": "\(line)"] ) )
    }
    if WARNING_DISPOSITION != .Ignore {
        STDERR.print( "SwiftRuby: \(U(LAST_WARNING))\n" )
    }
    if WARNING_DISPOSITION == .Fatal {
        fatalError()
    }
}

public func SRError( msg: String, file: StaticString, line: UInt ) {
    let error = String( UTF8String: strerror( errno ) ) ?? "Undecodable strerror"
    SRLog( msg+": \(error)", file: file, line: line )
}

public func SRFatal( msg: String, file: StaticString, line: UInt ) {
    SRLog( msg, file: file, line: line )
    fatalError()
}

public func SRNotImplemented( what: String, file: StaticString, line: UInt ) {
    SRFatal( "\(what) not implemented", file: file, line: line )
}

@_silgen_name("execArgv")
func execArgv( executable: NSString, _ argv: NSArray )

@_silgen_name("spawnArgv")
func spawnArgv( executable: NSString, _ argv: NSArray ) -> pid_t

public class Kernel: RubyObject {

    public class func open( path: string_like, _ mode: string_like = "r", _ perm: Int = 0o644, file: StaticString = #file, line: UInt = #line ) -> IO? {
        let path = path.to_s
        let index1 = path.startIndex.advancedBy(1)

        if path.substringToIndex( index1 ) == "|" {
            return IO.popen( path.substringFromIndex( index1 ), mode, file: file, line: line )
        }
        else {
            return File.open( path, mode, perm, file: file, line: line )
        }
    }

    public class func exec( command: string_like ) {
        exec( "/bin/bash", ["-c", command.to_s] )
    }

    public class func exec( executable: string_like, _ arguments: array_like ) {
        exec( [executable.to_s, executable.to_s], arguments.to_a )
    }

    public class func exec( executable: array_like, _ arguments: array_like ) {
        execArgv( executable.to_a[0].to_s, [executable.to_a[1]]+arguments.to_a )
    }

    public class func spawn( command: string_like ) -> Int {
        return Int(spawnArgv( "/bin/bash", ["/bin/bash", "-c", command.to_s] ))
    }

}
