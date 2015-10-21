//
//  Kernel.swift
//  SwiftRuby
//
//  Created by John Holdsworth on 27/09/2015.
//  Copyright © 2015 John Holdsworth. All rights reserved.
//
//  $Id: //depot/SwiftRuby/Kernel.swift#6 $
//
//  Repo: https://github.com/RubyNative/SwiftRuby
//
//  See: http://ruby-doc.org/core-2.2.3/Kernel.html
//

import Foundation

@asmname ("execArgv")
func execArgv( executable: NSString, argv: NSArray )

public class Kernel: RubyObject {

    public class func open( path: to_s_protocol, _ mode: to_s_protocol = "r", _ perm: Int = 0o644, file: StaticString = __FILE__, line: UInt = __LINE__ ) -> IO? {
        let path = path.to_s
        let index1 = path.startIndex.advancedBy(1)

        if path.substringToIndex( index1 ) == "|" {
            return IO.popen( path.substringFromIndex( index1 ), mode, file: file, line: line )
        }
        else {
            return File.open( path, mode, perm, file: file, line: line )
        }
    }

    public class func exec( command: to_s_protocol ) {
        exec( "/bin/bash", ["-c", command.to_s] )
    }

    public class func exec( executable: to_s_protocol, _ arguments: to_a_protocol ) {
        exec( [executable.to_s, executable.to_s], arguments.to_a )
    }

    public class func exec( executable: to_a_protocol, _ arguments: to_a_protocol ) {
        execArgv( executable.to_a[0].to_s, argv: [executable.to_a[1]]+arguments.to_a )
    }

}
