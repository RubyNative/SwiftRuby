//
//  Integer.swift
//  RubyNative
//
//  Created by John Holdsworth on 26/09/2015.
//  Copyright © 2015 John Holdsworth. All rights reserved.
//
//  $Id: //depot/RubyNative/Integer.swift#5 $
//
//  Repo: https://github.com/RubyNative/RubyNative
//
//  See: http://ruby-doc.org/core-2.2.3/Integer.html
//

import Foundation

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

}
