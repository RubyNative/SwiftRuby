//
//  public class func swift
//  RubyNative
//
//  Created by John Holdsworth on 30/09/2015.
//  Copyright © 2015 John Holdsworth. All rights reserved.
//
//  $Id: //depot/RubyNative/File.swift#3 $
//
//  Repo: https://github.com/RubyNative/RubyNative
//
//  See: http://ruby-doc.org/stdlib-2.2.3/libdoc/fileutils/rdoc/public class func html
//

import Foundation

public var STATUS = 0

public func systemOK( command: to_s_protocol, file: String?, line: Int = 0 ) -> Bool {
    STATUS = Int(system( command.to_s ) >> 8)
    if STATUS != 0 {
        if file != nil {
            if warningDisposition != .Ignore {
                print( "RubyNative: system call '\(command.to_s)' failed: \(String( UTF8String: strerror( errno ) )!) at \(file!)#\(line)")
            }
            if warningDisposition == .Fatal {
                fatalError()
            }
        }
        return false
    }
    return true
}

public class FileUtils {

    public var pwd: String? {
        return Dir.getwd

    }
    
    private class func expand( list: [String] ) -> String {
        return list.map { "\""+$0.stringByReplacingOccurrencesOfString("\"", withString: "\\\"")+"\"" }
            .joinWithSeparator( " " )
    }

    public class func cd( dir: to_s_protocol, options: [String]?, file: String = __FILE__, line: Int = __LINE__ ) -> Bool {
        return Dir.chdir( dir, file: file, line: line )
    }

//    public class func cd( dir: to_s_protocol, options: [String]?, file: String = __FILE__, line: Int = __LINE__ ) -> Bool { {|dir| .... }

    public class func chmod( mode: to_s_protocol, _ list: [String], _ options: [String]? = nil, file: String = __FILE__, line: Int = __LINE__ ) -> Bool {
        return systemOK( "chmod \(mode.to_s) \(expand( list ))", file: file, line: line )
    }

    public class func chmod_R( mode: to_s_protocol, _ list: [String], _ options: [String]? = nil, file: String = __FILE__, line: Int = __LINE__ ) -> Bool {
        return systemOK( "chmod -R \(mode.to_s) \(expand( list ))", file: file, line: line )
    }

    public class func chown( user: to_s_protocol, _ group: to_s_protocol?, _ list: [String], _ options: [String]? = nil, file: String = __FILE__, line: Int = __LINE__ ) -> Bool {
        let whoto = user.to_s + (group != nil ? ":"+group!.to_s : "")
        return systemOK( "chown \(whoto) \(expand( list ))", file: file, line: line )
    }

    public class func chown_R( user: to_s_protocol, _ group: to_s_protocol?, _ list: [String], _ options: [String]? = nil, file: String = __FILE__, line: Int = __LINE__ ) -> Bool {
        let whoto = user.to_s + (group != nil ? ":"+group!.to_s : "")
        return systemOK( "chown -R \(whoto) \(expand( list ))", file: file, line: line )
    }

    public class func cmp( src: to_s_protocol, _ dest: to_s_protocol, _ options: [String]? = nil, file: String = __FILE__, line: Int = __LINE__ ) -> Bool {
        return compare_file( src, dest, options, file: file, line: line )
    }

    public class func compare_file( src: to_s_protocol, _ dest: to_s_protocol, _ options: [String]? = nil, file: String = __FILE__, line: Int = __LINE__ ) -> Bool {
        return systemOK( "diff -q \"\(src.to_s)\" \"\(dest.to_s)\" >/dev/null", file: file, line: line )
    }

    public class func compare_stream( a: IO, _ b: IO, _ options: [String]? = nil, file: String = __FILE__, line: Int = __LINE__ ) -> Bool {
        if let a = a.read(), b = b.read() {
            return a.length == b.length && memcmp( a.bytes, b.bytes, a.length ) == 0
        }
        return false
    }

    public class func copy( src: to_s_protocol, _ dest: to_s_protocol, _ options: [String]? = nil, file: String = __FILE__, line: Int = __LINE__ ) -> Bool {
        return cp( src, dest, options, file: file, line: line )
    }

    public class func copy_entry( src: to_s_protocol, _ dest: to_s_protocol, _ preserve: Bool = false, _ options: [String]? = nil, file: String = __FILE__, line: Int = __LINE__ ) -> Bool {
        return rsync( [src.to_s], dest, preserve ? "-rlpogt" : "-rlp", options, file: file, line: line )
    }

    public class func copy_file( src: to_s_protocol, _ dest: to_s_protocol, _ options: [String]? = nil, file: String = __FILE__, line: Int = __LINE__ ) -> Bool {
        return cp( src, dest, options, file: file, line: line )
    }

    public class func copy_stream( src: IO, _ dest: IO, _ options: [String]? = nil, file: String = __FILE__, line: Int = __LINE__ ) -> Bool {
        if let data = src.read() {
            dest.write( data )
            return true
        }
        return false
    }

    public class func cp( src: to_s_protocol, _ dest: to_s_protocol, _ options: [String]? = nil, file: String = __FILE__, line: Int = __LINE__ ) -> Bool {
        return cp( [src.to_s], dest, options, file: file, line: line )
    }

    public class func cp( list: [String], _ dir: to_s_protocol, _ options: [String]? = nil, file: String = __FILE__, line: Int = __LINE__ ) -> Bool {
        return systemOK( "cp \(expand( list )) \"\(dir.to_s)\"", file: file, line: line )
    }

    public class func cp_r( src: to_s_protocol, _ dest: to_s_protocol, _ options: [String]? = nil, file: String = __FILE__, line: Int = __LINE__ ) -> Bool {
        return cp_r( [src.to_s], dest, options, file: file, line: line )
    }

    public class func cp_r( list: [String], _ dir: to_s_protocol, _ options: [String]? = nil, file: String = __FILE__, line: Int = __LINE__ ) -> Bool {
        return systemOK( "cp -r \(expand( list )) \"\(dir.to_s)\"", file: file, line: line )
    }
    
    public class func cp_rf( src: to_s_protocol, _ dest: to_s_protocol, _ options: [String]? = nil, file: String = __FILE__, line: Int = __LINE__ ) -> Bool {
        return cp_rf( [src.to_s], dest, options, file: file, line: line )
    }

    public class func cp_rf( list: [String], _ dir: to_s_protocol, _ options: [String]? = nil, file: String = __FILE__, line: Int = __LINE__ ) -> Bool {
        return systemOK( "cp -rf \(expand( list )) \"\(dir.to_s)\"", file: file, line: line )
    }
    
    public class func identical( src: to_s_protocol, _ dest: to_s_protocol, _ options: [String]? = nil, file: String = __FILE__, line: Int = __LINE__ ) -> Bool {
        return compare_file( src, dest, options, file: file, line: line )
    }

    public class func install( src: to_s_protocol, _ dest: to_s_protocol, _ mode: to_s_protocol?, options: [String]? = nil, file: String = __FILE__, line: Int = __LINE__ ) -> Bool {
        let mode = mode != nil ? " -m " + mode!.to_s : ""
        return systemOK( "install\(mode) \"\(src.to_s)\" \"\(dest.to_s)\"", file: file, line: line )
    }

    public class func link( old: to_s_protocol, _ new: to_s_protocol, _ options: [String]? = nil, file: String = __FILE__, line: Int = __LINE__ ) -> Bool {
        return ln( old, new, options, file: file, line: line )
    }

    public class func ln( old: to_s_protocol, _ new: to_s_protocol, _ options: [String]? = nil, file: String = __FILE__, line: Int = __LINE__ ) -> Bool {
        return ln( [old.to_s], new, options, file: file, line: line )
    }

    public class func ln( list: [String], _ destdir: to_s_protocol, _ options: [String]? = nil, file: String = __FILE__, line: Int = __LINE__ ) -> Bool {
        return systemOK( "ln \(expand( list )) \"\(destdir.to_s)\"", file: file, line: line )
    }

    public class func ln_s( old: to_s_protocol, _ new: to_s_protocol, _ options: [String]? = nil, file: String = __FILE__, line: Int = __LINE__ ) -> Bool {
        return ln_s( [old.to_s], new, options, file: file, line: line )
    }

    public class func ln_s( list: [String], _ destdir: to_s_protocol, _ options: [String]? = nil, file: String = __FILE__, line: Int = __LINE__ ) -> Bool {
        return systemOK( "ln -s \(expand( list )) \"\(destdir.to_s)\"", file: file, line: line )
    }

    public class func ln_sf( src: to_s_protocol, _ dest: to_s_protocol, _ options: [String]? = nil, file: String = __FILE__, line: Int = __LINE__ ) -> Bool {
        return systemOK( "ln -sf \"\(src.to_s)\" \"\(dest.to_s)\"", file: file, line: line )
    }

    public class func makedirs( list: [String], _ options: [String]? = nil, file: String = __FILE__, line: Int = __LINE__ ) -> Bool {
        return mkdir_p( list, options, file: file, line: line )
    }
    
    public class func mkdir( dir: to_s_protocol, _ options: [String]? = nil, file: String = __FILE__, line: Int = __LINE__ ) -> Bool {
        return mkdir( [dir.to_s], options, file: file, line: line )
    }

    public class func mkdir( list: [String], _ options: [String]? = nil, file: String = __FILE__, line: Int = __LINE__ ) -> Bool {
        return systemOK( "mkdir \(expand( list ))", file: file, line: line )
    }

    public class func mkdir_p( dir: to_s_protocol, _ options: [String]? = nil, file: String = __FILE__, line: Int = __LINE__ ) -> Bool {
        return mkdir_p( [dir.to_s], options, file: file, line: line )
    }

    public class func mkdir_p( list: [String], _ options: [String]? = nil, file: String = __FILE__, line: Int = __LINE__ ) -> Bool {
            return systemOK( "mkdir -p \(expand( list ))", file: file, line: line )
    }

    public class func mkpath( list: [String], _ options: [String]? = nil, file: String = __FILE__, line: Int = __LINE__ ) -> Bool {
        return mkdir_p( list, options, file: file, line: line )
    }

    public class func mv( src: to_s_protocol, _ dest: to_s_protocol, _ options: [String]? = nil, file: String = __FILE__, line: Int = __LINE__ ) -> Bool {
        return mv( [src.to_s], dest, options, file: file, line: line )
    }

    public class func mv( list: [String], _ dir: to_s_protocol, _ options: [String]? = nil, file: String = __FILE__, line: Int = __LINE__ ) -> Bool {
        return systemOK( "mv \(expand( list )) \"\(dir.to_s)\"", file: file, line: line )
    }
    
    public class func mv_f( src: to_s_protocol, _ dest: to_s_protocol, _ options: [String]? = nil, file: String = __FILE__, line: Int = __LINE__ ) -> Bool {
        return mv_f( [src.to_s], dest, options, file: file, line: line )
    }

    public class func mv_f( list: [String], _ dir: to_s_protocol, _ options: [String]? = nil, file: String = __FILE__, line: Int = __LINE__ ) -> Bool {
        return systemOK( "mv -f \(expand( list )) \"\(dir.to_s)\"", file: file, line: line )
    }
    
    public class func remove_dir( dir: to_s_protocol, _ force: Bool = false, _ options: [String]? = nil, file: String = __FILE__, line: Int = __LINE__ ) -> Bool {
        return force ? rm_rf( dir, options, file: file, line: line ) : rm_r( [dir.to_s], options, file: file, line: line )
    }

    public class func remove_entry( dir: to_s_protocol, _ force: Bool = false, _ options: [String]? = nil, file: String = __FILE__, line: Int = __LINE__ ) -> Bool {
        return force ? rm_rf( dir, options, file: file, line: line ) : rm_r( [dir.to_s], options, file: file, line: line )
    }

    public class func remove_entry_secure( dir: to_s_protocol, _ options: [String]? = nil, file: String = __FILE__, line: Int = __LINE__ ) -> Bool {
        return systemOK( "rm -rfP \"\(dir.to_s)\"", file: file, line: line )
    }

    public class func remove_file( path: to_s_protocol, _ options: [String]? = nil, file: String = __FILE__, line: Int = __LINE__ ) -> Bool {
        return rm( [path.to_s], options, file: file, line: line )
    }

    public class func rm( path: to_s_protocol, _ options: [String]? = nil, file: String = __FILE__, line: Int = __LINE__ ) -> Bool {
        return rm( [path.to_s], options, file: file, line: line )
    }

    public class func rm( list: [String], _ options: [String]? = nil, file: String = __FILE__, line: Int = __LINE__ ) -> Bool {
        return systemOK( "rm \(expand( list ))", file: file, line: line )
    }
    
    public class func rmdir( dir: to_s_protocol, _ options: [String]? = nil, file: String = __FILE__, line: Int = __LINE__ ) -> Bool {
        return rmdir( [dir.to_s], options, file: file, line: line )
    }

    public class func rmdir( list: [String], _ options: [String]? = nil, file: String = __FILE__, line: Int = __LINE__ ) -> Bool {
        return systemOK( "rmdir \(expand( list ))", file: file, line: line )
    }
    
    public class func rm_f( path: to_s_protocol, _ options: [String]? = nil, file: String = __FILE__, line: Int = __LINE__ ) -> Bool {
        return rm_f( [path.to_s], options, file: file, line: line )
    }

    public class func rm_f( list: [String], _ options: [String]? = nil, file: String = __FILE__, line: Int = __LINE__ ) -> Bool {
        return systemOK( "rm -f \(expand( list ))", file: file, line: line )
    }
    
    public class func rm_r( dir: to_s_protocol, _ options: [String]? = nil, file: String = __FILE__, line: Int = __LINE__ ) -> Bool {
        return rm_r( [dir.to_s], options, file: file, line: line )
    }

    public class func rm_r( list: [String], _ options: [String]? = nil, file: String = __FILE__, line: Int = __LINE__ ) -> Bool {
        return systemOK( "rm -r \(expand( list ))", file: file, line: line )
    }

    public class func rm_rf( dir: to_s_protocol, _ options: [String]? = nil, file: String = __FILE__, line: Int = __LINE__ ) -> Bool {
        return rm_rf( [dir.to_s], options, file: file, line: line )
    }

    public class func rm_rf( list: [String], _ options: [String]? = nil, file: String = __FILE__, line: Int = __LINE__ ) -> Bool {
        return systemOK( "rm -rf \(expand( list ))", file: file, line: line )
    }

    public class func rmtree( list: [String], _ options: [String]? = nil, file: String = __FILE__, line: Int = __LINE__ ) -> Bool {
        return rm_rf( list, options, file: file, line: line )
    }

    public class func safe_unlink( list: [String], _ options: [String]? = nil, file: String = __FILE__, line: Int = __LINE__ ) -> Bool {
        return rm_f( list, options, file: file, line: line )
    }

    public class func symlink( src: to_s_protocol, _ dest: to_s_protocol, _ options: [String]? = nil, file: String = __FILE__, line: Int = __LINE__ ) -> Bool {
        return ln_s( src, dest, options, file: file, line: line )
    }

    public class func rsync( src: to_s_protocol, _ dest: to_s_protocol, _ args: to_s_protocol = "-rlp", _ options: [String]? = nil, file: String = __FILE__, line: Int = __LINE__ ) -> Bool {
        return rsync( [src.to_s], dest, file: file, line: line )
    }

    public class func rsync( list: [String], _ dir: to_s_protocol, _ args: to_s_protocol = "-rlp", _ options: [String]? = nil, file: String = __FILE__, line: Int = __LINE__ ) -> Bool {
        return systemOK( "rsync \(args) \(expand( list )) \"\(dir.to_s)\"", file: file, line: line )
    }

    public class func touch( path: to_s_protocol, _ options: [String]? = nil, file: String = __FILE__, line: Int = __LINE__ ) -> Bool {
        return touch( [path.to_s], options, file: file, line: line )
    }

    public class func touch( list: [String], _ options: [String]? = nil, file: String = __FILE__, line: Int = __LINE__ ) -> Bool {
        return systemOK( "touch \(expand( list ))", file: file, line: line )
    }
    
    public class func touch_f( path: to_s_protocol, _ options: [String]? = nil, file: String = __FILE__, line: Int = __LINE__ ) -> Bool {
        return touch_f( [path.to_s], options, file: file, line: line )
    }

    public class func touch_f( list: [String], _ options: [String]? = nil, file: String = __FILE__, line: Int = __LINE__ ) -> Bool {
        return systemOK( "touch -f \(expand( list ))", file: file, line: line )
    }
    
}