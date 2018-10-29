//
//  File.swift
//  SwiftRuby
//
//  Created by John Holdsworth on 26/09/2015.
//  Copyright © 2015 John Holdsworth. All rights reserved.
//
//  $Id: //depot/SwiftRuby/File.swift#12 $
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

@discardableResult
public func unixOK( _ what: string_like, _ returnValue: Int32, file: StaticString?, line: UInt = 0 ) -> Bool {
    if returnValue != 0 {
        if file != nil {
            SRError( "\(what.to_s) failed, returning \(returnValue)", file: file!, line: line )
        }
        return false
    }
    return true
}

open class File : IO {

    let filepath: String

    var umask: Int {
        get {
            let omask = Darwin.umask(0)
            _ = Darwin.umask(omask)
            return Int(omask)
        }
        set {
            _ = Darwin.umask(mode_t(newValue))
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

    open class func new( _ file_name: string_like, _ mode: string_like = "r", _ perm: Int? = nil, file: StaticString = #file, line: UInt = #line ) -> File? {
        let newFile = File( filepath: file_name, mode: mode, file: file, line: line )
        if perm != nil {
            _ = newFile?.chmod( perm!, file: file, line: line )
        }
        return newFile
    }

    open class func open( _ file_name: string_like, _ mode: string_like = "r", _ perm: Int? = nil, file: StaticString = #file, line: UInt = #line ) -> File? {
        return new( file_name, mode, perm, file: file, line: line )
    }

    open class func absolute_path( _ file_name: string_like, _ dir_string: string_like? = nil, file: StaticString = #file, line: UInt = #line ) -> String? {
        var baseURL: URL?

        if dir_string != nil {
            baseURL = URL( fileURLWithPath: dir_string!.to_s )
        }

        let fileURL = URL( fileURLWithPath: file_name.to_s )
        #if swift(>=2.3)
        return URL( string: fileURL.absoluteString, relativeTo: baseURL )?.absoluteURL.path ////
        #else
        return NSURL( string: fileURL.absoluteString, relativeToURL: baseURL )?.absoluteURL.path ////
        #endif
    }

    open class func basename( _ file_name: string_like, _ suffix: string_like? = nil, file: StaticString = #file, line: UInt = #line ) -> String? {
        var file_name = file_name.to_s
        if suffix != nil {
            if suffix!.to_s == ".*" {
                file_name = extremoved( file_name )!
            }
            else {
                SRNotImplemented( "File.basename with suffix ofer than '.*'", file: file, line: line )
            }
        }
        return URL( fileURLWithPath: file_name ).lastPathComponent ////
    }

    open class func birthtime( _ file_name: string_like, file: StaticString = #file, line: UInt = #line ) -> Time? {
        return Stat( file_name, file: file, line: line )?.ctime
    }

    open class func blockdev( _ file_name: string_like, file: StaticString = #file, line: UInt = #line ) -> Bool? {
        return Stat( file_name, file: file, line: line )?.blockdev
    }

    open class func chardev( _ file_name: string_like, file: StaticString = #file, line: UInt = #line ) -> Bool? {
        return Stat( file_name, file: file, line: line )?.chardev
    }

    @discardableResult
    open class func chmod( _ mode_int: Int, _ file_names: array_like, file: StaticString = #file, line: UInt = #line ) -> Bool {
        var ok = true
        for file_name in file_names.to_a {
            ok = ok && unixOK( "File.chmod '\(file_name)'", Darwin.chmod( file_name, mode_t(mode_int) ), file: file, line: line )
        }
        return ok
    }

    open class func chown( _ owner_s: string_like?, _ group_s: string_like?, _ file_names: array_like, file: StaticString = #file, line: UInt = #line ) -> Bool {

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

    open class func user_uid( _ user_s: string_like, file: StaticString = #file, line: UInt = #line ) -> Int? {
        var buff = [Int8]( repeating: 0, count: Int(PATH_MAX) )
        var ret: UnsafeMutablePointer<passwd>?
        var info = passwd()

        if !unixOK( "File.getpwnam \(user_s.to_s)", getpwnam_r( user_s.to_s, &info, &buff, buff.count, &ret ), file: file, line: line ) {
            return nil
        }

        return Int(info.pw_uid)
    }

    open class func group_gid( _ group_s: string_like, file: StaticString = #file, line: UInt = #line ) -> Int? {
        var buff = [Int8]( repeating: 0, count: Int(PATH_MAX) )
        var ret: UnsafeMutablePointer<group>?
        var info = group()

        if !unixOK( "File.getgrnam \(group_s.to_s)", getgrnam_r( group_s.to_s, &info, &buff, buff.count, &ret ), file: file, line: line ) {
            return nil
        }

        return Int(info.gr_gid)
    }

    open class func ctime( _ file_name: string_like, file: StaticString = #file, line: UInt = #line ) -> Time? {
        return birthtime( file_name )
    }

    open class func delete( _ file_name: string_like, file: StaticString = #file, line: UInt = #line ) -> Bool {
        return unixOK( "File.delete '\(file_name.to_s)'", Darwin.unlink( file_name.to_s ), file: file, line: line )
    }

    open class func directory( _ file_name: string_like, file: StaticString = #file, line: UInt = #line ) -> Bool? {
        return Stat( file_name, file: file, line: line )?.directory
    }

    open class func dirname( _ file_name: string_like, file: StaticString = #file, line: UInt = #line ) -> String? {
        return NSURL( fileURLWithPath: file_name.to_s ).deletingLastPathComponent?.path
    }

    open class func executable( _ file_name: string_like, file: StaticString = #file, line: UInt = #line ) -> Bool? {
        return Stat( file_name, file: file, line: line )?.executable
    }

    open class func executable_real( _ file_name: string_like, file: StaticString = #file, line: UInt = #line ) -> Bool? {
        return Stat( file_name, file: file, line: line )?.executable_real
    }

    open class func exist( _ file_name: string_like, file: StaticString = #file, line: UInt = #line ) -> Bool {
        return Stat( file_name, file: nil ) != nil
    }

    open class func exists( _ file_name: string_like, file: StaticString = #file, line: UInt = #line ) -> Bool {
        return exist( file_name )
    }

    open class func expand_path( _ file_name: string_like, _ dir_string: string_like? = nil, file: StaticString = #file, line: UInt = #line ) -> String? {
        return NSURL( fileURLWithPath: file_name.to_s ).standardized?.path
    }

    open class func extname( _ file_name: string_like, file: StaticString = #file, line: UInt = #line ) -> String? {
        return URL( fileURLWithPath: file_name.to_s ).pathExtension
    }

    open class func file( _ file_name: string_like, file: StaticString = #file, line: UInt = #line ) -> Bool {
        return Stat( file_name, file: file, line: line )?.file == true
    }

//    public class func fnmatch( pattern: string_like, _ path: string_like, _ flags: string_like? = nil, file: StaticString = #file, line: UInt = #line ) -> Bool {
//        RKNotImplemented( "File.fnmatch" )
//        return false
//    }

    open class func ftype( _ file_name: string_like, file: StaticString = #file, line: UInt = #line ) -> String? {
        return Stat( file_name, file: file, line: line )?.ftype
    }

    open class func grpowned( _ file_name: string_like, file: StaticString = #file, line: UInt = #line ) -> Bool? {
        return Stat( file_name, file: file, line: line )?.grpowned
    }

    open class func identical( _ file_1: string_like, _ file_2: string_like, file: StaticString = #file, line: UInt = #line ) -> Bool {
        if let stat1 = Stat( file_1, file: file, line: line ), let stat2 = Stat( file_2, file: file, line: line ) {
            return stat1 == stat2
        }
        return false
    }

    open class func join( _ strings: [String], file: StaticString = #file, line: UInt = #line ) -> String {
        return strings.joined( separator: SEPARATOR )
    }

    open class func lchmod( _ mode_int: Int, _ file_names: array_like, file: StaticString = #file, line: UInt = #line ) -> Bool {
        var ok = true
        for file_name in file_names.to_a {
            ok = ok && unixOK( "File.lchmod '\(file_name)'", Darwin.lchmod( file_name, mode_t(mode_int) ), file: file, line: line )
        }
        return ok
    }

    open class func lchown( _ owner_s: string_like?, _ group_s: string_like?, _ file_names: array_like, file: StaticString = #file, line: UInt = #line ) -> Bool {

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
    
    open class func link( _ old_name: string_like, _ new_name: string_like, file: StaticString = #file, line: UInt = #line ) -> Bool {
        return unixOK( "File.link '\(old_name.to_s)' '\(new_name.to_s)'", Darwin.link( old_name.to_s, new_name.to_s ), file: file, line: line )
    }

    open class func lstat( _ file_name: string_like, file: StaticString = #file, line: UInt = #line ) -> Stat? {
        return Stat( file_name, statLink: true, file: file, line: line )
    }

    open class func mtime( _ file_name: string_like, file: StaticString = #file, line: UInt = #line ) -> Time? {
        return Stat( file_name, file: file, line: line )?.mtime
    }

    open class func owned( _ file_name: string_like, file: StaticString = #file, line: UInt = #line ) -> Bool? {
        return Stat( file_name, file: file, line: line )?.owned
    }

    open class func path( _ path: string_like, file: StaticString = #file, line: UInt = #line ) -> String {
        return path.to_s ////
    }

    open class func pipe( _ file_name: string_like, file: StaticString = #file, line: UInt = #line ) -> Bool? {
        return Stat( file_name, file: file, line: line )?.pipe
    }

    open class func readable( _ file_name: string_like, file: StaticString = #file, line: UInt = #line ) -> Bool? {
        return Stat( file_name, file: file, line: line )?.readable
    }

    open class func readable_real( _ file_name: string_like, file: StaticString = #file, line: UInt = #line ) -> Bool? {
        return Stat( file_name, file: file, line: line )?.readable_real
    }

    open class func readlink( _ link_name: string_like, file: StaticString = #file, line: UInt = #line ) -> String? {
        var path = [Int8]( repeating: 0, count: Int(PATH_MAX+1) )
        let length = Darwin.readlink( link_name.to_s, &path, path.count ) /// readlinkat for relatives?
        if unixOK( "File.readlink '\(link_name.to_s)'", length == -1 ? 1 : 0, file: file, line: line ) {
            path[length] = 0
            return String( validatingUTF8: path )
        }
        return nil
    }

    open class func realdirpath( _ file_name: string_like, _ dir_string: string_like? = nil, file: StaticString = #file, line: UInt = #line ) -> String? {
        if dir_string != nil {
            SRNotImplemented( "File.realdirpath with dir_string argument", file: file, line: line )
        }
        return NSURL( fileURLWithPath: file_name.to_s ).resolvingSymlinksInPath?.path ////
    }
    
    open class func realpath( _ file_name: string_like, _ dir_string: string_like? = nil, file: StaticString = #file, line: UInt = #line ) -> String? {
        if dir_string != nil {
            SRNotImplemented( "File.realpath with dir_string argument", file: file, line: line )
        }
        return NSURL( fileURLWithPath: file_name.to_s ).resolvingSymlinksInPath?.path ////
    }
    
    open class func extremoved( _ file_name: string_like, _ suffix: string_like? = nil, file: StaticString = #file, line: UInt = #line ) -> String? {
        return NSURL( fileURLWithPath: file_name.to_s ).deletingPathExtension?.path
    }

    open class func rename( _ old_name: string_like, _ new_name: string_like, file: StaticString = #file, line: UInt = #line ) -> Bool {
        return unixOK( "File.rename '\(old_name.to_s)' '\(new_name.to_s)'", Darwin.rename( old_name.to_s, new_name.to_s ), file: file, line: line )
    }

    open class func setgid( _ file_name: string_like, file: StaticString = #file, line: UInt = #line ) -> Bool? {
        return Stat( file_name, file: file, line: line )?.setgid
    }

    open class func setuid( _ file_name: string_like, file: StaticString = #file, line: UInt = #line ) -> Bool? {
        return Stat( file_name, file: file, line: line )?.setuid
    }

    open class func size( _ file_name: string_like, file: StaticString = #file, line: UInt = #line ) -> Int? {
        return Stat( file_name, file: file, line: line )?.size
    }

    open class func socket( _ file_name: string_like, file: StaticString = #file, line: UInt = #line ) -> Bool? {
        return Stat( file_name, file: file, line: line )?.socket
    }

    open class func split( _ file_name: string_like, file: StaticString = #file, line: UInt = #line ) -> [String?] {
        return [dirname(file_name), basename(file_name)]
    }

    open class func stat( _ file_name: string_like, file: StaticString = #file, line: UInt = #line ) -> Stat? {
        return Stat( file_name, file: file, line: line )
    }

    open class func sticky( _ file_name: string_like, file: StaticString = #file, line: UInt = #line ) -> Bool? {
        return Stat( file_name, file: file, line: line )?.sticky
    }

    open class func symlink( _ old_name: string_like, _ new_name: string_like, file: StaticString = #file, line: UInt = #line ) -> Bool {
        return unixOK( "File.symlink '\(old_name.to_s)' '\(new_name.to_s)'", Darwin.symlink( old_name.to_s, new_name.to_s ), file: file, line: line )
    }

    open class func truncate( _ file_name: string_like, _ integer: Int, file: StaticString = #file, line: UInt = #line ) -> Bool {
        return unixOK( "File.truncate '\(file_name.to_s)' \(integer)", Darwin.truncate( file_name.to_s, off_t(integer) ), file: file, line: line )
    }

    open class func unlink( _ file_name: string_like, file: StaticString = #file, line: UInt = #line ) -> Bool {
        return delete( file_name, file: file, line: line )
    }

    open class func unlink_f( _ file_name: string_like, file: StaticString = #file, line: UInt = #line ) -> Bool {
        return File.exists( file_name ) || File.lstat( file_name ) != nil ? unlink( file_name, file: file, line: line ) : true
    }

    open class func utime( _ file_name: string_like, _ actime: int_like, _ modtime: int_like, file: StaticString = #file, line: UInt = #line ) -> Bool {
        var times = utimbuf()
        times.actime = time_t(actime.to_i)
        times.modtime = time_t(modtime.to_i)
        return unixOK( "File.utime '\(file_name.to_s)'", Darwin.utime( file_name.to_s, &times ), file: file, line: line )
    }

    open class func writable( _ file_name: string_like, file: StaticString = #file, line: UInt = #line ) -> Bool? {
        return Stat( file_name, file: file, line: line )?.writable
    }

    open class func writable_real( _ file_name: string_like, file: StaticString = #file, line: UInt = #line ) -> Bool? {
        return Stat( file_name, file: file, line: line )?.writable_real
    }

    open class func write( _ file_name: string_like, string: data_like, file: StaticString = #file, line: UInt = #line ) -> fixnum? {
        return File( filepath: file_name, mode: "w", file: file, line: line )?.write( string )
    }

    open class func zero( _ file_name: string_like, file: StaticString = #file, line: UInt = #line ) -> Bool? {
        return Stat( file_name, file: file, line: line )?.zero
    }

    // MARK: Instance Methods

    open var atime: Time? {
        return stat?.atime
    }

    open var birthtime: Time? {
        return stat?.birthtime
    }

    open func chmod( _ mode_int: Int, file: StaticString = #file, line: UInt = #line ) -> Bool {
        return unixOK( "File.chmod \(mode_int) '\(filepath)'", Darwin.chmod( filepath, mode_t(mode_int) ), file: file, line: line )
    }

    open func chown( _ owner_s: string_like?, _ group_s: string_like?, file: StaticString = #file, line: UInt = #line ) -> Bool {

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

    open var ctime: Time? {
        return birthtime
    }

//    open func flock( _ locking_constant: Int, file: StaticString = #file, line: UInt = #line ) -> Bool {
//        return unixOK( "File.flock '\(filepath)' \(locking_constant)", Darwin.flock( Int32(fileno), Int32(locking_constant) ), file: file, line: line )
//    }

    open var lstat: Stat? {
        return Stat( filepath, statLink: true, file: #file, line: #line )
    }

    open var mtime: Time? {
        return stat?.mtime
    }

    open var path: String {
        return filepath
    }

    open var to_path: String {
        return filepath
    }

    open func truncate( _ integer: Int, file: StaticString = #file, line: UInt = #line ) -> Bool {
        return unixOK( "File.truncate '\(filepath)' \(integer)", Darwin.truncate( filepath, off_t(integer) ), file: file, line: line )
    }

}
