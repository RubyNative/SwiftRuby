//
//  Object.swift
//  RubyNative
//
//  Created by John Holdsworth on 26/09/2015.
//  Copyright © 2015 John Holdsworth. All rights reserved.
//
//  $Id: //depot/RubyNative/Object.swift#13 $
//
//  Repo: https://github.com/RubyNative/RubyNative
//
//  See: http://ruby-doc.org/core-2.2.3/Object.html
//

import Foundation

public let ARGV = Process.arguments

public let STDIN = IO( what: "stdin", filePointer: stdin )!
public let STDOUT = IO( what: "stdout", filePointer: stdout )!
public let STDERR = IO( what: "stderr", filePointer: stderr )!

public func RNLog( msg: String ) {
    STDERR.print( "RubyNative: "+msg )
}

public let ENV = ENVProxy()

public class ENVProxy {

    public subscript( key: to_s_protocol ) -> String? {
        get {
            let val = getenv( key.to_s )
            return val != nil ? String( UTF8String: val ) : nil
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
        var out = [String]()
        for symName in methodSymbolsForClass( self.dynamicType ) {
            out.append( _stdlib_demangleName( symName as! String ) )
        }
        return out
    }

}
