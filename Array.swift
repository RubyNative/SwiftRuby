//
//  Array.swift
//  SwiftRuby
//
//  Created by John Holdsworth on 26/09/2015.
//  Copyright © 2015 John Holdsworth. All rights reserved.
//
//  $Id: //depot/SwiftRuby/Array.swift#4 $
//
//  Repo: https://github.com/RubyNative/SwiftRuby
//
//  See: http://ruby-doc.org/core-2.2.3/Array.html
//

public protocol array_like {

    var to_a: [String] { get }

}

extension Array: array_like {

    public var to_a: [String] {
        return map { String( $0 ) }
    }

//    public func join( sep: String = " " ) -> String {
//        return joinWithSeparator( sep )
//    }

}

extension CollectionType {

    public func each( block: (Generator.Element) -> () ) {
        forEach( block )
    }
    
}
