//
//  Object.swift
//  SwiftRuby
//
//  Created by John Holdsworth on 26/09/2015.
//  Copyright © 2015 John Holdsworth. All rights reserved.
//
//  $Id: //depot/SwiftRuby/Object.swift#11 $
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

public let ENV = ENVProxy()

public class ENVProxy {

    public subscript( key: string_like ) -> String? {
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
