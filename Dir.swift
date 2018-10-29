//
//  Dir.swift
//  SwiftRuby
//
//  Created by John Holdsworth on 28/09/2015.
//  Copyright © 2015 John Holdsworth. All rights reserved.
//
//  $Id: //depot/SwiftRuby/Dir.swift#14 $
//
//  Repo: https://github.com/RubyNative/SwiftRuby
//
//  See: http://ruby-doc.org/core-2.2.3/Dir.html
//

import Darwin

open class Dir: RubyObject, array_like {

    let dirpath: String
    var unixDIR: UnsafeMutablePointer<DIR>?

    // Dir[ string [, string ...] ] → array

    init?( dirname: string_like, file: StaticString = #file, line: UInt = #line ) {
        dirpath = dirname.to_s
        unixDIR = opendir( dirpath )
        super.init()
        if unixDIR == nil {
            SRError( "opendir '\(dirpath.to_s)' failed", file: file, line: line )
            return nil
        }
    }

    // MARK: Class Methods

    open class func new( _ string: string_like, file: StaticString = #file, line: UInt = #line ) -> Dir? {
        return Dir( dirname: string, file: file, line: line )
    }

    open class func open( _ string: string_like, file: StaticString = #file, line: UInt = #line ) -> Dir? {
        return new( string, file: file, line: line )
    }
    
    open class func chdir( _ string: string_like, file: StaticString = #file, line: UInt = #line ) -> Bool {
        return unixOK( "Dir.chdir '\(string.to_s)", Darwin.chdir( string.to_s ), file: file, line: line )
    }

    open class func chroot( _ string: string_like, file: StaticString = #file, line: UInt = #line ) -> Bool {
        return unixOK( "Dir.chroot '\(string.to_s)", Darwin.chroot( string.to_s ), file: file, line: line )
    }

    open class func delete( _ string: string_like, file: StaticString = #file, line: UInt = #line ) -> Bool {
        return unixOK( "Dir.rmdir '\(string.to_s)", Darwin.rmdir( string.to_s ), file: file, line: line )
    }

    open class func entries( _ dirname: string_like, file: StaticString = #file, line: UInt = #line ) -> [String] {
        var out = [String]()
        foreach( dirname ) {
            (name) in
            out.append( name )
        }
        return out
    }

    open class func exist( _ dirname: string_like, file: StaticString = #file, line: UInt = #line ) -> Bool {
        return File.exist( dirname, file: file, line: line )
    }

    open class func exists( _ dirname: string_like, file: StaticString = #file, line: UInt = #line ) -> Bool {
        return exist( dirname, file: file, line: line )
    }

    open class func foreach( _ dirname: string_like, _ block: (String) -> () ) {
        if let dir = Dir( dirname: dirname, file: #file, line: #line ) {
            dir.each {
                (name) in
                block( name )
            }
        }
    }

    open class var getwd: String? {
        var cwd = [Int8]( repeating: 0, count: Int(PATH_MAX) )
        if !unixOK( "Dir.getwd", Darwin.getcwd( &cwd, cwd.count ) != nil ? 0 : 1, file: #file, line: #line ) {
            return nil
        }
        return String( validatingUTF8: cwd )
    }

    open class func glob( _ pattern: string_like, _ flags: Int32 = 0, file: StaticString = #file, line: UInt = #line ) -> [String]? {
        return pattern.to_s.withCString {
            var pglob = glob_t()
            if (unixOK("Dir.glob", Darwin.glob($0, flags, nil, &pglob), file: file, line: line)) {
                defer { globfree(&pglob) }
                return (0..<Int(pglob.gl_matchc)).map { String(cString: U(U(pglob.gl_pathv)[$0])) }
            }
            return nil
        }
    }

    open class func home( _ user: string_like? = nil, file: StaticString = #file, line: UInt = #line ) -> String? {
        var user = user?.to_s
        var buff = [Int8]( repeating: 0, count: Int(PATH_MAX) )
        var ret: UnsafeMutablePointer<passwd>?
        var info = passwd()

        if user == nil || user == "" {
            if !unixOK( "Dir.getpwuid", getpwuid_r( geteuid(), &info, &buff, buff.count, &ret ), file: file, line: line ) {
                return nil
            }
            user = String( validatingUTF8: info.pw_name )
        }

        if !unixOK( "Dir.getpwnam \(user!.to_s)", getpwnam_r( user!, &info, &buff, buff.count, &ret ), file: file, line: line ) {
            return nil
        }

        return String( validatingUTF8: info.pw_dir )
    }

    open class func mkdir( _ string: string_like, _ mode: Int = 0o755, file: StaticString = #file, line: UInt = #line ) -> Bool {
        return unixOK( "Dir.mkdir '\(string.to_s)", Darwin.mkdir( string.to_s, mode_t(mode) ), file: file, line: line )
    }

    open class var pwd: String? {
        return getwd
    }

    open class func rmdir( _ string: string_like, file: StaticString = #file, line: UInt = #line ) -> Bool {
        return delete( string, file: file, line: line )
    }

    open class func unlink( _ string: string_like, file: StaticString = #file, line: UInt = #line ) -> Bool {
        return delete( string, file: file, line: line )
    }

    // MARK: Instance methods

    @discardableResult
    open func close( _ file: StaticString = #file, line: UInt = #line ) -> Bool {
        let ok = unixOK( "Dir.closedir '\(dirpath)'",  closedir( unixDIR ), file: file, line: line )
        unixDIR = nil
        return ok
    }

    @discardableResult
    open func each( _ block: (String) -> () ) -> Dir {
        while let name = read() {
            block( name )
        }
        return self
    }

    open var fileno: Int {
        return Int(dirfd( unixDIR ))
    }

    open var inspect: String {
        return dirpath
    }

    open var path: String {
        return dirpath
    }

    open var pos: Int  {
        return Int(telldir( unixDIR ))
    }

    open func read() -> String? {
        let ent = readdir( unixDIR )
        if ent != nil {
            return withUnsafeMutablePointer (to: &ent!.pointee.d_name) {
                String( validatingUTF8: UnsafeMutableRawPointer($0).assumingMemoryBound(to: CChar.self) )
            }
        }
        return nil
    }

    open func rewind() {
        Darwin.rewinddir( unixDIR )
    }

    open func seek( _ pos: Int ) {
        seekdir( unixDIR, pos )
    }

    open var tell: Int {
        return pos
    }

    open var to_a: [String] {
        var out = [String]()
        each {
            (entry) in
            out .append( entry )
        }
        return out
    }

    open var to_path: String {
        return dirpath
    }

    deinit {
        if unixDIR != nil {
            close()
        }
    }

}
