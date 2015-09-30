//
//  String.swift
//  RubyNative
//
//  Created by John Holdsworth on 26/09/2015.
//  Copyright © 2015 John Holdsworth. All rights reserved.
//
//  $Id: //depot/RubyNative/String.swift#6 $
//
//  Repo: https://github.com/RubyNative/RubyNative
//
//  See: http://ruby-doc.org/core-2.2.3/String.html
//

import Foundation

public protocol to_s_protocol {

    var to_s: String { get }

}

public protocol to_c_protocol {

    var to_c: [CChar] { get }
    
}

extension String: to_s_protocol, to_d_protocol, to_c_protocol {

    public var to_s: String {
        return self
    }

    public var to_i: Int {
        return Int( self )!
    }

    public var to_f: Double {
        return Double( self )!
    }

    public var to_c: [CChar] {
        return self.cStringUsingEncoding(NSUTF8StringEncoding)!
    }

    public var to_d: Data {
        var array = self.to_c
        return Data( bytes: &array, length: Int(strlen(array)) ) //// avoids copy but relies on autorelease scope..
        let length = Int(strlen( &array ))
        let data = Data( capacity: length )
        memcpy( data.bytes, array, length+1 )
        data.length = length
        return data
    }

    public subscript ( i: Int ) -> String {
        let idx = self.startIndex.advancedBy(i)
        return self.substringWithRange(idx..<idx.advancedBy(1))
    }

    public subscript ( r: Range<Int> ) -> String {
        get {
            return self.substringWithRange(self.startIndex.advancedBy(r.startIndex)..<self.startIndex.advancedBy(r.endIndex))
        }
    }

}
