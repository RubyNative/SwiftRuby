//
//  File.swift
//  SwiftRuby
//
//  Created by John Holdsworth on 26/09/2015.
//  Copyright © 2015 John Holdsworth. All rights reserved.
//
//  $Id: //depot/SwiftRuby/File.swift#9 $
//
//  Repo: https://github.com/RubyNative/SwiftRuby
//
//  See: http://ruby-doc.org/core-2.2.3/File.html
//

import Foundation

public let ALT_SEPARATOR = "/"
public let PATH_SEPARATOR = ":"
public let SEPARATOR = "/"
public let Separator = "/"

public func unixOK( what: string_like, _ returnValue: Int32, file: StaticString?, line: UInt = 0 ) -> Bool {
    if returnValue != 0 {
        if file != nil {
            SRError( "\(what.to_s) failed, returning \(returnValue)", file: file!, line: line )
        }
        return false
    }
    return true
}

public class File : IO {

    let filepath: String

    var umask: Int {
        get {
            let omask = Darwin.umask(0)
            Darwin.umask(omask)
            return Int(omask)
        }
        set {
            Darwin.umask(mode_t(newValue))
        }
    }

    public init?( filepath: string_like, mode: string_like = "r", file: StaticString, line: UInt ) {
        self.filepath = filepath.to_s
        super.init( what: "fopen '\(filepath.to_s)', mode '\(mode.to_s)'", unixFILE: fopen( filepath.to_s, mode.to_s ), file: file, line: line )
        if ifValid() == nil {
            return nil
        }
    }

    // MARK: Class Methods

    public class func new( file_name: string_like, _ mode: string_like = "r", _ perm: Int? = nil, file: StaticString = #file, line: UInt = #line ) -> File? {
        let newFile = File( filepath: file_name, mode: mode, file: file, line: line )
        if perm != nil {
            newFile?.chmod( perm!, file: file, line: line )
        }
        return newFile
    }

    public class func open( file_name: string_like, _ mode: string_like = "r", _ perm: Int? = nil, file: StaticString = #file, line: UInt = #line ) -> File? {
        return new( file_name, mode, perm, file: file, line: line )
    }

    public class func absolute_path( file_name: string_like, _ dir_string: string_like? = nil, file: StaticString = #file, line: UInt = #line ) -> String? {
        var baseURL: NSURL?

        if dir_string != nil {
            baseURL = NSURL( fileURLWithPath: dir_string!.to_s )
        }

        let fileURL = NSURL( fileURLWithPath: file_name.to_s )
        #if swift(>=2.3)
        return NSURL( string: fileURL.absoluteString!, relativeToURL: baseURL )?.absoluteURL!.path ////
        #else
        return NSURL( string: fileURL.absoluteString, relativeToURL: baseURL )?.absoluteURL.path ////
        #endif
    }

    public class func basename( file_name: string_like, _ suffix: string_like? = nil, file: StaticString = #file, line: UInt = #line ) -> String? {
        var file_name = file_name.to_s
        if suffix != nil {
            if suffix!.to_s == ".*" {
                file_name = extremoved( file_name )!
            }
            else {
                SRNotImplemented( "File.basename with suffix ofer than '.*'", file: file, line: line )
            }
        }
        return NSURL( fileURLWithPath: file_name ).lastPathComponent ////
    }

    public class func birthtime( file_name: string_like, file: StaticString = #file, line: UInt = #line ) -> Time? {
        return Stat( file_name, file: file, line: line )?.ctime
    }

    public class func blockdev( file_name: string_like, file: StaticString = #file, line: UInt = #line ) -> Bool? {
        return Stat( file_name, file: file, line: line )?.blockdev
    }

    public class func chardev( file_name: string_like, file: StaticString = #file, line: UInt = #line ) -> Bool? {
        return Stat( file_name, file: file, line: line )?.chardev
    }

    public class func chmod( mode_int: Int, _ file_names: array_like, file: StaticString = #file, line: UInt = #line ) -> Bool {
        var ok = true
        for file_name in file_names.to_a {
            ok = ok && unixOK( "File.chmod '\(file_name)'", Darwin.chmod( file_name, mode_t(mode_int) ), file: file, line: line )
        }
        return ok
    }

    public class func chown( owner_s: string_like?, _ group_s: string_like?, _ file_names: array_like, file: StaticString = #file, line: UInt = #line ) -> Bool {

        var owner_int = owner_s != nil ? Int( owner_s!.to_s ) : nil
        if owner_int == nil && owner_s != nil {
            owner_int = user_uid( owner_s!, file: file, line: line )
            if owner_int == nil {
                return false
            }
        }

        var group_int = group_s != nil ? Int( group_s!.to_s ) : nil
        if group_int == nil && group_s != nil {
            group_int = group_gid( group_s!, file: file, line: line )
            if group_int == nil {
                return false
            }
        }

        var ok = true
        for file_name in file_names.to_a {
            ok = ok && unixOK( "File.chown '\(file_name)'", Darwin.chown( file_name, uid_t(owner_int ?? -1), gid_t(group_int ?? -1) ), file: file, line: line )
        }
        return ok
    }

    public class func user_uid( user_s: string_like, file: StaticString = #file, line: UInt = #line ) -> Int? {
        var buff = [Int8]( count: Int(PATH_MAX), repeatedValue: 0 )
        var ret = UnsafeMutablePointer<passwd>(nil)
        var info = passwd()

        if !unixOK( "File.getpwnam \(user_s.to_s)", getpwnam_r( user_s.to_s, &info, &buff, buff.count, &ret ), file: file, line: line ) {
            return nil
        }

        return Int(info.pw_uid)
    }

    public class func group_gid( group_s: string_like, file: StaticString = #file, line: UInt = #line ) -> Int? {
        var buff = [Int8]( count: Int(PATH_MAX), repeatedValue: 0 )
        var ret = UnsafeMutablePointer<group>(nil)
        var info = group()

        if !unixOK( "File.getgrnam \(group_s.to_s)", getgrnam_r( group_s.to_s, &info, &buff, buff.count, &ret ), file: file, line: line ) {
            return nil
        }

        return Int(info.gr_gid)
    }

    public class func ctime( file_name: string_like, file: StaticString = #file, line: UInt = #line ) -> Time? {
        return birthtime( file_name )
    }

    public class func delete( file_name: string_like, file: StaticString = #file, line: UInt = #line ) -> Bool {
        return unixOK( "File.delete '\(file_name.to_s)'", Darwin.unlink( file_name.to_s ), file: file, line: line )
    }

    public class func directory( file_name: string_like, file: StaticString = #file, line: UInt = #line ) -> Bool? {
        return Stat( file_name, file: file, line: line )?.directory
    }

    public class func dirname( file_name: string_like, file: StaticString = #file, line: UInt = #line ) -> String? {
        return NSURL( fileURLWithPath: file_name.to_s ).URLByDeletingLastPathComponent?.path
    }

    public class func executable( file_name: string_like, file: StaticString = #file, line: UInt = #line ) -> Bool? {
        return Stat( file_name, file: file, line: line )?.executable
    }

    public class func executable_real( file_name: string_like, file: StaticString = #file, line: UInt = #line ) -> Bool? {
        return Stat( file_name, file: file, line: line )?.executable_real
    }

    public class func exist( file_name: string_like, file: StaticString = #file, line: UInt = #line ) -> Bool {
        return Stat( file_name, file: nil ) != nil
    }

    public class func exists( file_name: string_like, file: StaticString = #file, line: UInt = #line ) -> Bool {
        return exist( file_name )
    }

    public class func expand_path( file_name: string_like, _ dir_string: string_like? = nil, file: StaticString = #file, line: UInt = #line ) -> String? {
        return NSURL( fileURLWithPath: file_name.to_s ).URLByStandardizingPath?.path
    }

    public class func extname( file_name: string_like, file: StaticString = #file, line: UInt = #line ) -> String? {
        return NSURL( fileURLWithPath: file_name.to_s ).pathExtension
    }

    public class func file( file_name: string_like, file: StaticString = #file, line: UInt = #line ) -> Bool {
        return Stat( file_name, file: file, line: line )?.file == true
    }

//    public class func fnmatch( pattern: string_like, _ path: string_like, _ flags: string_like? = nil, file: StaticString = #file, line: UInt = #line ) -> Bool {
//        RKNotImplemented( "File.fnmatch" )
//        return false
//    }

    public class func ftype( file_name: string_like, file: StaticString = #file, line: UInt = #line ) -> String? {
        return Stat( file_name, file: file, line: line )?.ftype
    }

    public class func grpowned( file_name: string_like, file: StaticString = #file, line: UInt = #line ) -> Bool? {
        return Stat( file_name, file: file, line: line )?.grpowned
    }

    public class func identical( file_1: string_like, _ file_2: string_like, file: StaticString = #file, line: UInt = #line ) -> Bool {
        if let stat1 = Stat( file_1, file: file, line: line ), stat2 = Stat( file_2, file: file, line: line ) {
            return stat1 == stat2
        }
        return false
    }

    public class func join( strings: [String], file: StaticString = #file, line: UInt = #line ) -> String {
        return strings.joinWithSeparator( SEPARATOR )
    }

    public class func lchmod( mode_int: Int, _ file_names: array_like, file: StaticString = #file, line: UInt = #line ) -> Bool {
        var ok = true
        for file_name in file_names.to_a {
            ok = ok && unixOK( "File.lchmod '\(file_name)'", Darwin.lchmod( file_name, mode_t(mode_int) ), file: file, line: line )
        }
        return ok
    }

    public class func lchown( owner_s: string_like?, _ group_s: string_like?, _ file_names: array_like, file: StaticString = #file, line: UInt = #line ) -> Bool {

        var owner_int = owner_s != nil ? Int( owner_s!.to_s ) : nil
        if owner_int == nil && owner_s != nil {
            owner_int = user_uid( owner_s!, file: file, line: line )
            if owner_int == nil {
                return false
            }
        }

        var group_int = group_s != nil ? Int( group_s!.to_s ) : nil
        if group_int == nil && group_s != nil {
            group_int = group_gid( group_s!, file: file, line: line )
            if group_int == nil {
                return false
            }
       }

        var ok = true
        for file_name in file_names.to_a {
            ok = ok &&  unixOK( "File.lchown '\(file_name.to_s)'", Darwin.lchown( file_name.to_s, uid_t(owner_int ?? -1), gid_t(group_int ?? -1) ), file: file, line: line )
        }
        return ok
    }
    
    public class func link( old_name: string_like, _ new_name: string_like, file: StaticString = #file, line: UInt = #line ) -> Bool {
        return unixOK( "File.link '\(old_name.to_s)' '\(new_name.to_s)'", Darwin.link( old_name.to_s, new_name.to_s ), file: file, line: line )
    }

    public class func lstat( file_name: string_like, file: StaticString = #file, line: UInt = #line ) -> Stat? {
        return Stat( file_name, statLink: true, file: file, line: line )
    }

    public class func mtime( file_name: string_like, file: StaticString = #file, line: UInt = #line ) -> Time? {
        return Stat( file_name, file: file, line: line )?.mtime
    }

    public class func owned( file_name: string_like, file: StaticString = #file, line: UInt = #line ) -> Bool? {
        return Stat( file_name, file: file, line: line )?.owned
    }

    public class func path( path: string_like, file: StaticString = #file, line: UInt = #line ) -> String {
        return path.to_s ////
    }

    public class func pipe( file_name: string_like, file: StaticString = #file, line: UInt = #line ) -> Bool? {
        return Stat( file_name, file: file, line: line )?.pipe
    }

    public class func readable( file_name: string_like, file: StaticString = #file, line: UInt = #line ) -> Bool? {
        return Stat( file_name, file: file, line: line )?.readable
    }

    public class func readable_real( file_name: string_like, file: StaticString = #file, line: UInt = #line ) -> Bool? {
        return Stat( file_name, file: file, line: line )?.readable_real
    }

    public class func readlink( link_name: string_like, file: StaticString = #file, line: UInt = #line ) -> String? {
        var path = [Int8]( count: Int(PATH_MAX+1), repeatedValue: 0 )
        let length = Darwin.readlink( link_name.to_s, &path, path.count ) /// readlinkat for relatives?
        if unixOK( "File.readlink '\(link_name.to_s)'", length == -1 ? 1 : 0, file: file, line: line ) {
            path[length] = 0
            return String( UTF8String: path )
        }
        return nil
    }

    public class func realdirpath( file_name: string_like, _ dir_string: string_like? = nil, file: StaticString = #file, line: UInt = #line ) -> String? {
        if dir_string != nil {
            SRNotImplemented( "File.realdirpath with dir_string argument", file: file, line: line )
        }
        return NSURL( fileURLWithPath: file_name.to_s ).URLByResolvingSymlinksInPath?.path ////
    }
    
    public class func realpath( file_name: string_like, _ dir_string: string_like? = nil, file: StaticString = #file, line: UInt = #line ) -> String? {
        if dir_string != nil {
            SRNotImplemented( "File.realpath with dir_string argument", file: file, line: line )
        }
        return NSURL( fileURLWithPath: file_name.to_s ).URLByResolvingSymlinksInPath?.path ////
    }
    
    public class func extremoved( file_name: string_like, _ suffix: string_like? = nil, file: StaticString = #file, line: UInt = #line ) -> String? {
        return NSURL( fileURLWithPath: file_name.to_s ).URLByDeletingPathExtension?.path
    }

    public class func rename( old_name: string_like, _ new_name: string_like, file: StaticString = #file, line: UInt = #line ) -> Bool {
        return unixOK( "File.rename '\(old_name.to_s)' '\(new_name.to_s)'", Darwin.rename( old_name.to_s, new_name.to_s ), file: file, line: line )
    }

    public class func setgid( file_name: string_like, file: StaticString = #file, line: UInt = #line ) -> Bool? {
        return Stat( file_name, file: file, line: line )?.setgid
    }

    public class func setuid( file_name: string_like, file: StaticString = #file, line: UInt = #line ) -> Bool? {
        return Stat( file_name, file: file, line: line )?.setuid
    }

    public class func size( file_name: string_like, file: StaticString = #file, line: UInt = #line ) -> Int? {
        return Stat( file_name, file: file, line: line )?.size
    }

    public class func socket( file_name: string_like, file: StaticString = #file, line: UInt = #line ) -> Bool? {
        return Stat( file_name, file: file, line: line )?.socket
    }

    public class func split( file_name: string_like, file: StaticString = #file, line: UInt = #line ) -> [String?] {
        return [dirname(file_name), basename(file_name)]
    }

    public class func stat( file_name: string_like, file: StaticString = #file, line: UInt = #line ) -> Stat? {
        return Stat( file_name, file: file, line: line )
    }

    public class func sticky( file_name: string_like, file: StaticString = #file, line: UInt = #line ) -> Bool? {
        return Stat( file_name, file: file, line: line )?.sticky
    }

    public class func symlink( old_name: string_like, _ new_name: string_like, file: StaticString = #file, line: UInt = #line ) -> Bool {
        return unixOK( "File.symlink '\(old_name.to_s)' '\(new_name.to_s)'", Darwin.symlink( old_name.to_s, new_name.to_s ), file: file, line: line )
    }

    public class func truncate( file_name: string_like, _ integer: Int, file: StaticString = #file, line: UInt = #line ) -> Bool {
        return unixOK( "File.truncate '\(file_name.to_s)' \(integer)", Darwin.truncate( file_name.to_s, off_t(integer) ), file: file, line: line )
    }

    public class func unlink( file_name: string_like, file: StaticString = #file, line: UInt = #line ) -> Bool {
        return delete( file_name, file: file, line: line )
    }

    public class func unlink_f( file_name: string_like, file: StaticString = #file, line: UInt = #line ) -> Bool {
        return File.exists( file_name ) || File.lstat( file_name ) != nil ? unlink( file_name, file: file, line: line ) : true
    }

    public class func utime( file_name: string_like, _ actime: int_like, _ modtime: int_like, file: StaticString = #file, line: UInt = #line ) -> Bool {
        var times = utimbuf()
        times.actime = time_t(actime.to_i)
        times.modtime = time_t(modtime.to_i)
        return unixOK( "File.utime '\(file_name.to_s)'", Darwin.utime( file_name.to_s, &times ), file: file, line: line )
    }

    public class func writable( file_name: string_like, file: StaticString = #file, line: UInt = #line ) -> Bool? {
        return Stat( file_name, file: file, line: line )?.writable
    }

    public class func writable_real( file_name: string_like, file: StaticString = #file, line: UInt = #line ) -> Bool? {
        return Stat( file_name, file: file, line: line )?.writable_real
    }

    public class func write( file_name: string_like, string: data_like, file: StaticString = #file, line: UInt = #line ) -> fixnum? {
        return File( filepath: file_name, mode: "w", file: file, line: line )?.write( string )
    }

    public class func zero( file_name: string_like, file: StaticString = #file, line: UInt = #line ) -> Bool? {
        return Stat( file_name, file: file, line: line )?.zero
    }

    // MARK: Instance Methods

    public var atime: Time? {
        return stat?.atime
    }

    public var birthtime: Time? {
        return stat?.birthtime
    }

    public func chmod( mode_int: Int, file: StaticString = #file, line: UInt = #line ) -> Bool {
        return unixOK( "File.chmod \(mode_int) '\(filepath)'", Darwin.chmod( filepath, mode_t(mode_int) ), file: file, line: line )
    }

    public func chown( owner_s: string_like?, _ group_s: string_like?, file: StaticString = #file, line: UInt = #line ) -> Bool {

        var owner_int = owner_s != nil ? Int( owner_s!.to_s ) : nil
        if owner_int == nil && owner_s != nil {
            owner_int = File.user_uid( owner_s!, file: file, line: line )
            if owner_int == nil {
                return false
            }
        }

        var group_int = group_s != nil ? Int( group_s!.to_s ) : nil
        if group_int == nil && group_s != nil {
            group_int = File.group_gid( group_s!, file: file, line: line )
            if group_int == nil {
                return false
            }
        }

        return unixOK( "File.chown '\(filepath)' \(owner_int) \(group_int)", Darwin.chown( filepath,
            uid_t(owner_int ?? -1), gid_t(group_int ?? -1) ), file: file, line: line )
    }

    public var ctime: Time? {
        return birthtime
    }

    public func flock( locking_constant: Int, file: StaticString = #file, line: UInt = #line ) -> Bool {
        return unixOK( "File.flock '\(filepath)' \(locking_constant)", Darwin.flock( Int32(fileno), Int32(locking_constant) ), file: file, line: line )
    }

    public var lstat: Stat? {
        return Stat( filepath, statLink: true, file: #file, line: #line )
    }

    public var mtime: Time? {
        return stat?.mtime
    }

    public var path: String {
        return filepath
    }

    public var to_path: String {
        return filepath
    }

    public func truncate( integer: Int, file: StaticString = #file, line: UInt = #line ) -> Bool {
        return unixOK( "File.truncate '\(filepath)' \(integer)", Darwin.truncate( filepath, off_t(integer) ), file: file, line: line )
    }

}
