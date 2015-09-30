//
//  Array.swift
//  RubyNative
//
//  Created by John Holdsworth on 26/09/2015.
//  Copyright © 2015 John Holdsworth. All rights reserved.
//
//  $Id: //depot/RubyNative/Array.swift#4 $
//
//  Repo: https://github.com/RubyNative/RubyNative
//
//  See: http://ruby-doc.org/core-2.2.3/Array.html
//

import Foundation

public protocol to_a_protocol {

    var to_a: [String] { get }

}

extension Array {

    public func each( block: (String) -> () ) {
        for string in self {
            block( String( string ) ) ///// cast! doesn't work in binary targets 
        }
    }

}