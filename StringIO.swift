//
//  StringIO.swift
//  SwiftRuby
//
//  Created by John Holdsworth on 28/09/2015.
//  Copyright © 2015 John Holdsworth. All rights reserved.
//
//  $Id: //depot/SwiftRuby/StringIO.swift#7 $
//
//  Repo: https://github.com/RubyNative/SwiftRuby
//
//  See: http://ruby-doc.org/stdlib-2.2.3/libdoc/stringio/rdoc/StringIO.html
//

import Darwin

public var LINE_SEPARATOR = "\n"

open class StringIO: IO {

    open let data: Data
    open var offset = 0

    open override var pos: Int {
        get {
            return offset
        }
        set {
            offset = newValue
        }
    }

    public init( _ string: data_like = "", file: StaticString = #file, line: UInt = #line ) {
        data = string.to_d
        super.init( what: nil, unixFILE: nil )
    }

    open class func new( _ string: data_like, _ mode: string_like = "r", _ perm: Int? = nil, file: StaticString = #file, line: UInt = #line ) -> StringIO {
        return StringIO( string, file: file, line: line )
    }

    open class func open( _ string: data_like, _ mode: string_like = "r", _ perm: Int? = nil, file: StaticString = #file, line: UInt = #line ) -> StringIO {
        return new( string, mode, perm, file: file, line: line )
    }

    open override func each_byte( _ block: (CChar) -> () ) -> IO {
        while !eof {
            block( data.bytes[offset] )
            offset += 1
        }
        return self
    }

    open override var eof: Bool {
        return offset >= data.length
    }

    open override var getc: String? {
        let ret: String? = !eof ? String( data.bytes[offset] ) : nil
        offset += 1
        return ret
    }

    override func gets( _ sep: string_like = LINE_SEPARATOR ) -> String? {
        if eof {
            return nil
        }

        let sepchar = sep.to_s.ord
        let endOfLine = memchr( data.bytes+offset, Int32(sepchar), Int(data.length-offset) )?.assumingMemoryBound(to: Int8.self)

        if endOfLine != nil {
            endOfLine!.pointee = 0
        }

        let out = String( validatingUTF8: data.bytes+offset )

        if endOfLine != nil {
            endOfLine!.pointee = Int8(sepchar)
            offset = endOfLine! - data.bytes + 1
        }
        else {
            offset = data.length
        }

        return out
    }

    open override func print( _ string: string_like ) -> Int {
        return write( string.to_s )
    }

    override func putc( _ obj: Int ) -> Int {
        if data.capacity <  data.length + 1 {
            data.capacity += 10_000 ////
        }
        data.bytes[data.length] = Int8(obj)
        data.length += 1
        return 1
    }

    open override func read( _ length: Int?, _ outbuf: Data? ) -> Data? {
        return data
    }

    @discardableResult
    open override func rewind( _ file: StaticString = #file, line: UInt = #line ) -> IO {
        _ = seek( 0, Int(SEEK_SET) )
        return self
    }

    open override func seek( _ amount: Int, _ whence: Int, file: StaticString = #file, line: UInt = #line ) -> Bool {
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

    @discardableResult
    open override func write( _ string: data_like ) -> fixnum {
        return data.append( string )
    }

}
