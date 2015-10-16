//
//  Integer.swift
//  RubyNative
//
//  Created by John Holdsworth on 26/09/2015.
//  Copyright © 2015 John Holdsworth. All rights reserved.
//
//  $Id: //depot/SwiftRuby/Integer.swift#2 $
//
//  Repo: https://github.com/RubyNative/SwiftRuby
//
//  See: http://ruby-doc.org/core-2.2.3/Integer.html
//

public typealias fixnum = Int

public protocol to_i_protocol {

    var to_i: Int { get }
    
}

extension Int {

    public var to_i: Int {
        return self
    }
    
    public var to_f: Double {
        return Double( self )
    }

    public var to_s: String {
        return String( self )
    }

    public var to_b: String {
        return String( self, radix: 2 )
    }

    public var to_o: String {
        return String( self, radix: 8  )
    }

    public var to_h: String {
        return String( self, radix: 16, uppercase: false )
    }

    public var chr: String {
        return "\(UnicodeScalar(self))"
    }

    public var denominator: Int {
        return 1
    }

    public func downto( limit: Int, block: (i: Int) -> () ) -> Int {
        for var i = self; i >= limit ; i-- {
            block( i: i )
        }
        return self
    }

    public var even: Bool {
        return self & 0x1 == 0
    }

//    public func gcd( int2: Int ) -> Int {
//        RKNotImplemented( "Integer.gcd" )
//        return -1
//    }
//
//    public func gcdlcm( int2: Int ) -> Int {
//        RKNotImplemented( "Integer.gcd" )
//        return -1
//    }
//
//    public func lcm( int2: Int ) -> Int {
//        RKNotImplemented( "Integer.gcd" )
//        return -1
//    }

    public var next: Int {
        return self+1
    }

    public var numerator: Int {
        return self+1
    }

    public var odd: Bool {
        return !even
    }

    public var ord: Int {
        return self
    }

    public var pred: Int {
        return self-1
    }

    public func times( block: (i: Int) -> () ) -> Int {
        for var i = 1; i <= self ; i++ {
            block( i: i )
        }
        return self
    }

    public func upto( limit: Int, block: (i: Int) -> () ) -> Int {
        for var i = self; i <= limit ; i++ {
            block( i: i )
        }
        return self
    }

}
