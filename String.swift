//
//  String.swift
//  RubyNative
//
//  Created by John Holdsworth on 26/09/2015.
//  Copyright © 2015 John Holdsworth. All rights reserved.
//
//  $Id: //depot/RubyNative/String.swift#10 $
//
//  Repo: https://github.com/RubyNative/RubyNative
//
//  See: http://ruby-doc.org/core-2.2.3/String.html
//

import Foundation

public protocol to_s_protocol: to_a_protocol {

    var to_s: String { get }
    var to_a: [String] { get }

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
        RNLog( "Unable to convert \(self) to Int. Returning \(dummy)" )
        return dummy
    }

    public var to_f: Double {
        if let val = Double( self ) {
            return val
        }
        let dummy = -99999999.0
        RNLog( "Unable to convert \(self) to Doubleb. Returning \(dummy)" )
        return dummy
    }

    public var to_c: [CChar] {
        return cStringUsingEncoding( NSUTF8StringEncoding ) ??
            "UNLIKELY ERROR ENCODING TO UTF8".cStringUsingEncoding( NSUTF8StringEncoding )!
    }

    public var to_d: Data {
        var array = self.to_c
        return Data( bytes: &array, length: Int(strlen(array)) ) //// avoids extra copy but relies on autorelease scope..
//        let length = Int(strlen( &array ))
//        let data = Data( capacity: length )
//        memcpy( data.bytes, array, length+1 )
//        data.length = length
//        return data
    }

    public subscript ( i: Int ) -> String {
        return self[i..<i+1]
    }

    public subscript ( r: Range<Int> ) -> String {
        return substringWithRange(startIndex.advancedBy(r.startIndex)..<startIndex.advancedBy(r.endIndex))
    }

}
