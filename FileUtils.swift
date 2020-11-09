//
//  public class func swift
//  SwiftRuby
//
//  Created by John Holdsworth on 30/09/2015.
//  Copyright © 2015 John Holdsworth. All rights reserved.
//
//  $Id: //depot/SwiftRuby/FileUtils.swift#18 $
//
//  Repo: https://github.com/RubyNative/SwiftRuby
//
//  See: http://ruby-doc.org/stdlib-2.2.3/libdoc/fileutils/rdoc/FileUtils.html
//

import Darwin
// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}


public var STATUS = 0

public func systemOK(_ command: string_like, file: StaticString? = #file, line: UInt = #line) -> Bool {
#if os(iOS)
    SRNotImplemented("system() depricated since iOS 8", file: file!, line: line)
#else
    STATUS = Int(_system(command.to_s))
    if STATUS != 0 {
        if file != nil {
            SRLog("system call '\(command.to_s)' failed", file: file!, line: line)
        }
        return false
    }
    STATUS >>= 8
#endif
    return true
}

open class FileUtils {

    open var pwd: String? {
        return Dir.getwd
    }
    
    fileprivate class func expand(_ list: array_like) -> String {
        return list.to_a.map { "\""+$0.replacingOccurrences(of: "\"", with: "\\\"")+"\"" }
            .joined(separator: " ")
    }

    open class func cd(_ dir: string_like, options: [String]?, file: StaticString = #file, line: UInt = #line) -> Bool {
        return Dir.chdir(dir, file: file, line: line)
    }

//    public class func cd(dir: string_like, options: [String]?, file: StaticString = #file, line: UInt = #line) -> Bool { {|dir| .... }

    open class func chmod(_ mode: string_like, _ list: array_like, _ options: [String]? = nil, file: StaticString = #file, line: UInt = #line) -> Bool {
        return systemOK("chmod \(mode.to_s) \(expand(list))", file: file, line: line)
    }

    open class func chmod_R(_ mode: string_like, _ list: array_like, _ options: [String]? = nil, file: StaticString = #file, line: UInt = #line) -> Bool {
        return systemOK("chmod -R \(mode.to_s) \(expand(list))", file: file, line: line)
    }

    open class func chown(_ user: string_like, _ group: string_like?, _ list: array_like, _ options: [String]? = nil, file: StaticString = #file, line: UInt = #line) -> Bool {
        let whoto = user.to_s + (group != nil ? ":"+group!.to_s : "")
        return systemOK("chown \(whoto) \(expand(list))", file: file, line: line)
    }

    open class func chown_R(_ user: string_like, _ group: string_like?, _ list: array_like, _ options: [String]? = nil, file: StaticString = #file, line: UInt = #line) -> Bool {
        let whoto = user.to_s + (group != nil ? ":"+group!.to_s : "")
        return systemOK("chown -R \(whoto) \(expand(list))", file: file, line: line)
    }

    open class func cmp(_ src: string_like, _ dest: string_like, _ options: [String]? = nil, file: StaticString = #file, line: UInt = #line) -> Bool {
        return compare_file(src, dest, options, file: file, line: line)
    }

    open class func compare_file(_ src: string_like, _ dest: string_like, _ options: [String]? = nil, file: StaticString = #file, line: UInt = #line) -> Bool {
        return systemOK("diff -q \"\(src.to_s)\" \"\(dest.to_s)\" >/dev/null", file: file, line: line)
    }

    open class func compare_stream(_ a: IO, _ b: IO, _ options: [String]? = nil, file: StaticString = #file, line: UInt = #line) -> Bool {
        if let a = a.read(), let b = b.read() {
            return a.length == b.length && memcmp(a.bytes, b.bytes, a.length) == 0
        }
        return false
    }

    open class func copy(_ src: string_like, _ dest: string_like, _ options: [String]? = nil, file: StaticString = #file, line: UInt = #line) -> Bool {
        return cp(src, dest, options, file: file, line: line)
    }

    open class func copy_entry(_ src: string_like, _ dest: string_like, _ preserve: Bool = false, _ options: [String]? = nil, file: StaticString = #file, line: UInt = #line) -> Bool {
        return rsync([src.to_s], dest, preserve ? "-rlpogt" : "-rlp", options, file: file, line: line)
    }

    open class func copy_file(_ src: string_like, _ dest: string_like, _ options: [String]? = nil, file: StaticString = #file, line: UInt = #line) -> Bool {
        return cp(src, dest, options, file: file, line: line)
    }

    open class func copy_stream(_ src: IO, _ dest: IO, _ options: [String]? = nil, file: StaticString = #file, line: UInt = #line) -> Bool {
        if let data = src.read() {
            dest.write(data)
            return true
        }
        return false
    }

    open class func cat(_ list: array_like, _ dir: string_like, _ options: [String]? = nil, file: StaticString = #file, line: UInt = #line) -> Bool {
        return systemOK("cat \(expand(list)) >\"\(dir.to_s)\"", file: file, line: line)
    }

    open class func cp(_ list: array_like, _ dir: string_like, _ options: [String]? = nil, file: StaticString = #file, line: UInt = #line) -> Bool {
        return systemOK("cp \(expand(list)) \"\(dir.to_s)\"", file: file, line: line)
    }

    open class func cp_r(_ list: array_like, _ dir: string_like, _ options: [String]? = nil, file: StaticString = #file, line: UInt = #line) -> Bool {
        return systemOK("cp -r \(expand(list)) \"\(dir.to_s)\"", file: file, line: line)
    }
    
    open class func cp_rf(_ list: array_like, _ dir: string_like, _ options: [String]? = nil, file: StaticString = #file, line: UInt = #line) -> Bool {
        return systemOK("cp -rf \(expand(list)) \"\(dir.to_s)\"", file: file, line: line)
    }
    
    open class func identical(_ src: string_like, _ dest: string_like, _ options: [String]? = nil, file: StaticString = #file, line: UInt = #line) -> Bool {
        return compare_file(src, dest, options, file: file, line: line)
    }

    open class func install(_ src: string_like, _ dest: string_like, _ mode: string_like?, options: [String]? = nil, file: StaticString = #file, line: UInt = #line) -> Bool {
        let mode = mode != nil ? " -m " + mode!.to_s : ""
        return systemOK("install\(mode) \"\(src.to_s)\" \"\(dest.to_s)\"", file: file, line: line)
    }

    open class func link(_ old: string_like, _ new: string_like, _ options: [String]? = nil, file: StaticString = #file, line: UInt = #line) -> Bool {
        return ln(old, new, options, file: file, line: line)
    }

    open class func ln(_ list: array_like, _ destdir: string_like, _ options: [String]? = nil, file: StaticString = #file, line: UInt = #line) -> Bool {
        return systemOK("ln \(expand(list)) \"\(destdir.to_s)\"", file: file, line: line)
    }

    open class func ln_s(_ list: array_like, _ destdir: string_like, _ options: [String]? = nil, file: StaticString = #file, line: UInt = #line) -> Bool {
        return systemOK("ln -s \(expand(list)) \"\(destdir.to_s)\"", file: file, line: line)
    }

    open class func ln_sf(_ src: string_like, _ dest: string_like, _ options: [String]? = nil, file: StaticString = #file, line: UInt = #line) -> Bool {
        return systemOK("ln -sf \"\(src.to_s)\" \"\(dest.to_s)\"", file: file, line: line)
    }

    open class func makedirs(_ list: array_like, _ options: [String]? = nil, file: StaticString = #file, line: UInt = #line) -> Bool {
        return mkdir_p(list, options, file: file, line: line)
    }
    
    open class func mkdir(_ list: array_like, _ options: [String]? = nil, file: StaticString = #file, line: UInt = #line) -> Bool {
        return systemOK("mkdir \(expand(list))", file: file, line: line)
    }

    open class func mkdir_p(_ list: array_like, _ options: [String]? = nil, file: StaticString = #file, line: UInt = #line) -> Bool {
            return systemOK("mkdir -p \(expand(list))", file: file, line: line)
    }

    open class func mkpath(_ list: array_like, _ options: [String]? = nil, file: StaticString = #file, line: UInt = #line) -> Bool {
        return mkdir_p(list, options, file: file, line: line)
    }

    open class func mv(_ list: array_like, _ dir: string_like, _ options: [String]? = nil, file: StaticString = #file, line: UInt = #line) -> Bool {
        return systemOK("mv \(expand(list)) \"\(dir.to_s)\"", file: file, line: line)
    }
    
    open class func mv_f(_ list: array_like, _ dir: string_like, _ options: [String]? = nil, file: StaticString = #file, line: UInt = #line) -> Bool {
        return systemOK("mv -f \(expand(list)) \"\(dir.to_s)\"", file: file, line: line)
    }
    
    open class func remove_dir(_ dir: string_like, _ force: Bool = false, _ options: [String]? = nil, file: StaticString = #file, line: UInt = #line) -> Bool {
        return force ? rm_rf(dir, options, file: file, line: line) : rm_r([dir.to_s], options, file: file, line: line)
    }

    open class func remove_entry(_ dir: string_like, _ force: Bool = false, _ options: [String]? = nil, file: StaticString = #file, line: UInt = #line) -> Bool {
        return force ? rm_rf(dir, options, file: file, line: line) : rm_r([dir.to_s], options, file: file, line: line)
    }

    open class func remove_entry_secure(_ dir: string_like, _ options: [String]? = nil, file: StaticString = #file, line: UInt = #line) -> Bool {
        return systemOK("rm -rfP \"\(dir.to_s)\"", file: file, line: line)
    }

    open class func remove_file(_ path: string_like, _ options: [String]? = nil, file: StaticString = #file, line: UInt = #line) -> Bool {
        return rm([path.to_s], options, file: file, line: line)
    }

    open class func rm(_ list: array_like, _ options: [String]? = nil, file: StaticString = #file, line: UInt = #line) -> Bool {
        return systemOK("rm \(expand(list))", file: file, line: line)
    }
    
    open class func rm_f(_ list: array_like, _ options: [String]? = nil, file: StaticString = #file, line: UInt = #line) -> Bool {
        return systemOK("rm -f \(expand(list))", file: file, line: line)
    }
    
    open class func rm_r(_ list: array_like, _ options: [String]? = nil, file: StaticString = #file, line: UInt = #line) -> Bool {
        return systemOK("rm -r \(expand(list))", file: file, line: line)
    }

    open class func rm_rf(_ list: array_like, _ options: [String]? = nil, file: StaticString = #file, line: UInt = #line) -> Bool {
        return systemOK("rm -rf \(expand(list.to_a))", file: file, line: line)
    }

    open class func rmdir(_ list: array_like, _ options: [String]? = nil, file: StaticString = #file, line: UInt = #line) -> Bool {
        return systemOK("rmdir \(expand(list))", file: file, line: line)
    }

    open class func rmtree(_ list: array_like, _ options: [String]? = nil, file: StaticString = #file, line: UInt = #line) -> Bool {
        return rm_rf(list, options, file: file, line: line)
    }

    open class func safe_unlink(_ list: array_like, _ options: [String]? = nil, file: StaticString = #file, line: UInt = #line) -> Bool {
        return rm_f(list, options, file: file, line: line)
    }

    open class func symlink(_ src: string_like, _ dest: string_like, _ options: [String]? = nil, file: StaticString = #file, line: UInt = #line) -> Bool {
        return ln_s(src, dest, options, file: file, line: line)
    }

    open class func rsync(_ list: array_like, _ dest: string_like, _ args: string_like = "-a", _ options: [String]? = nil, file: StaticString = #file, line: UInt = #line) -> Bool {
        return systemOK("rsync \(args) \(expand(list)) \"\(dest.to_s)\"", file: file, line: line)
    }

    open class func touch(_ list: array_like, _ options: [String]? = nil, file: StaticString = #file, line: UInt = #line) -> Bool {
        return systemOK("touch \(expand(list))", file: file, line: line)
    }
    
    open class func touch_f(_ list: array_like, _ options: [String]? = nil, file: StaticString = #file, line: UInt = #line) -> Bool {
        return systemOK("touch -f \(expand(list))", file: file, line: line)
    }

    open class func uptodate(_ new: string_like, old_list: array_like, file: StaticString = #file, line: UInt = #line) -> Bool {
        let new_time = Stat(new, file: nil)?.mtime.to_f ?? 0
        for old in old_list.to_a {
            if Stat(old, file: file, line: line)?.mtime.to_f > new_time {
                return false
            }
        }
        return true
    }

}
