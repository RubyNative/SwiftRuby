//
//  IO.swift
//  RubyNative
//
//  Created by John Holdsworth on 26/09/2015.
//  Copyright © 2015 John Holdsworth. All rights reserved.
//
//  $Id: //depot/RubyNative/IO.swift#17 $
//
//  Repo: https://github.com/RubyNative/RubyNative
//
//  See: http://ruby-doc.org/core-2.2.3/IO.html
//

import Foundation

public let EWOULDBLOCKWaitReadable = EWOULDBLOCK
public let EWOULDBLOCKWaitWritable = EWOULDBLOCK
public let dollarSlash = "\n"

@asmname("fcntl")
func _fcntl( filedesc: Int32, _ command: Int32, _ arg: Int32 ) -> Int32

public class IO: Object {

    var filePointer = UnsafeMutablePointer<FILE>()
    var autoclose = true
    let binmode = true
    var lineno = 0

    var sync = true {
        didSet {
            flush()
            setvbuf( filePointer, nil, sync ? _IONBF : _IOFBF, 0 )
        }
    }

    var nonblock = false {
        didSet {
            var flags = fcntl( Int(F_GETFL), 0 )
            if nonblock {
                flags |= Int(O_NONBLOCK)
            }
            else {
                flags &= ~Int(O_NONBLOCK)
            }
            fcntl( Int(F_SETFL), flags )
        }
    }

    var close_on_exec = false {
        didSet {
            if close_on_exec {
                fcntl( Int(F_SETFD), Int(FD_CLOEXEC) )
            }
        }
    }

    public init?( what: String, filePointer: UnsafeMutablePointer<FILE>, file: String = __FILE__, line: Int = __LINE__ ) {
        super.init()
        if filePointer == nil {
            if warningDisposition != .Ignore {
                STDERR.print( "RubyNative: \(what) failed: \(String( UTF8String: strerror( errno ) )!) at \(file)#\(line)" )
            }
            if warningDisposition == .Fatal {
                fatalError()
            }
            return nil
        }
        self.filePointer = filePointer
    }

    // MARK: Class methods

    public class func binread( name: to_s_protocol, _ length: Int? = nil, _ offset: Int? = nil ) -> Data? {
        return self.read( name, length, offset )
    }

    public class func binwrite( name: to_s_protocol, _ string: to_d_protocol, _ offset: Int? = nil ) -> fixnum? {
        return self.write( name, string, offset )
    }

    public class func copy_stream( src: IO, _ dst: IO, _ copy_length: Int? = nil, _ src_offset: Int? = nil ) -> Int {
        if src_offset != nil {
            src.seek( src_offset!, Int(SEEK_SET) )
        }
        var copied = 0
        let data = Data( capacity: 1024*1024 )
        while let data = src.read( data.capacity, data ) {
            copied += data.length
            dst.write( data )
            data.length = 0
        }
        return copied
    }

    public class func for_fd( fd: Int, _ mode: to_s_protocol, opt: Array<String>? = nil, file: String = __FILE__, line: Int = __LINE__ ) -> IO? {
        return IO( what: "fdopen \(fd)", filePointer: fdopen( Int32(fd), mode.to_s ), file: file, line: line )
    }

    public class func foreach( name: to_s_protocol, _ sep: to_s_protocol = dollarSlash,
                                _ limit: Int? = nil, _ block: (line: String) -> () ) {
        if let ioFile = File.open( name, "r" ) {
            ioFile.each_line( sep, limit, block )
        }
    }

    public class func foreach( name: to_s_protocol, _ limit: Int? = nil, _ block: (line: String) -> () ) {
        foreach( name, dollarSlash, limit, block )
    }

    public class func new( fd: Int, _ mode: to_s_protocol = "r", file: String = __FILE__, line: Int = __LINE__ ) -> IO? {
        return for_fd( fd, mode, file: file, line: line )
    }

    public class func open( fd: Int, _ mode: to_s_protocol = "r", file: String = __FILE__, line: Int = __LINE__ ) -> IO? {
        return for_fd( fd, mode, file: file, line: line )
    }

    public class func pipe( file: String = __FILE__, line: Int = __LINE__ ) -> (reader: IO?, writer: IO?) {
        var fds = [Int32](count: 0, repeatedValue: 0)
        Darwin.pipe( &fds )
        return (IO.new( Int(fds[0]), "r", file: file, line: line ), IO.new( Int(fds[1]), "w", file: file, line: line ))
    }

    public class func popen( command: to_s_protocol, _ mode: to_s_protocol = "r", file: String = __FILE__, line: Int = __LINE__ ) -> IO? {
        return IO( what: "IO.popen '\(command)'", filePointer: Darwin.popen( command.to_s, mode.to_s ), file: file, line: line )
    }

    public class func read( name: to_s_protocol, _ length: Int? = nil, _ offset: Int? = nil, file: String = __FILE__, line: Int = __LINE__ ) -> Data? {
        if let ioFile = File.open( name, "r" ) {
            if offset != nil {
                ioFile.seek( offset!, Int(SEEK_SET), file: file, line: line )
            }
            return ioFile.read( length )
        }
        return nil
    }

    public class func readlines( name: to_s_protocol, _ sep: to_s_protocol = dollarSlash, _ limit: Int? = nil, file: String = __FILE__, line: Int = __LINE__ ) -> [String]? {
        if let ioFile = File.open( name, "r", file: file, line: line ) {
            var out = [String]()
            ioFile.each_line( sep, limit, {
                (line) in
                out.append( line )
            } )
            return out
        }
        return nil
    }

    public class func readlines( name: to_s_protocol, _ limit: Int? = nil, file: String = __FILE__, line: Int = __LINE__ ) -> [String]? {
        return readlines( name, dollarSlash, limit, file: file, line: line )
    }

    public class func select( read_array: [IO], _ write_array: [IO]? = nil, _ error_array: [IO]? = nil, timeout: Int? = nil ) {
        /// later, much later...
        notImplemented( "IO.select" )
    }

    public class func sysopen( path: to_s_protocol, _ mode: Int = Int(O_RDONLY), _ perm: Int = 0o644 ) -> fixnum {
        return Int(Darwin.open( path.to_s, CInt(mode), mode_t(perm) ))
    }


    public class func write( name: to_s_protocol, _ string: to_d_protocol, _ offset: Int? = 0, _ open_args: String? = nil, file: String = __FILE__, line: Int = __LINE__ ) -> fixnum? {
        if let ioFile = File.open( name, open_args ?? "w", file: file, line: line ) {
            if offset != nil {
                ioFile.seek( offset!, Int(SEEK_SET), file: file, line: line )
            }
            return ioFile.write( string )
        }
        return nil
    }

    // MARK: Instance methods

    public func advise( advice: Int, _ offset: Int = 0, _ len: Int = 0 ) {
        notImplemented( "IO.advise" )
    }

    public func bytes( block: (CChar) -> () ) -> IO {
        return each_byte( block )
    }

    public func chars( block: (CChar16) -> () ) -> IO {
        return each_char( block )
    }

    public func close( file: String = __FILE__, line: Int = __LINE__ ) {
        if filePointer != nil {
            pclose( filePointer ) == 0 ||
            unixOK( "IO.fclose \(filePointer)", fclose( filePointer ), file: file, line: line )
            filePointer = nil
        }
    }

    public func close_read() {
        notImplemented( "IO.close_read" )
    }

    public func close_write() {
        notImplemented( "IO.close_write" )
    }

    public var closed: Bool {
        return filePointer == nil
    }

    public func each_byte( block: (CChar) -> () ) -> IO {
        while true {
            let byte = CChar(fgetc( filePointer ))
            if feof( filePointer ) != 0 {
                break
            }
            block( byte )
        }
        return self
    }

    public func each_char( block: (CChar16) -> () ) -> IO {
        if let string = read()?.to_s {
            for ch in string.utf16 {
                block( ch )
            }
        }
        return self
    }

    public func each( limit: Int? = nil, _ block: (line: String) -> () ) -> IO {
        return each_line( dollarSlash, limit, block )
    }

    public func each( sep: to_s_protocol = dollarSlash, _ limit: Int? = nil, _ block: (line: String) -> () ) -> IO {
        return each_line( sep, limit, block )
    }

//    public func each_line( limit: Int? = nil, _ block: (line: String) -> () ) -> IO {
//        return each_line( dollarSlash, limit, block )
//    }
//
    public func each_line( sep: to_s_protocol = dollarSlash, _ limit: Int? = nil, _ block: (line: String) -> () ) -> IO {
        var count = 0
        while let line = readline( sep ) {
            block( line: line )
            if limit != nil && ++count >= limit! {
                break
            }
        }
        return self
    }

    public var eof: Bool {
        return feof( filePointer ) != 0
    }

    public func fcntl( arg: Int, _ arg2: Int = 0 ) -> Int {
        return Int(_fcntl( Int32(fileno), Int32(arg), Int32(arg2) ))
    }

    public func fdatasync() {
        notImplemented( "IO.fdatasync" )
    }

    public var fileno: Int {
        return Int(Darwin.fileno( filePointer ))
    }

    public func flush( file: String = __FILE__, line: Int = __LINE__ ) -> Bool {
        return unixOK( "IO.fflush", fflush( filePointer ), file: file, line: line )
    }

    public func fsync( file: String = __FILE__, line: Int = __LINE__ ) -> Bool {
        return flush() && unixOK( "IO.fsync", Darwin.fsync( Int32(fileno) ), file: file, line: line )
    }

    public var getbyte: fixnum? {
        let byte = CChar(fgetc( filePointer ))
        if feof( filePointer ) != 0 {
            return nil
        }
        return Int(byte)
    }

    public var getc: String? {
        let byte = CChar(fgetc( filePointer ))
        if feof( filePointer ) != 0 {
            return nil
        }
        return String(byte)
    }

    func gets( sep: to_s_protocol = dollarSlash ) -> String? {
        let data = Data( capacity: 1_000_000 ) // TODO: should loop
        if fgets( data.bytes, Int32(data.capacity), filePointer ) == nil {
            return nil
        }
        lineno++
        data.length = Int(strlen( data.bytes ))
        data.bytes[data.length-1] = 0 ////
        return data.to_s
    }

    public var inspect: String {
        return self.to_s
    }

    public var internal_encoding: Int {
        return Int(NSUTF8StringEncoding)
    }

    public func ioctl( integer_cmd: Int, arg: Int ) -> Int {
        notImplemented( "IO.ioctl" )
        return 1
    }

    public var isatty: Bool {
        return Darwin.isatty( Int32(fileno) ) != 0
    }

    public func lines( block: (line: String) -> () ) -> IO {
        return each_line( dollarSlash, nil, block )
    }

    public var pid: Int {
        /// no possible without re-implementing popen()
        notImplemented( "IO.pid" )
        return -1
    }

    public var pos: Int {
        return Int(ftell( filePointer ))
    }

    public func print( string: to_s_protocol ) -> Int {
        return Int(fputs( string.to_s, filePointer ))
    }

    public func print( strings: [String] ) {
        for string in strings {
            print( string )
        }
    }

    func printf( string: to_s_protocol ) {
        print( string )
    }

    func putc( obj: Int ) -> Int {
        return Int(fputc( Int32(obj), filePointer ))
    }

    public func puts( string: to_s_protocol ) -> Int {
        return print( string )
    }

    public func puts( strings: [String] ) {
        return print( strings )
    }
    
    public func read( length: Int? = nil, _ outbuf: Data? = nil ) -> Data? {
        let data = outbuf ?? Data( capacity: length ?? stat?.size ?? 1_000_000 )
        data.length = fread( data.bytes, 1, data.capacity, filePointer )
        return data.length != 0 ? data : nil
    }

    public func read_nonblock( length: Int? = nil, _ outbuf: Data? = nil ) -> Data? {
        nonblock = true
        return read( length, outbuf )
    }

    public var readbyte: fixnum? {
        return getbyte
    }

    public var readchar: String? {
        return getc
    }

    public func readline( sep: to_s_protocol = dollarSlash ) -> String? {
        return gets( sep )
    }

    public func readlines( /*sep: to_s_protocol = dollarSlash, _*/ limit: Int? = nil ) -> [String] {
        var out = [String]()
        each_line( dollarSlash, limit, {
            (line) in
            out.append( line )
        } )
        return out
    }

//    public func readlines( limit: Int? = nil ) -> [String] {
//        return readlines( dollarSlash, limit )
//    }

    public func readpartial( maxlen: Int, _ outbuf: Data? = nil ) -> Data? {
        notImplemented( "IO.readpartial" )
        return nil
    }

    public func reopen( other_IO: IO ) -> IO {
        self.filePointer = other_IO.filePointer ////
        return self
    }

    public func reopen( path: to_s_protocol, _ mode_str: to_s_protocol = "r", file: String = __FILE__, line: Int = __LINE__ ) -> IO? {
        return unixOK( "IO.reopen \(path.to_s)", freopen( path.to_s, mode_str.to_s, self.filePointer ) == nil ? 1 : 0,
                        file: file, line: line ) ? self : nil
    }

    public func rewind( file: String = __FILE__, line: Int = __LINE__ ) -> IO {
        Darwin.rewind( filePointer )
        return self
    }

    public func seek( amount: Int, _ whence: Int = Int(SEEK_SET), file: String = __FILE__, line: Int = __LINE__ ) -> Bool {
        return unixOK( "IO.seek", fseek( filePointer, amount, Int32(whence) ), file: file, line: line )
    }

    public func set_encoding( ext_enc: Int ) -> IO? {
        notImplemented( "IO.set_encoding" )
        return nil
    }

    public var stat: Stat? {
        return Stat( fd: fileno, file: __FILE__, line: __LINE__ )
    }

    public func sysread( maxlen: Int? = nil, _ outbuf: Data? = nil ) -> Data? {
        let data = outbuf ?? Data( capacity: maxlen ?? stat?.size ?? 1_000_000 )
        data.length = Darwin.read( Int32(fileno), data.bytes, data.capacity )
        return data.length > 0 ? data : nil
    }

    public func sysseek( offset: Int, _ whence: Int = Int(SEEK_SET) ) -> Int {
        return Int(lseek( Int32(fileno), off_t(offset), Int32(whence) ))
    }

    public func syswrite( string: to_d_protocol ) -> Int {
        return Int(Darwin.write( Int32(fileno), string.to_d.bytes, string.to_d.length ))
    }

    public var tell: Int {
        return pos
    }

    public var to_i: Int {
        return fileno
    }

    public var to_s: String {
        return "\(self)"
    }

    public var tty: Bool {
        return isatty
    }

    public func ungetbyte( string: to_s_protocol ) {
        ungetc( Int32(Array(arrayLiteral: string.to_s)[0])!, filePointer ) ////
    }

    public func ungetbyte( byte: Int ) {
        ungetc( Int32(byte), filePointer )
    }

    public func write( string: to_d_protocol ) -> fixnum {
        return fwrite( string.to_d.bytes, 1, string.to_d.length, filePointer );
    }

    public func write_nonblock( string: to_d_protocol, options: Array<String>? = nil ) -> Int {
        nonblock = true
        return write( string )
    }

    deinit {
        if autoclose {
            close()
        }
    }

}
