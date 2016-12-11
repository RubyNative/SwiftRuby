//
//  Object.swift
//  SwiftRuby
//
//  Created by John Holdsworth on 26/09/2015.
//  Copyright © 2015 John Holdsworth. All rights reserved.
//
//  $Id: //depot/SwiftRuby/Object.swift#14 $
//
//  Repo: https://github.com/RubyNative/SwiftRuby
//
//  See: http://ruby-doc.org/core-2.2.3/Object.html
//

import Foundation

public let ARGV = CommandLine.arguments

public let STDIN = IO( what: "stdin", unixFILE: stdin )
public let STDOUT = IO( what: "stdout", unixFILE: stdout )
public let STDERR = IO( what: "stderr", unixFILE: stderr )

public let ENV = ENVProxy()

open class ENVProxy {

    open subscript( key: string_like ) -> String? {
        get {
            let val = getenv( key.to_s )
            return val != nil ? String( validatingUTF8: val! ) ?? "Value not UTF8" : nil
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

@_silgen_name("instanceVariablesForClass")
func instanceVariablesForClass( _ cls: AnyClass, _ ivarNames: NSMutableArray ) -> [String]

@_silgen_name("methodSymbolsForClass")
func methodSymbolsForClass( _ cls: AnyClass ) -> [String]

open class RubyObject {

    open var hash: fixnum {
        return unsafeBitCast( self, to: Int.self )
    }

    open var instance_variables: [String] {
        return instanceVariablesForClass( type(of: self), NSMutableArray() ) 
    }

    open var methods: [String] {
        return methodSymbolsForClass( type(of: self) ).map { _stdlib_demangleName( String( $0 ) ) }
    }

}

// not public in Swift3

@_silgen_name("swift_demangle")
public
func _stdlib_demangleImpl(
    _ mangledName: UnsafePointer<CChar>?,
    mangledNameLength: UInt,
    outputBuffer: UnsafeMutablePointer<UInt8>?,
    outputBufferSize: UnsafeMutablePointer<UInt>?,
    flags: UInt32
    ) -> UnsafeMutablePointer<CChar>?


func _stdlib_demangleName(_ mangledName: String) -> String {
    return mangledName.utf8CString.withUnsafeBufferPointer {
        (mangledNameUTF8) in

        let demangledNamePtr = _stdlib_demangleImpl(
            mangledNameUTF8.baseAddress,
            mangledNameLength: UInt(mangledNameUTF8.count - 1),
            outputBuffer: nil,
            outputBufferSize: nil,
            flags: 0)

        if let demangledNamePtr = demangledNamePtr {
            let demangledName = String(cString: demangledNamePtr)
            free(demangledNamePtr)
            return demangledName
        }
        return mangledName
    }
}

