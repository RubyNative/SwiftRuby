//
//  Float.swift
//  SwiftRuby
//
//  Created by John Holdsworth on 26/09/2015.
//  Copyright © 2015 John Holdsworth. All rights reserved.
//
//  $Id: //depot/SwiftRuby/Float.swift#6 $
//
//  Repo: https://github.com/RubyNative/SwiftRuby
//
//  See: http://ruby-doc.org/core-2.2.3/Float.html
//

public protocol float_like {

    var to_f: Double { get }

}

extension Double: float_like {

    public var to_s: String {
        return String(self)
    }

    public var to_f: Double {
        return self
    }

    public var to_i: Int {
        return Int(self)
    }

}
