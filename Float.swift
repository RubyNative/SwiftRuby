//
//  Float.swift
//  RubyNative
//
//  Created by John Holdsworth on 26/09/2015.
//  Copyright © 2015 John Holdsworth. All rights reserved.
//
//  $Id: //depot/RubyKit/Float.swift#1 $
//
//  Repo: https://github.com/RubyNative/RubyNative
//
//  See: http://ruby-doc.org/core-2.2.3/Float.html
//

import Foundation

public protocol to_f_protocol {

    var to_f: Double { get }

}

extension Double {

    public var to_s: String {
        return String( self )
    }

    public var to_f: Double {
        return self
    }

    public var to_i: Int {
        return Int( self )
    }

}
