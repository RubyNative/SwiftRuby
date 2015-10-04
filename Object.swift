//
//  Object.swift
//  RubyNative
//
//  Created by John Holdsworth on 26/09/2015.
//  Copyright © 2015 John Holdsworth. All rights reserved.
//
//  $Id: //depot/RubyKit/Object.swift#5 $
//
//  Repo: https://github.com/RubyNative/RubyKit
//
//  See: http://ruby-doc.org/core-2.2.3/Object.html
//

import Foundation

public let ARGV = Process.arguments

public let STDIN = IO( what: "stdin", unixFILE: stdin )
public let STDOUT = IO( what: "stdout", unixFILE: stdout )
public let STDERR = IO( what: "stderr", unixFILE: stderr )

public enum WarningDisposition {
    case Ignore, Warn, Fatal
}

public var WARNING_DISPOSITION: WarningDisposition = .Warn

public func RKLog( msg: String, file: String = __FILE__, line: Int = __LINE__ ) {
    if WARNING_DISPOSITION != .Ignore {
        STDERR.print( "RubyNative: "+msg+" at \(file)#\(line)\n" )
    }
    if WARNING_DISPOSITION == .Fatal {
        fatalError()
    }
}

public func RKError( msg: String, file: String = __FILE__, line: Int = __LINE__ ) {
    let error = String( UTF8String: strerror( errno ) ) ?? "Unavailable error"
    RKLog( msg+": \(error)", file: file, line: line )
}

public func RKFatal( msg: String, file: String = __FILE__, line: Int = __LINE__ ) {
    RKLog( msg, file: file, line: line )
    fatalError()
}

public func RKNotImplemented( what: String, file: String = __FILE__, line: Int = __LINE__ ) {
    RKFatal( "\(what) not implemented", file: file, line: line )
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

@asmname("instanceVariablesForClass")
func instanceVariablesForClass( cls: AnyClass, _: NSMutableArray ) -> NSArray
@asmname("methodSymbolsForClass")
func methodSymbolsForClass( cls: AnyClass ) -> NSArray

public class Object: NSObject {

    public var instance_variables: [String] {
        return instanceVariablesForClass( self.dynamicType, NSMutableArray() ) as! [String]
    }

    public var methods: [String] {
        return methodSymbolsForClass( self.dynamicType ).map { _stdlib_demangleName( $0 as! String ) }
    }

}
