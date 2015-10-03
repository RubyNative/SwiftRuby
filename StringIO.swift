//
//  StringIO.swift
//  RubyNative
//
//  Created by John Holdsworth on 28/09/2015.
//  Copyright © 2015 John Holdsworth. All rights reserved.
//
//  $Id: //depot/RubyKit/StringIO.swift#4 $
//
//  Repo: https://github.com/RubyNative/RubyKit
//
//  See: http://ruby-doc.org/stdlib-2.2.3/libdoc/stringio/rdoc/StringIO.html
//

import Foundation

public var LINE_SEPARATOR = "\n"

public class StringIO: IO {

    public let data: Data
    public var offset = 0

    public override var pos: Int {
        get {
            return offset
        }
        set {
            offset = newValue
        }
    }

    public init( _ string: to_d_protocol = "", file: String = __FILE__, line: Int = __LINE__ ) {
        data = string.to_d
        super.init( what: nil, unixFILE: nil )
    }

    public class func new( string: to_d_protocol, _ mode: to_s_protocol = "r", _ perm: Int? = nil, file: String = __FILE__, line: Int = __LINE__ ) -> StringIO {
        return StringIO( string, file: file, line: line )
    }

    public class func open( string: to_d_protocol, _ mode: to_s_protocol = "r", _ perm: Int? = nil, file: String = __FILE__, line: Int = __LINE__ ) -> StringIO {
        return new( string, mode, perm, file: file, line: line )
    }

    public override func each_byte( block: (CChar) -> () ) -> IO {
        while !eof {
            block( data.bytes[offset++] )
        }
        return self
    }

    public override var eof: Bool {
        return offset >= data.length
    }

    public override var getc: String? {
        return !eof ? String( data.bytes[offset++] ) : nil
    }

    override func gets( sep: to_s_protocol = LINE_SEPARATOR ) -> String? {
        if eof {
            return nil
        }

        let sepchar = sep.to_s.ord
        let endOfLine = UnsafeMutablePointer<Int8>( memchr( data.bytes+offset, Int32(sepchar), Int(data.length-offset) ) )

        if endOfLine != nil {
            endOfLine.memory = 0
        }

        let out = String( UTF8String: data.bytes+offset )

        if endOfLine != nil {
            endOfLine.memory = Int8(sepchar)
            offset = endOfLine - data.bytes + 1
        }
        else {
            offset = data.length
        }

        return out
    }

    public override func print( string: to_s_protocol ) -> Int {
        return write( string.to_s )
    }

    override func putc( obj: Int ) -> Int {
        if data.capacity <  data.length + 1 {
            data.capacity += 10_000 ////
        }
        data.bytes[data.length++] = Int8(obj)
        return 1
    }

    public override func read( length: Int?, _ outbuf: Data? ) -> Data? {
        return data
    }

    public override func rewind( file: String = __FILE__, line: Int = __LINE__ ) -> IO {
        seek( 0, Int(SEEK_SET) )
        return self
    }

    public override func seek( amount: Int, _ whence: Int, file: String = __FILE__, line: Int = __LINE__ ) -> Bool {
        switch Int32(whence) {
        case SEEK_SET:
            offset = amount
        case SEEK_CUR:
            offset += amount
        case SEEK_END:
            offset = data.length + amount
        default:
            return false
        }
        if offset < 0 || offset > data.length {
            RKLog( "Invalid StringIO.seek \(amount), \(whence) -> \(offset) outside 0-\(data.length)", file: file, line: line )
            return false
        }
        return true
    }

    public override func write( string: to_d_protocol ) -> fixnum {
        return data.append( string )
    }

}
