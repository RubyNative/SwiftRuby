//
//  Dir.swift
//  SwiftRuby
//
//  Created by John Holdsworth on 28/09/2015.
//  Copyright © 2015 John Holdsworth. All rights reserved.
//
//  $Id: //depot/SwiftRuby/Dir.swift#5 $
//
//  Repo: https://github.com/RubyNative/SwiftRuby
//
//  See: http://ruby-doc.org/core-2.2.3/Dir.html
//

import Darwin

public class Dir: RubyObject, array_like {

    let dirpath: String
    var unixDIR: UnsafeMutablePointer<DIR>

    // Dir[ string [, string ...] ] → array

    init?( dirname: string_like, file: StaticString = __FILE__, line: UInt = __LINE__ ) {
        dirpath = dirname.to_s
        unixDIR = opendir( dirpath )
        super.init()
        if unixDIR == nil {
            SRError( "opendir '\(dirpath.to_s)' failed", file: file, line: line )
            return nil
        }
    }

    // MARK: Class Methods

    public class func new( string: string_like, file: StaticString = __FILE__, line: UInt = __LINE__ ) -> Dir? {
        return Dir( dirname: string, file: file, line: line )
    }

    public class func open( string: string_like, file: StaticString = __FILE__, line: UInt = __LINE__ ) -> Dir? {
        return new( string, file: file, line: line )
    }
    
    public class func chdir( string: string_like, file: StaticString = __FILE__, line: UInt = __LINE__ ) -> Bool {
        return unixOK( "Dir.chdir '\(string.to_s)", Darwin.chdir( string.to_s ), file: file, line: line )
    }

    public class func chroot( string: string_like, file: StaticString = __FILE__, line: UInt = __LINE__ ) -> Bool {
        return unixOK( "Dir.chroot '\(string.to_s)", Darwin.chroot( string.to_s ), file: file, line: line )
    }

    public class func delete( string: string_like, file: StaticString = __FILE__, line: UInt = __LINE__ ) -> Bool {
        return unixOK( "Dir.rmdir '\(string.to_s)", Darwin.rmdir( string.to_s ), file: file, line: line )
    }

    public class func entries( dirname: string_like, file: StaticString = __FILE__, line: UInt = __LINE__ ) -> [String] {
        var out = [String]()
        foreach( dirname ) {
            (name) in
            out.append( name )
        }
        return out
    }

    public class func exist( dirname: string_like, file: StaticString = __FILE__, line: UInt = __LINE__ ) -> Bool {
        return File.exist( dirname, file: file, line: line )
    }

    public class func exists( dirname: string_like, file: StaticString = __FILE__, line: UInt = __LINE__ ) -> Bool {
        return exist( dirname, file: file, line: line )
    }

    public class func foreach( dirname: string_like, _ block: (String) -> () ) {
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

    public class func glob( pattern: string_like, _ root: String = ".", file: StaticString = __FILE__, line: UInt = __LINE__ ) -> [String]? {
        let regex = pattern.to_s
            .stringByReplacingOccurrencesOfString( ".", withString: "\\." )
            .stringByReplacingOccurrencesOfString( "**", withString: "___" )
            .stringByReplacingOccurrencesOfString( "*", withString: "[^/]*" )
            .stringByReplacingOccurrencesOfString( "?", withString: "[^/]" )
            .stringByReplacingOccurrencesOfString( "___", withString: ".*" )
        let command = "cd \"\(root)\" && find -E . -regex \"^(./)?\(regex)$\"| sed -e s/^.\\\\///"
        return IO.popen( command, file: file, line: line )?.readlines()
    }

    public class func home( user: string_like? = nil, file: StaticString = __FILE__, line: UInt = __LINE__ ) -> String? {
        var user = user?.to_s
        var buff = [Int8]( count: Int(PATH_MAX), repeatedValue: 0 )
        var ret = UnsafeMutablePointer<passwd>()
        var info = passwd()

        if user == nil || user == "" {
            if !unixOK( "Dir.getpwuid", getpwuid_r( geteuid(), &info, &buff, buff.count, &ret ), file: file, line: line ) {
                return nil
            }
            user = String( UTF8String: info.pw_name )
        }

        if !unixOK( "Dir.getpwnam \(user!.to_s)", getpwnam_r( user!, &info, &buff, buff.count, &ret ), file: file, line: line ) {
            return nil
        }

        return String( UTF8String: info.pw_dir )
    }

    public class func mkdir( string: string_like, _ mode: Int = 0o755, file: StaticString = __FILE__, line: UInt = __LINE__ ) -> Bool {
        return unixOK( "Dir.mkdir '\(string.to_s)", Darwin.mkdir( string.to_s, mode_t(mode) ), file: file, line: line )
    }

    public class var pwd: String? {
        return getwd
    }

    public class func rmdir( string: string_like, file: StaticString = __FILE__, line: UInt = __LINE__ ) -> Bool {
        return delete( string, file: file, line: line )
    }

    public class func unlink( string: string_like, file: StaticString = __FILE__, line: UInt = __LINE__ ) -> Bool {
        return delete( string, file: file, line: line )
    }

    // MARK: Instance methods

    public func close( file: StaticString = __FILE__, line: UInt = __LINE__ ) -> Bool {
        let ok = unixOK( "Dir.closedir '\(dirpath)'",  closedir( unixDIR ), file: file, line: line )
        unixDIR = nil
        return ok
    }

    public func each( block: (String) -> () ) -> Dir {
        while let name = read() {
            block( name )
        }
        return self
    }

    public var fileno: Int {
        return Int(dirfd( unixDIR ))
    }

    public var inspect: String {
        return dirpath
    }

    public var path: String {
        return dirpath
    }

    public var pos: Int  {
        return Int(telldir( unixDIR ))
    }

    public func read() -> String? {
        let ent = readdir( unixDIR )
        if ent != nil {
            return withUnsafeMutablePointer (&ent.memory.d_name) {
                String( UTF8String: UnsafeMutablePointer($0) )
            }
        }
        return nil
    }

    public func rewind() {
        Darwin.rewinddir( unixDIR )
    }

    public func seek( pos: Int ) -> Int {
        return Int(seekdir( unixDIR, pos ))
    }

    public var tell: Int {
        return pos
    }

    public var to_a: [String] {
        var out = [String]()
        each {
            (entry) in
            out .append( entry )
        }
        return out
    }

    public var to_path: String {
        return dirpath
    }

    deinit {
        if unixDIR != nil {
            close()
        }
    }

}
