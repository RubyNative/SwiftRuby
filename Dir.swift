//
//  Dir.swift
//  RubyNative
//
//  Created by John Holdsworth on 28/09/2015.
//  Copyright © 2015 John Holdsworth. All rights reserved.
//
//  $Id: //depot/RubyNative/Dir.swift#21 $
//
//  Repo: https://github.com/RubyNative/RubyNative
//
//  See: http://ruby-doc.org/core-2.2.3/Dir.html
//

import Foundation

public class Dir: Object {

    let dirpath: String
    var dirPointer: UnsafeMutablePointer<DIR>
    var closed = false

    // Dir[ string [, string ...] ] → array

    init?( dirname: to_s_protocol, file: String = __FILE__, line: Int = __LINE__ ) {
        dirpath = dirname.to_s
        dirPointer = opendir( dirpath )
        super.init()
        if dirPointer == nil {
            if warningDisposition != .Ignore {
                RKLogerr( "opendir '\(dirpath)' failed", file: file, line: line )
            }
            if warningDisposition == .Fatal {
                fatalError()
            }
            return nil
        }
    }

    public class func chdir( string: to_s_protocol, file: String = __FILE__, line: Int = __LINE__ ) -> Bool {
        return unixOK( "Dir.chdir '\(string.to_s)", Darwin.chdir( string.to_s ), file: file, line: line )
    }

    public class func chroot( string: to_s_protocol, file: String = __FILE__, line: Int = __LINE__ ) -> Bool {
        return unixOK( "Dir.chroot '\(string.to_s)", Darwin.chroot( string.to_s ), file: file, line: line )
    }

    public class func delete( string: to_s_protocol, file: String = __FILE__, line: Int = __LINE__ ) -> Bool {
        return unixOK( "Dir.rmdir '\(string.to_s)", Darwin.rmdir( string.to_s ), file: file, line: line )
    }

    public class func entries( dirname: to_s_protocol, file: String = __FILE__, line: Int = __LINE__ ) -> [String] {
        var out = [String]()
        foreach( dirname ) {
            (name) in
            out.append( name )
        }
        return out
    }

    public class func exist( dirname: to_s_protocol, file: String = __FILE__, line: Int = __LINE__ ) -> Bool {
        return File.exist( dirname, file: file, line: line )
    }

    public class func exists( dirname: to_s_protocol, file: String = __FILE__, line: Int = __LINE__ ) -> Bool {
        return exist( dirname, file: file, line: line )
    }

    public class func foreach( dirname: to_s_protocol, _ block: (String) -> () ) {
        if let dir = Dir( dirname: dirname, file: __FILE__, line: __LINE__ ) {
            dir.each {
                (name) in
                block( name )
            }
        }
    }

    public class var getwd: String? {
        var cwd = [Int8]( count: Int(PATH_MAX), repeatedValue: 0 )
        if !unixOK( "Dir.getwd", Darwin.getcwd( &cwd, cwd.count ) != nil ? 0 : 1, file: __FILE__, line: __LINE__ ) {
            return nil
        }
        return String( UTF8String: cwd )
    }

    public class func glob( pattern: to_s_protocol, _ root: String = ".", file: String = __FILE__, line: Int = __LINE__ ) -> [String]? {
        let regex = pattern.to_s
            .stringByReplacingOccurrencesOfString( ".", withString: "\\." )
            .stringByReplacingOccurrencesOfString( "**", withString: "___" )
            .stringByReplacingOccurrencesOfString( "*", withString: "[^/]*" )
            .stringByReplacingOccurrencesOfString( "?", withString: "[^/]" )
            .stringByReplacingOccurrencesOfString( "___", withString: ".*" )
        //print( regex )
        return IO.popen( "find \"\(root)\" -print | egrep -e \"^(./)?\(regex)$\"", file: file, line: line )?.readlines()
    }

    public class func home( user: to_s_protocol? = nil, file: String = __FILE__, line: Int = __LINE__ ) -> String? {
        var user = user?.to_s
        var cwd = [Int8]( count: Int(PATH_MAX), repeatedValue: 0 )
        var ret = UnsafeMutablePointer<passwd>()
        var info = passwd()

        if user == nil || user == "" {
            if !unixOK( "Dir.home", getpwuid_r( getuid(), &info, &cwd, cwd.count, &ret ), file: file, line: line ) {
                return nil
            }
            user = String( UTF8String: info.pw_name )
        }

        if !unixOK( "Dir.home \(user)", getpwnam_r( user!, &info, &cwd, cwd.count, &ret ), file: file, line: line ) {
            return nil
        }

        return String( UTF8String: info.pw_dir )
    }

    public class func mkdir( string: to_s_protocol, _ mode: Int = 0o755, file: String = __FILE__, line: Int = __LINE__ ) -> Bool {
        return unixOK( "Dir.mkdir '\(string.to_s)", Darwin.mkdir( string.to_s, mode_t(mode) ), file: file, line: line )
    }

    public class func new( string: to_s_protocol, file: String = __FILE__, line: Int = __LINE__ ) -> Dir? {
        return Dir( dirname: string, file: file, line: line )
    }

    public class func open( string: to_s_protocol, file: String = __FILE__, line: Int = __LINE__ ) -> Dir? {
        return new( string, file: file, line: line )
    }

    public class var pwd: String? {
        return getwd
    }

    public class func rmdir( string: to_s_protocol, file: String = __FILE__, line: Int = __LINE__ ) -> Bool {
        return delete( string, file: file, line: line )
    }

    public class func unlink( string: to_s_protocol, file: String = __FILE__, line: Int = __LINE__ ) -> Bool {
        return delete( string, file: file, line: line )
    }

    // MARK: Instance methods

    public func close( file: String = __FILE__, line: Int = __LINE__ ) -> Bool {
        closed = true
        return unixOK( "Dir.closedir '\(dirpath)'",  closedir( dirPointer ), file: file, line: line )
    }

    public func each( block: (String) -> () ) -> Dir {
        while let name = read() {
            block( name )
        }
        return self
    }

    public var fileno: Int {
        return Int(dirfd(dirPointer))
    }

    public var inspect: String {
        return dirpath
    }

    public var path: String {
        return dirpath
    }

    public var pos: Int  {
        return Int(telldir( dirPointer ))
    }

    public func read() -> String? {
        let ent = readdir( dirPointer )
        if ent != nil {
            return withUnsafeMutablePointer (&ent.memory.d_name) {
                String( UTF8String: UnsafeMutablePointer($0) ) //!!
            }
        }
        return nil
    }

    public func rewind() {
        Darwin.rewinddir( dirPointer )
    }

    public func seek( pos: Int ) {
        seekdir( dirPointer, pos )
    }

    public var tell: Int  {
        return pos
    }

    public var to_path: String {
        return dirpath
    }

    deinit {
        if !closed {
            close()
        }
    }

}
