//
//  Data.swift
//  SwiftRuby
//
//  Created by John Holdsworth on 26/09/2015.
//  Copyright © 2015 John Holdsworth. All rights reserved.
//
//  $Id: //depot/SwiftRuby/Data.swift#8 $
//
//  Repo: https://github.com/RubyNative/SwiftRuby
//
//  See: http://ruby-doc.org/core-2.2.3/Data.html
//

import Darwin

public protocol data_like {

    var to_d: Data { get }
    
}

public func ==(lhs: Data, rhs: Data) -> Bool {
    return lhs.length == rhs.length && memcmp( lhs.bytes, rhs.bytes, lhs.length ) == 0
}

public class Data: RubyObject, string_like, array_like, char_like, data_like {

    public var bytes: UnsafeMutablePointer<Int8>

    public var length = 0 {
        didSet {
            if length > capacity {
                SRFatal( "Data length \(length) > capacity \(capacity)", file: __FILE__, line: __LINE__ )
            }
            bytes[length] = 0
        }
    }

    public var capacity = 0 {
        didSet {
            bytes = UnsafeMutablePointer<Int8>( realloc( bytes, capacity+1 ) )
        }
    }

    public init( bytes: UnsafeMutablePointer<Int8>, length: Int = 0 ) {
        self.bytes = bytes
        self.length = length
        super.init()
    }

    public convenience init( capacity: Int? = 0 ) {
        let capacity = capacity ?? 10 * 1024
        self.init( bytes: UnsafeMutablePointer<Int8>( malloc( capacity+1 ) ) )
        self.capacity = capacity
    }

    public convenience init( array: [CChar] ) {
        let alen = array.count
        self.init( capacity: alen )
        memcpy( bytes, array, alen )
        length = alen-1
    }

    public func append( extra: data_like ) -> Int {
        let extra = extra.to_d
        let required = length + extra.length
        if required + 1 > capacity {
            capacity += max( required - capacity, 10_000 )
        }
        memcpy( bytes+length, extra.bytes, extra.length )
        length += extra.length
        return extra.length
    }

    public var to_a: [String] {
        return [to_s]
    }

    public var to_c: [CChar] {
        var data = [CChar]( count: length+1, repeatedValue: 0 ) ///
        memcpy( &data, bytes, data.count )
        return data
    }

    public var to_d: Data {
        return self
    }

    public var to_s: String {
        if let string = String( CString: bytes, encoding: STRING_ENCODING ) {
            return string
        }

        SRLog( "Data.to_s: Could not decode string from input" )
        return U(String( CString: bytes, encoding: FALLBACK_INPUT_ENCODING ))
    }

    deinit {
        if capacity != 0 {
            free( bytes )
        }
    }

}
