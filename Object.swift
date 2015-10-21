//
//  Object.swift
//  SwiftRuby
//
//  Created by John Holdsworth on 26/09/2015.
//  Copyright © 2015 John Holdsworth. All rights reserved.
//
//  $Id: //depot/SwiftRuby/Object.swift#8 $
//
//  Repo: https://github.com/RubyNative/SwiftRuby
//
//  See: http://ruby-doc.org/core-2.2.3/Object.html
//

import Foundation

public let ARGV = Process.arguments

public let STDIN = IO( what: "stdin", unixFILE: stdin )
public let STDOUT = IO( what: "stdout", unixFILE: stdout )
public let STDERR = IO( what: "stderr", unixFILE: stderr )

public enum WarningDisposition {
    case Ignore, Warn, Throw, Fatal
}

public var WARNING_DISPOSITION: WarningDisposition = .Warn
public var LAST_WARNING: String?

public func SRLog( msg: String, file: StaticString = __FILE__, line: UInt = __LINE__ ) {
    LAST_WARNING = msg+" at \(file)#\(line)"
    if WARNING_DISPOSITION == .Throw {
        _throw( NSException( name: msg, reason: LAST_WARNING, userInfo: ["msg": msg, "file": String(file), "line": "\(line)"] ) )
    }
    if WARNING_DISPOSITION != .Ignore {
        STDERR.print( "SwiftRuby: \(LAST_WARNING!)\n" )
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

public let ENV = ENVProxy()

public class ENVProxy {

    public subscript( key: to_s_protocol ) -> String? {
        get {
            let val = getenv( key.to_s )
            return val != nil ? String( UTF8String: val ) ?? "Value not UTF8" : nil
        }
        set {
            if newValue != nil {
                setenv( key.to_s, newValue!, 1 )
            }
            else {
                unsetenv( key.to_s )
            }
        }
    }

}

@asmname ("instanceVariablesForClass")
func instanceVariablesForClass( cls: AnyClass, _ ivarNames: NSMutableArray ) -> NSArray

@asmname ("methodSymbolsForClass")
func methodSymbolsForClass( cls: AnyClass ) -> NSArray

public class RubyObject {

    public var hash: fixnum {
        return unsafeBitCast( self, Int.self )
    }

    public var instance_variables: [String] {
        return instanceVariablesForClass( self.dynamicType, NSMutableArray() ) as! [String]
    }

    public var methods: [String] {
        return methodSymbolsForClass( self.dynamicType ).map { _stdlib_demangleName( String( $0 ) ) }
    }

}

@asmname("_try")
public func _try( tryBlock: () -> () )

@asmname("_catch")
public func _catch( catchBlock: (ex: NSException) -> () )

@asmname("_throw")
public func _throw( ex: NSException )

public func U<T>( toUnwrap: T?, name: String? = nil, file: StaticString = __FILE__, line: UInt = __LINE__ ) -> T {
    if toUnwrap == nil {
        let msg = name != nil ? "Forced unwrap of \(name) fail" : "Forced unwrap fail"
        _throw( NSException( name: msg, reason: "\(file), \(line)", userInfo: ["msg": msg, "file": String(file), "line": "\(line)"] ) )
    }
    return toUnwrap!
}
