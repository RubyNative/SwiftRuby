//
//  String.swift
//  RubyNative
//
//  Created by John Holdsworth on 26/09/2015.
//  Copyright © 2015 John Holdsworth. All rights reserved.
//
//  $Id: //depot/SwiftRuby/String.swift#2 $
//
//  Repo: https://github.com/RubyNative/SwiftRuby
//
//  See: http://ruby-doc.org/core-2.2.3/String.html
//

import Foundation

public var STRING_ENCODING = NSUTF8StringEncoding
public let ALTERNATE_ENCODING = NSISOLatin1StringEncoding

public protocol to_s_protocol: to_a_protocol {

    var to_s: String { get }

}

public protocol to_c_protocol {

    var to_c: [CChar] { get }
    
}

extension String: to_s_protocol, to_a_protocol, to_d_protocol, to_c_protocol {

    public var to_s: String {
        return self
    }

    public var to_a: [String] {
        return [self]
    }

    public var to_i: Int {
        if let val = Int( self ) {
            return val
        }
        let dummy = -99999999
        RKLog( "Unable to convert \(self) to Int. Returning \(dummy)" )
        return dummy
    }

    public var to_f: Double {
        if let val = Double( self ) {
            return val
        }
        let dummy = -99999999.0
        RKLog( "Unable to convert \(self) to Doubleb. Returning \(dummy)" )
        return dummy
    }

    public var to_c: [CChar] {
        return cStringUsingEncoding( STRING_ENCODING ) ??
            "UNLIKELY ERROR ENCODING TO UTF8".cStringUsingEncoding( STRING_ENCODING )!
    }

    public var to_d: Data {
        return Data( array: self.to_c )
    }

    public subscript ( i: Int ) -> String {
        return self[i..<i+1]
    }

    public subscript ( r: Range<Int> ) -> String {
        return substringWithRange( startIndex.advancedBy( r.startIndex )..<startIndex.advancedBy( r.endIndex ) )
    }

    public func characterAtIndex( i: Int ) -> Int {
        if let char = self[i].unicodeScalars.first {
            return Int(char.value)
        }
        RKLog( "No character available in string '\(self)' returning nul char" )
        return 0
    }

    public var ord: Int {
        return characterAtIndex(0)
    }

}
