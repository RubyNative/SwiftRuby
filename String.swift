//
//  String.swift
//  SwiftRuby
//
//  Created by John Holdsworth on 26/09/2015.
//  Copyright © 2015 John Holdsworth. All rights reserved.
//
//  $Id: //depot/SwiftRuby/String.swift#11 $
//
//  Repo: https://github.com/RubyNative/SwiftRuby
//
//  See: http://ruby-doc.org/core-2.2.3/String.html
//

import Foundation

public var STRING_ENCODING = String.Encoding.utf8

public let FALLBACK_INPUT_ENCODING = String.Encoding.isoLatin1
public let FALLBACK_OUTPUT_ENCODING = String.Encoding.utf8

public enum StringIndexDisposition {
    case warnAndFail, truncate
}

public var STRING_INDEX_DISPOSITION: StringIndexDisposition = .warnAndFail

public protocol string_like: array_like {

    var to_s: String { get }

}

public protocol char_like {

    var to_c: [CChar] { get }
    
}

extension String: string_like, array_like, data_like, char_like {

    public subscript ( i: Int ) -> String {
        return slice( i )
    }

    public subscript ( start: Int, len: Int ) -> String {
        return slice( start, len: len )
    }

    public subscript ( r: Range<Int> ) -> String {
        return substring( with: characters.index(startIndex, offsetBy: r.lowerBound)..<characters.index(startIndex, offsetBy: r.upperBound) )
    }

    public var to_s: String {
        return self
    }

    public var to_a: [String] {
        // ??? self.characters.count
        return [self]
    }

    public var to_c: [CChar] {
        if let chars = cString( using: STRING_ENCODING ) {
            return chars
        }

        SRLog( "String.to_c, unable to encode string for output" )
        return U(cString( using: FALLBACK_OUTPUT_ENCODING ))
    }

    public var to_d: Data {
        return Data( array: self.to_c )
    }

    public var to_i: Int {
        if let val = Int( self ) {
            return val
        }
        let dummy = -99999999
        SRLog( "Unable to convert \(self) to Int. Returning \(dummy)" )
        return dummy
    }

    public var to_f: Double {
        if let val = Double( self ) {
            return val
        }
        let dummy = -99999999.0
        SRLog( "Unable to convert \(self) to Doubleb. Returning \(dummy)" )
        return dummy
    }
    
    public func characterAtIndex( _ i: Int ) -> Int {
        if let char = self[i].unicodeScalars.first {
            return Int(char.value)
        }
        SRLog( "No character available in string '\(self)' returning nul char" )
        return 0
    }

    public var downcase: String {
        return self.lowercased()
    }

    public func each_byte( _ block: (UInt8) -> () ) {
        for char in utf8 {
            block( char )
        }
    }

    public func each_char( _ block: (UInt16) -> () ) {
        for char in utf16 {
            block( char )
        }
    }

    public func each_codepoint( _ block: (String) -> () ) {
        for char in characters {
            block( String( char ) )
        }
    }

    public func each_line( _ block: (String) -> () ) {
        StringIO( self ).each_line( LINE_SEPARATOR, nil, block )
    }

    public var length: Int {
        return characters.count
    }

    public var ord: Int {
        return characterAtIndex(0)
    }

    public func slice( _ start: Int, len: Int = 1 ) -> String {
        var vstart = start, vlen = len
        let length = self.length

        if start < 0 {
            vstart = length + start
        }
        if vstart < 0 {
            SRLog( "String.str( \(start), \(len) ) start before front of string '\(self)', length \(length)" )
            if STRING_INDEX_DISPOSITION == .truncate {
                vstart = 0
            }
        }
        else if vstart > length {
            SRLog( "String.str( \(start), \(len) ) start after end of string '\(self)', length \(length)" )
            if STRING_INDEX_DISPOSITION == .truncate {
                vstart = length
            }
        }

        if len < 0 {
            vlen = length + len - vstart
        }
        else if len ==  NSNotFound {
            vlen = length - vstart
        }
        if vlen < 0 {
            SRLog( "String.str( \(start), \(len) ) start + len before start of substring '\(self)', length \(length)" )
            if STRING_INDEX_DISPOSITION == .truncate {
                vlen = 0
            }
        }
        else if vstart + vlen > length {
            SRLog( "String.str( \(start), \(len) ) start + len after end of string '\(self)', length \(length)" )
            if STRING_INDEX_DISPOSITION == .truncate {
                vlen = length - vstart
            }
        }

        return self[vstart..<vstart+vlen]
    }

    public func split( _ delimiter: String ) -> [String] {
        return components( separatedBy: delimiter )
    }

    public var upcase: String {
        return self.uppercased()
    }

}
