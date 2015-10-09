//
//  Kernel.swift
//  RubyNative
//
//  Created by John Holdsworth on 27/09/2015.
//  Copyright © 2015 John Holdsworth. All rights reserved.
//
//  $Id: //depot/RubyKit/Kernel.swift#3 $
//
//  Repo: https://github.com/RubyNative/RubyKit
//
//  See: http://ruby-doc.org/core-2.2.3/Kernel.html
//

import Foundation

public class Kernel: RubyObject {

    public class func open( path: to_s_protocol, _ mode: to_s_protocol = "r", _ perm: Int = 0o644, file: String = __FILE__, line: Int = __LINE__ ) -> IO? {
        let path = path.to_s
        let index1 = path.startIndex.advancedBy(1)

        if path.substringToIndex( index1 ) == "|" {
            return IO.popen( path.substringFromIndex( index1 ), mode, file: file, line: line )
        }
        else {
            return File.open( path, mode, perm, file: file, line: line )
        }
    }

}
