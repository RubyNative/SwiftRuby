//
//  Data.swift
//  RubyNative
//
//  Created by John Holdsworth on 26/09/2015.
//  Copyright © 2015 John Holdsworth. All rights reserved.
//
//  $Id: //depot/RubyNative/Data.swift#13 $
//
//  Repo: https://github.com/RubyNative/RubyNative
//
//  See: http://ruby-doc.org/core-2.2.3/Data.html
//

import Foundation

public protocol to_d_protocol {

    var to_d: Data { get }
    
}

public class Data: Object, to_s_protocol, to_d_protocol, to_c_protocol {

    public var bytes: UnsafeMutablePointer<Int8>

    public var length = 0 {
        didSet {
            if length > capacity {
                RNLog( "Data length \(length) > capacity \(capacity)" )
                fatalError()
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
        self.length = length
        self.bytes = bytes
        super.init()
    }

    public convenience init( capacity: Int? = 0 ) {
        let capacity = capacity ?? 10 * 1024
        self.init( bytes: UnsafeMutablePointer<Int8>( malloc( capacity+1 ) ) )
        self.capacity = capacity
    }

    public var to_c: [CChar] {
        var data = [CChar]( count: capacity+1, repeatedValue: 0 )
        memcpy( &data, bytes, capacity+1 )
        return data
    }

    public var to_d: Data {
        return self
    }

    public var to_s: String {
        return String( UTF8String: bytes )!
    }

    public var to_a: [String] {
        return [to_s]
    }

    public var data: NSData {
        let shouldFree = capacity != 0
        capacity = 0
        return NSData( bytesNoCopy: bytes, length: length, freeWhenDone: shouldFree )
    }

    deinit {
        if capacity != 0 {
            free( bytes )
        }
    }

}
