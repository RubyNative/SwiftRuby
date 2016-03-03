//
//  StringIO.swift
//  SwiftRuby
//
//  Created by John Holdsworth on 28/09/2015.
//  Copyright © 2015 John Holdsworth. All rights reserved.
//
//  $Id: //depot/SwiftRuby/StringIO.swift#6 $
//
//  Repo: https://github.com/RubyNative/SwiftRuby
//
//  See: http://ruby-doc.org/stdlib-2.2.3/libdoc/stringio/rdoc/StringIO.html
//

import Darwin

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

    public init( _ string: data_like = "", file: StaticString = __FILE__, line: UInt = __LINE__ ) {
        data = string.to_d
        super.init( what: nil, unixFILE: nil )
    }

    public class func new( string: data_like, _ mode: string_like = "r", _ perm: Int? = nil, file: StaticString = __FILE__, line: UInt = __LINE__ ) -> StringIO {
        return StringIO( string, file: file, line: line )
    }

    public class func open( string: data_like, _ mode: string_like = "r", _ perm: Int? = nil, file: StaticString = __FILE__, line: UInt = __LINE__ ) -> StringIO {
        return new( string, mode, perm, file: file, line: line )
    }

    public override func each_byte( block: (CChar) -> () ) -> IO {
        while !eof {
            block( data.bytes[offset] )
            offset += 1
        }
        return self
    }

    public override var eof: Bool {
        return offset >= data.length
    }

    public override var getc: String? {
        let ret: String? = !eof ? String( data.bytes[offset] ) : nil
        offset += 1
        return ret
    }

    override func gets( sep: string_like = LINE_SEPARATOR ) -> String? {
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

    public override func print( string: string_like ) -> Int {
        return write( string.to_s )
    }

    override func putc( obj: Int ) -> Int {
        if data.capacity <  data.length + 1 {
            data.capacity += 10_000 ////
        }
        data.bytes[data.length] = Int8(obj)
        data.length += 1
        return 1
    }

    public override func read( length: Int?, _ outbuf: Data? ) -> Data? {
        return data
    }

    public override func rewind( file: StaticString = __FILE__, line: UInt = __LINE__ ) -> IO {
        seek( 0, Int(SEEK_SET) )
        return self
    }

    public override func seek( amount: Int, _ whence: Int, file: StaticString = __FILE__, line: UInt = __LINE__ ) -> Bool {
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
            SRLog( "Invalid StringIO.seek \(amount), \(whence) -> \(offset) outside 0-\(data.length)", file: file, line: line )
            return false
        }
        return true
    }

    public override func write( string: data_like ) -> fixnum {
        return data.append( string )
    }

}
