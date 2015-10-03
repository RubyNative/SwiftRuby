//
//  Stat.swift
//  RubyNative
//
//  Created by John Holdsworth on 26/09/2015.
//  Copyright © 2015 John Holdsworth. All rights reserved.
//
//  $Id: //depot/RubyKit/Stat.swift#2 $
//
//  Repo: https://github.com/RubyNative/RubyKit
//
//  See: http://ruby-doc.org/core-2.2.3/File/Stat.html
//

import Foundation

// from <sys/stat.h> (not in Foundation)

/* File mode */
/* Read, write, execute/search by owner */
public let S_IRWXU: Int = 0o000700		/* [XSI] RWX mask for owner */
public let S_IRUSR: Int = 0o000400		/* [XSI] R for owner */
public let S_IWUSR: Int = 0o000200		/* [XSI] W for owner */
public let S_IXUSR: Int = 0o000100		/* [XSI] X for owner */
/* Read, write, execute/search by group */
public let S_IRWXG: Int = 0o000070		/* [XSI] RWX mask for group */
public let S_IRGRP: Int = 0o000040		/* [XSI] R for group */
public let S_IWGRP: Int = 0o000020		/* [XSI] W for group */
public let S_IXGRP: Int = 0o000010		/* [XSI] X for group */
/* Read, write, execute/search by others */
public let S_IRWXO: Int = 0o000007		/* [XSI] RWX mask for other */
public let S_IROTH: Int = 0o000004		/* [XSI] R for other */
public let S_IWOTH: Int = 0o000002		/* [XSI] W for other */
public let S_IXOTH: Int = 0o000001		/* [XSI] X for other */

public let S_ISUID: Int = 0o004000		/* [XSI] set user id on execution */
public let S_ISGID: Int = 0o002000		/* [XSI] set group id on execution */
public let S_ISVTX: Int = 0o001000		/* [XSI] directory restrcted delete */

public let S_IFMT : Int = 0o170000		/* [XSI] type of file mask */
public let S_IFIFO: Int = 0o010000		/* [XSI] named pipe (fifo) */
public let S_IFCHR: Int = 0o020000		/* [XSI] character special */
public let S_IFDIR: Int = 0o040000		/* [XSI] directory */
public let S_IFBLK: Int = 0o060000		/* [XSI] block special */
public let S_IFREG: Int = 0o100000		/* [XSI] regular */
public let S_IFLNK: Int = 0o120000		/* [XSI] symbolic link */
public let S_IFSOCK:Int = 0o140000		/* [XSI] socket */

/* Linux only? */
public let S_IRUGO = (S_IRUSR|S_IRGRP|S_IROTH)
public let S_IWUGO = (S_IWUSR|S_IWGRP|S_IWOTH)
public let S_IXUGO = (S_IXUSR|S_IXGRP|S_IXOTH)

public func S_ISBLK(m: Int) -> Bool {
    return (((m) & S_IFMT) == S_IFBLK)	/* block special */
}

public func S_ISCHR(m: Int) -> Bool {
    return (((m) & S_IFMT) == S_IFCHR)	/* char special */
}

public func S_ISDIR(m: Int) -> Bool {
    return (((m) & S_IFMT) == S_IFDIR)	/* directory */
}

public func S_ISFIFO(m: Int) -> Bool {
    return (((m) & S_IFMT) == S_IFIFO)	/* fifo or socket */
}

public func S_ISREG(m: Int) -> Bool {
    return (((m) & S_IFMT) == S_IFREG)	/* regular file */
}

public func S_ISLNK(m: Int) -> Bool {
    return (((m) & S_IFMT) == S_IFLNK)	/* symbolic link */
}

public func S_ISSOCK(m: Int) -> Bool {
    return (((m) & S_IFMT) == S_IFSOCK)	/* socket */
}

public class Stat : Object {

    public var info = stat()

    public class func new( filename: to_s_protocol, statLink: Bool = false, file: String, line: Int ) -> Stat? {
        return Stat( filename, statLink: statLink, file: file, line: line )
    }

    public convenience init?( fd: Int, file: String, line: Int ) {
        self.init()
        if !unixOK( "fstat \(fd)", fstat( Int32(fd), &info ), file: file, line: line ) {
            return nil
        }
    }

    public convenience init?( _ filepath: to_s_protocol, statLink: Bool = false, file: String?, line: Int = 0 ) {
        self.init()
        if statLink {
            if !unixOK( "lstat \(filepath.to_s)", lstat( filepath.to_s, &info ), file: file, line: line ) {
                return nil
            }
        }
        else {
            if !unixOK( "stat \(filepath.to_s)", stat( filepath.to_s, &info ), file: file, line: line ) {
                return nil
            }
        }
    }

    // MARK: Instance methods

    public var atime: Time {
        return Time(spec: info.st_atimespec)
    }

    public var birthtime: Time {
        return Time(spec: info.st_ctimespec)
    }

    public var blksize: Int {
        return Int(info.st_blksize)
    }

    public var blockdev: Bool {
        return S_ISBLK(mode)
    }

    public var blocks: Int {
        return Int(info.st_blocks)
    }

    public var chardev: Bool {
        return S_ISCHR(mode)
    }

    public var ctime: Time {
        return Time(spec: info.st_ctimespec)
    }

    public var dev: Int {
        return Int(info.st_dev)
    }

    public var directory: Bool {
        return S_ISDIR(mode)
    }

    public var executable: Bool {
        if geteuid() == 0 {
            return true
        }
        if owned {
            return mode & S_IXUSR != 0
        }
        if grpowned {
            return mode & S_IXGRP != 0
        }
        if mode & S_IXOTH == 0 {
            return false
        }
        return true
    }

    public var executable_real: Bool {
        if getuid() == 0 {
            return true
        }
        if rowned {
            return mode & S_IXUSR != 0
        }
        if rgrpowned {
            return mode & S_IXGRP != 0
        }
        if mode & S_IXOTH == 0 {
            return false
        }
        return true
    }

    public var file: Bool {
        return S_ISREG(mode)
    }

    public var ftype: String {
        return
            S_ISREG(mode) ? "file" :
            S_ISDIR(mode) ? "directory" :
            S_ISCHR(mode) ? "characterSpecial" :
            S_ISBLK(mode) ? "blockSpecial" :
            S_ISFIFO(mode) ? "fifo" :
            S_ISLNK(mode) ? "link" :
            S_ISSOCK(mode) ? "socket" :
            "unknown"
    }

    public var gid: Int {
        return Int(info.st_gid)
    }

    public var grpowned: Bool {
        let egid = gid_t(getegid())
        var groups = [gid_t](count: 1000, repeatedValue: 0)
        let gcount = getgroups( Int32(groups.count), &groups )

        for g in 0..<Int(gcount) {
            if groups[g] == egid {
                return true
            }
        }

        return false
    }

    public var ino: Int {
        return Int(info.st_ino)
    }

    public var mode: Int {
        return Int(info.st_mode)
    }

    public var mtime: Time {
        return Time(spec: info.st_mtimespec)
    }

    public var nlink: Int {
        return Int(info.st_nlink)
    }

    public var owned: Bool {
        return geteuid() == info.st_uid
    }

    public var pipe: Bool {
        return S_ISFIFO(mode)
    }

    public var rdev: Int {
        return Int(info.st_rdev)
    }

    public var rdev_major: Int? {
        return nil
    }

    public var rdev_minor: Int? {
        return nil
    }

    public var readable: Bool {
        if geteuid() == 0 {
            return true
        }
        if owned {
            return mode & S_IRUSR != 0
        }
        if grpowned {
            return mode & S_IRGRP != 0
        }
        if mode & S_IROTH == 0 {
            return false
        }
        return true
    }

    public var readable_real: Bool {
        if getuid() == 0 {
            return true
        }
        if rowned {
            return mode & S_IRUSR != 0
        }
        if rgrpowned {
            return mode & S_IRGRP != 0
        }
        if mode & S_IROTH == 0 {
            return false
        }
        return true
    }

    public var rowned: Bool {
        return getuid() == info.st_uid
    }

    public var rgrpowned: Bool {
        let egid = gid_t(getgid())
        var groups = [gid_t](count: 1000, repeatedValue: 0)
        let gcount = getgroups( Int32(groups.count), &groups )

        for g in 0..<Int(gcount) {
            if groups[g] == egid {
                return true
            }
        }

        return false
    }
    
    public var setgid: Bool {
        return (mode & S_ISGID) != 0
    }

    public var setuid: Bool {
        return (mode & S_ISUID) != 0
    }

    public var size: Int {
        return Int(info.st_size)
    }

    public var socket: Bool {
        return S_ISSOCK(mode)
    }

    public var sticky: Bool {
        return mode & S_ISVTX != 0
    }

    public var symlink: Bool {
        return S_ISLNK(mode)
    }

    public var uid: Int {
        return Int(info.st_uid)
    }

    public var world_readable: Bool {
        return mode & S_IROTH != 0
    }

    public var world_writable: Bool {
        return mode & S_IWOTH != 0
    }

    public var writable: Bool {
        if geteuid() == 0 {
            return true
        }
        if owned {
            return mode & S_IWUSR != 0
        }
        if grpowned {
            return mode & S_IWGRP != 0
        }
        if mode & S_IWOTH == 0 {
            return false
        }
        return true
    }

    public var writable_real: Bool {
        if getuid() == 0 {
            return true
        }
        if rowned {
            return mode & S_IWUSR != 0
        }
        if rgrpowned {
            return mode & S_IWGRP != 0
        }
        if mode & S_IWOTH == 0 {
            return false
        }
        return true
    }

    public var zero: Bool {
        return info.st_size == 0
    }

}