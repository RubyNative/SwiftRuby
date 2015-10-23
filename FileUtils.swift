//
//  public class func swift
//  SwiftRuby
//
//  Created by John Holdsworth on 30/09/2015.
//  Copyright © 2015 John Holdsworth. All rights reserved.
//
//  $Id: //depot/RubyNative/File.swift#3 $
//
//  Repo: https://github.com/RubyNative/SwiftRuby
//
//  See: http://ruby-doc.org/stdlib-2.2.3/libdoc/fileutils/rdoc/FileUtils.html
//

import Darwin

public var STATUS = 0

public func systemOK( command: string_like, file: StaticString? = __FILE__, line: UInt = __LINE__ ) -> Bool {
    STATUS = Int(system( command.to_s ))
    if STATUS != 0 {
        if file != nil {
            SRLog( "system call '\(command.to_s)' failed", file: file!, line: line )
        }
        return false
    }
    STATUS >>= 8
    return true
}

public class FileUtils {

    public var pwd: String? {
        return Dir.getwd
    }
    
    private class func expand( list: array_like ) -> String {
        return list.to_a.map { "\""+$0.stringByReplacingOccurrencesOfString("\"", withString: "\\\"")+"\"" }
            .joinWithSeparator( " " )
    }

    public class func cd( dir: string_like, options: [String]?, file: StaticString = __FILE__, line: UInt = __LINE__ ) -> Bool {
        return Dir.chdir( dir, file: file, line: line )
    }

//    public class func cd( dir: string_like, options: [String]?, file: StaticString = __FILE__, line: UInt = __LINE__ ) -> Bool { {|dir| .... }

    public class func chmod( mode: string_like, _ list: array_like, _ options: [String]? = nil, file: StaticString = __FILE__, line: UInt = __LINE__ ) -> Bool {
        return systemOK( "chmod \(mode.to_s) \(expand( list ))", file: file, line: line )
    }

    public class func chmod_R( mode: string_like, _ list: array_like, _ options: [String]? = nil, file: StaticString = __FILE__, line: UInt = __LINE__ ) -> Bool {
        return systemOK( "chmod -R \(mode.to_s) \(expand( list ))", file: file, line: line )
    }

    public class func chown( user: string_like, _ group: string_like?, _ list: array_like, _ options: [String]? = nil, file: StaticString = __FILE__, line: UInt = __LINE__ ) -> Bool {
        let whoto = user.to_s + (group != nil ? ":"+group!.to_s : "")
        return systemOK( "chown \(whoto) \(expand( list ))", file: file, line: line )
    }

    public class func chown_R( user: string_like, _ group: string_like?, _ list: array_like, _ options: [String]? = nil, file: StaticString = __FILE__, line: UInt = __LINE__ ) -> Bool {
        let whoto = user.to_s + (group != nil ? ":"+group!.to_s : "")
        return systemOK( "chown -R \(whoto) \(expand( list ))", file: file, line: line )
    }

    public class func cmp( src: string_like, _ dest: string_like, _ options: [String]? = nil, file: StaticString = __FILE__, line: UInt = __LINE__ ) -> Bool {
        return compare_file( src, dest, options, file: file, line: line )
    }

    public class func compare_file( src: string_like, _ dest: string_like, _ options: [String]? = nil, file: StaticString = __FILE__, line: UInt = __LINE__ ) -> Bool {
        return systemOK( "diff -q \"\(src.to_s)\" \"\(dest.to_s)\" >/dev/null", file: file, line: line )
    }

    public class func compare_stream( a: IO, _ b: IO, _ options: [String]? = nil, file: StaticString = __FILE__, line: UInt = __LINE__ ) -> Bool {
        if let a = a.read(), b = b.read() {
            return a.length == b.length && memcmp( a.bytes, b.bytes, a.length ) == 0
        }
        return false
    }

    public class func copy( src: string_like, _ dest: string_like, _ options: [String]? = nil, file: StaticString = __FILE__, line: UInt = __LINE__ ) -> Bool {
        return cp( src, dest, options, file: file, line: line )
    }

    public class func copy_entry( src: string_like, _ dest: string_like, _ preserve: Bool = false, _ options: [String]? = nil, file: StaticString = __FILE__, line: UInt = __LINE__ ) -> Bool {
        return rsync( [src.to_s], dest, preserve ? "-rlpogt" : "-rlp", options, file: file, line: line )
    }

    public class func copy_file( src: string_like, _ dest: string_like, _ options: [String]? = nil, file: StaticString = __FILE__, line: UInt = __LINE__ ) -> Bool {
        return cp( src, dest, options, file: file, line: line )
    }

    public class func copy_stream( src: IO, _ dest: IO, _ options: [String]? = nil, file: StaticString = __FILE__, line: UInt = __LINE__ ) -> Bool {
        if let data = src.read() {
            dest.write( data )
            return true
        }
        return false
    }

    public class func cat( list: array_like, _ dir: string_like, _ options: [String]? = nil, file: StaticString = __FILE__, line: UInt = __LINE__ ) -> Bool {
        return systemOK( "cat \(expand( list )) >\"\(dir.to_s)\"", file: file, line: line )
    }

    public class func cp( list: array_like, _ dir: string_like, _ options: [String]? = nil, file: StaticString = __FILE__, line: UInt = __LINE__ ) -> Bool {
        return systemOK( "cp \(expand( list )) \"\(dir.to_s)\"", file: file, line: line )
    }

    public class func cp_r( list: array_like, _ dir: string_like, _ options: [String]? = nil, file: StaticString = __FILE__, line: UInt = __LINE__ ) -> Bool {
        return systemOK( "cp -r \(expand( list )) \"\(dir.to_s)\"", file: file, line: line )
    }
    
    public class func cp_rf( list: array_like, _ dir: string_like, _ options: [String]? = nil, file: StaticString = __FILE__, line: UInt = __LINE__ ) -> Bool {
        return systemOK( "cp -rf \(expand( list )) \"\(dir.to_s)\"", file: file, line: line )
    }
    
    public class func identical( src: string_like, _ dest: string_like, _ options: [String]? = nil, file: StaticString = __FILE__, line: UInt = __LINE__ ) -> Bool {
        return compare_file( src, dest, options, file: file, line: line )
    }

    public class func install( src: string_like, _ dest: string_like, _ mode: string_like?, options: [String]? = nil, file: StaticString = __FILE__, line: UInt = __LINE__ ) -> Bool {
        let mode = mode != nil ? " -m " + mode!.to_s : ""
        return systemOK( "install\(mode) \"\(src.to_s)\" \"\(dest.to_s)\"", file: file, line: line )
    }

    public class func link( old: string_like, _ new: string_like, _ options: [String]? = nil, file: StaticString = __FILE__, line: UInt = __LINE__ ) -> Bool {
        return ln( old, new, options, file: file, line: line )
    }

    public class func ln( list: array_like, _ destdir: string_like, _ options: [String]? = nil, file: StaticString = __FILE__, line: UInt = __LINE__ ) -> Bool {
        return systemOK( "ln \(expand( list )) \"\(destdir.to_s)\"", file: file, line: line )
    }

    public class func ln_s( list: array_like, _ destdir: string_like, _ options: [String]? = nil, file: StaticString = __FILE__, line: UInt = __LINE__ ) -> Bool {
        return systemOK( "ln -s \(expand( list )) \"\(destdir.to_s)\"", file: file, line: line )
    }

    public class func ln_sf( src: string_like, _ dest: string_like, _ options: [String]? = nil, file: StaticString = __FILE__, line: UInt = __LINE__ ) -> Bool {
        return systemOK( "ln -sf \"\(src.to_s)\" \"\(dest.to_s)\"", file: file, line: line )
    }

    public class func makedirs( list: array_like, _ options: [String]? = nil, file: StaticString = __FILE__, line: UInt = __LINE__ ) -> Bool {
        return mkdir_p( list, options, file: file, line: line )
    }
    
    public class func mkdir( list: array_like, _ options: [String]? = nil, file: StaticString = __FILE__, line: UInt = __LINE__ ) -> Bool {
        return systemOK( "mkdir \(expand( list ))", file: file, line: line )
    }

    public class func mkdir_p( list: array_like, _ options: [String]? = nil, file: StaticString = __FILE__, line: UInt = __LINE__ ) -> Bool {
            return systemOK( "mkdir -p \(expand( list ))", file: file, line: line )
    }

    public class func mkpath( list: array_like, _ options: [String]? = nil, file: StaticString = __FILE__, line: UInt = __LINE__ ) -> Bool {
        return mkdir_p( list, options, file: file, line: line )
    }

    public class func mv( list: array_like, _ dir: string_like, _ options: [String]? = nil, file: StaticString = __FILE__, line: UInt = __LINE__ ) -> Bool {
        return systemOK( "mv \(expand( list )) \"\(dir.to_s)\"", file: file, line: line )
    }
    
    public class func mv_f( list: array_like, _ dir: string_like, _ options: [String]? = nil, file: StaticString = __FILE__, line: UInt = __LINE__ ) -> Bool {
        return systemOK( "mv -f \(expand( list )) \"\(dir.to_s)\"", file: file, line: line )
    }
    
    public class func remove_dir( dir: string_like, _ force: Bool = false, _ options: [String]? = nil, file: StaticString = __FILE__, line: UInt = __LINE__ ) -> Bool {
        return force ? rm_rf( dir, options, file: file, line: line ) : rm_r( [dir.to_s], options, file: file, line: line )
    }

    public class func remove_entry( dir: string_like, _ force: Bool = false, _ options: [String]? = nil, file: StaticString = __FILE__, line: UInt = __LINE__ ) -> Bool {
        return force ? rm_rf( dir, options, file: file, line: line ) : rm_r( [dir.to_s], options, file: file, line: line )
    }

    public class func remove_entry_secure( dir: string_like, _ options: [String]? = nil, file: StaticString = __FILE__, line: UInt = __LINE__ ) -> Bool {
        return systemOK( "rm -rfP \"\(dir.to_s)\"", file: file, line: line )
    }

    public class func remove_file( path: string_like, _ options: [String]? = nil, file: StaticString = __FILE__, line: UInt = __LINE__ ) -> Bool {
        return rm( [path.to_s], options, file: file, line: line )
    }

    public class func rm( list: array_like, _ options: [String]? = nil, file: StaticString = __FILE__, line: UInt = __LINE__ ) -> Bool {
        return systemOK( "rm \(expand( list ))", file: file, line: line )
    }
    
    public class func rm_f( list: array_like, _ options: [String]? = nil, file: StaticString = __FILE__, line: UInt = __LINE__ ) -> Bool {
        return systemOK( "rm -f \(expand( list ))", file: file, line: line )
    }
    
    public class func rm_r( list: array_like, _ options: [String]? = nil, file: StaticString = __FILE__, line: UInt = __LINE__ ) -> Bool {
        return systemOK( "rm -r \(expand( list ))", file: file, line: line )
    }

    public class func rm_rf( list: array_like, _ options: [String]? = nil, file: StaticString = __FILE__, line: UInt = __LINE__ ) -> Bool {
        return systemOK( "rm -rf \(expand( list.to_a ))", file: file, line: line )
    }

    public class func rmdir( list: array_like, _ options: [String]? = nil, file: StaticString = __FILE__, line: UInt = __LINE__ ) -> Bool {
        return systemOK( "rmdir \(expand( list ))", file: file, line: line )
    }

    public class func rmtree( list: array_like, _ options: [String]? = nil, file: StaticString = __FILE__, line: UInt = __LINE__ ) -> Bool {
        return rm_rf( list, options, file: file, line: line )
    }

    public class func safe_unlink( list: array_like, _ options: [String]? = nil, file: StaticString = __FILE__, line: UInt = __LINE__ ) -> Bool {
        return rm_f( list, options, file: file, line: line )
    }

    public class func symlink( src: string_like, _ dest: string_like, _ options: [String]? = nil, file: StaticString = __FILE__, line: UInt = __LINE__ ) -> Bool {
        return ln_s( src, dest, options, file: file, line: line )
    }

    public class func rsync( list: array_like, _ dest: string_like, _ args: string_like = "-a", _ options: [String]? = nil, file: StaticString = __FILE__, line: UInt = __LINE__ ) -> Bool {
        return systemOK( "rsync \(args) \(expand( list )) \"\(dest.to_s)\"", file: file, line: line )
    }

    public class func touch( list: array_like, _ options: [String]? = nil, file: StaticString = __FILE__, line: UInt = __LINE__ ) -> Bool {
        return systemOK( "touch \(expand( list ))", file: file, line: line )
    }
    
    public class func touch_f( list: array_like, _ options: [String]? = nil, file: StaticString = __FILE__, line: UInt = __LINE__ ) -> Bool {
        return systemOK( "touch -f \(expand( list ))", file: file, line: line )
    }

    public class func uptodate( new: string_like, old_list: array_like, file: StaticString = __FILE__, line: UInt = __LINE__ ) -> Bool {
        let new_time = Stat( new, file: nil )?.mtime.to_f ?? 0
        for old in old_list.to_a {
            if Stat( old, file: file, line: line )?.mtime.to_f > new_time {
                return false
            }
        }
        return true
    }

}
