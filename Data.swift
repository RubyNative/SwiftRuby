//
//  Data.swift
//  RubyNative
//
//  Created by John Holdsworth on 26/09/2015.
//  Copyright © 2015 John Holdsworth. All rights reserved.
//
//  $Id: //depot/SwiftRuby/Data.swift#2 $
//
//  Repo: https://github.com/RubyNative/SwiftRuby
//
//  See: http://ruby-doc.org/core-2.2.3/Data.html
//

import Darwin

public protocol to_d_protocol {

    var to_d: Data { get }
    
}

public class Data: RubyObject, to_s_protocol, to_d_protocol, to_c_protocol, to_a_protocol {

    public var bytes: UnsafeMutablePointer<Int8>

    public var length = 0 {
        didSet {
            if length > capacity {
                RKFatal( "Data length \(length) > capacity \(capacity)", file: __FILE__, line: __LINE__ )
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

    public func append( extra: to_d_protocol ) -> Int {
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
        var data = [CChar]( count: length+1, repeatedValue: 0 )
        memcpy( &data, bytes, length+1 )
        return data
    }

    public var to_d: Data {
        return self
    }

    public var to_s: String {
        if let string = String( CString: bytes, encoding: STRING_ENCODING ) {
            return string
        }
        RKLog( "Data.to_s: Could not create string from UTF8" )
        return String( CString: bytes, encoding: ALTERNATE_ENCODING )!
    }

    deinit {
        if capacity != 0 {
            free( bytes )
        }
    }

}
