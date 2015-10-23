//
//  IO.swift
//  SwiftRuby
//
//  Created by John Holdsworth on 26/09/2015.
//  Copyright © 2015 John Holdsworth. All rights reserved.
//
//  $Id: //depot/SwiftRuby/IO.swift#8 $
//
//  Repo: https://github.com/RubyNative/SwiftRuby
//
//  See: http://ruby-doc.org/core-2.2.3/IO.html
//

import Darwin

@asmname("fcntl")
func _fcntl( filedesc: Int32, _ command: Int32, _ arg: Int32 ) -> Int32

public let EWOULDBLOCKWaitReadable = EWOULDBLOCK
public let EWOULDBLOCKWaitWritable = EWOULDBLOCK

private let selectBitsPerFlag: Int32 = 32
private let selectShift = 5
private let selectBitMask = (1<<selectShift)-1

public func FD_ZERO( flags: UnsafeMutablePointer<Int32> ) {
    memset( flags, 0, sizeof(fd_set) )
}

public func FD_CLR( fd: Int, _ flags: UnsafeMutablePointer<Int32> ) {
    let set = flags + Int( fd>>selectShift )
    set.memory &= ~Int32(1<<(fd&selectBitMask))
}

public func FD_SET( fd: Int, _ flags: UnsafeMutablePointer<Int32> ) {
    let set = flags + Int( fd>>selectShift )
    set.memory |= Int32(1<<(fd&selectBitMask))
}

public func FD_ISSET( fd: Int, _ flags: UnsafeMutablePointer<Int32> ) -> Bool {
    let set = flags + Int( fd>>selectShift )
    return (set.memory & Int32(1<<(fd&selectBitMask))) != 0
}

public func ==(lhs: IO, rhs: IO) -> Bool {
    if let lhData = lhs.read(), rhData = rhs.read() {
        return lhData == rhData
    }
    return false
}

public class IO: RubyObject, string_like, data_like {

    private var _unixFILE = UnsafeMutablePointer<FILE>()
    public var unixFILE: UnsafeMutablePointer<FILE> {
        get {
            if _unixFILE == nil {
                SRLog( "Get of nil IO.unixFILE" )
            }
            return _unixFILE
        }
    }

    public var autoclose = true
    public let binmode = true
    public var lineno = 0

    public var sync = true {
        didSet {
            flush()
            setvbuf( unixFILE, nil, sync ? _IONBF : _IOFBF, 0 )
        }
    }

    public var nonblock = false {
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

    public var close_on_exec = false {
        didSet {
            if close_on_exec {
                fcntl( Int(F_SETFD), Int(FD_CLOEXEC) )
            }
        }
    }

    public var pos: Int {
        get {
            return Int(ftell( unixFILE ))
        }
        set {
            seek( newValue )
        }
    }

    public init( what: String?, unixFILE: UnsafeMutablePointer<FILE>, file: StaticString = __FILE__, line: UInt = __LINE__ ) {
        super.init()
        if unixFILE == nil && what != nil {
            SRError( "\(what!) failed", file: file, line: line )
        }
        self._unixFILE = unixFILE
    }

    public func ifValid() -> IO? {
        return _unixFILE != nil ? self : nil
    }

    // MARK: Class methods

    public class func binread( name: string_like, _ length: Int? = nil, _ offset: Int? = nil ) -> Data? {
        return self.read( name, length, offset )
    }

    public class func binwrite( name: string_like, _ string: data_like, _ offset: Int? = nil ) -> fixnum? {
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

    public class func for_fd( fd: Int, _ mode: string_like, opt: Array<String>? = nil, file: StaticString = __FILE__, line: UInt = __LINE__ ) -> IO? {
        return IO( what: "fdopen \(fd)", unixFILE: fdopen( Int32(fd), mode.to_s ), file: file, line: line ).ifValid()
    }

    public class func foreach( name: string_like, _ sep: string_like = LINE_SEPARATOR,
                                _ limit: Int? = nil, _ block: (line: String) -> () ) {
        if let ioFile = File.open( name, "r" ) {
            ioFile.each_line( sep, limit, block )
        }
    }

    public class func foreach( name: string_like, _ limit: Int? = nil, _ block: (line: String) -> () ) {
        foreach( name, LINE_SEPARATOR, limit, block )
    }

    public class func new( fd: Int, _ mode: string_like = "r", file: StaticString = __FILE__, line: UInt = __LINE__ ) -> IO? {
        return for_fd( fd, mode, file: file, line: line )
    }

    public class func open( fd: Int, _ mode: string_like = "r", file: StaticString = __FILE__, line: UInt = __LINE__ ) -> IO? {
        return for_fd( fd, mode, file: file, line: line )
    }

    public class func pipe( file: StaticString = __FILE__, line: UInt = __LINE__ ) -> (reader: IO?, writer: IO?) {
        var fds = [Int32](count: 0, repeatedValue: 0)
        Darwin.pipe( &fds )
        return (IO.new( Int(fds[0]), "r", file: file, line: line ), IO.new( Int(fds[1]), "w", file: file, line: line ))
    }

    public class func popen( command: string_like, _ mode: string_like = "r", file: StaticString = __FILE__, line: UInt = __LINE__ ) -> IO? {
        return IO( what: "IO.popen '\(command)'", unixFILE: Darwin.popen( command.to_s, mode.to_s ), file: file, line: line ).ifValid()
    }

    public class func read( name: string_like, _ length: Int? = nil, _ offset: Int? = nil, file: StaticString = __FILE__, line: UInt = __LINE__ ) -> Data? {
        if let ioFile = File.open( name, "r" ) {
            if offset != nil {
                ioFile.seek( offset!, Int(SEEK_SET), file: file, line: line )
            }
            return ioFile.read( length )
        }
        return nil
    }

    public class func readlines( name: string_like, _ sep: string_like = LINE_SEPARATOR, _ limit: Int? = nil, file: StaticString = __FILE__, line: UInt = __LINE__ ) -> [String]? {
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

    public class func readlines( name: string_like, _ limit: Int? = nil, file: StaticString = __FILE__, line: UInt = __LINE__ ) -> [String]? {
        return readlines( name, LINE_SEPARATOR, limit, file: file, line: line )
    }

    public class func select( read_array: [IO]?, _ write_array: [IO]? = nil, _ error_array: [IO]? = nil,
                        timeout: Double? = nil, file: StaticString = __FILE__, line: UInt = __LINE__ )
                            -> (readable: [IO], writable: [IO], errored: [IO])? {

        let read_flags = UnsafeMutablePointer<Int32>( malloc( sizeof(fd_set) ) )
        let write_flags = UnsafeMutablePointer<Int32>( malloc( sizeof(fd_set) ) )
        let error_flags = UnsafeMutablePointer<Int32>( malloc( sizeof(fd_set) ) )
        var max_fd = -1

        for (array, flags) in [(read_array, read_flags), (write_array, write_flags), (error_array, error_flags)] {
            FD_ZERO( flags )
            if array != nil {
                for io in array! {
                    FD_SET( io.fileno, flags )
                    if max_fd < io.fileno {
                        max_fd = io.fileno
                    }
                }
            }
        }

        var time: Time?
        if timeout != nil {
            time = Time( time_f: timeout! )
        }

        func mutablePointer<T>( inout val: T ) -> UnsafeMutablePointer<T> {
            return withUnsafeMutablePointer (&val) {
                UnsafeMutablePointer($0)
            }
        }

        let selected = Darwin.select( Int32(max_fd),
                        UnsafeMutablePointer<fd_set>( read_flags ),
                        UnsafeMutablePointer<fd_set>( write_flags ),
                        UnsafeMutablePointer<fd_set>( error_flags ),
            time != nil ? mutablePointer( &time!.value ) : nil )

        var out: (readable: [IO], writable: [IO], errored: [IO])?

        if selected < 0 {
            unixOK( "IO.select", selected, file: file, line: line )
        }
        else if selected > 0 {
            var readable = [IO](), writable = [IO](), errored = [IO]()

            for (array, flags, out) in [
                (read_array, read_flags, mutablePointer( &readable )),
                (write_array, write_flags, mutablePointer( &writable )),
                (error_array, error_flags, mutablePointer( &errored ))] {
                if array != nil {
                    for io in array! {
                       if FD_ISSET( io.fileno, flags ) {
                            out.memory.append( io )
                        }
                    }
                }
            }

            out = (readable, writable, errored)
        }

        free( read_flags )
        free( write_flags )
        free( error_flags )
        return out
    }

    public class func sysopen( path: string_like, _ mode: Int = Int(O_RDONLY), _ perm: Int = 0o644 ) -> fixnum {
        return Int(Darwin.open( path.to_s, CInt(mode), mode_t(perm) ))
    }


    public class func write( name: string_like, _ string: data_like, _ offset: Int? = 0, _ open_args: String? = nil, file: StaticString = __FILE__, line: UInt = __LINE__ ) -> fixnum? {
        if let ioFile = File.open( name, open_args ?? "w", file: file, line: line ) {
            if offset != nil {
                ioFile.seek( offset!, Int(SEEK_SET), file: file, line: line )
            }
            return ioFile.write( string )
        }
        return nil
    }

    // MARK: Instance methods

//    public func advise( advice: Int, _ offset: Int = 0, _ len: Int = 0 ) {
//        RKNotImplemented( "IO.advise" )
//    }

    public func bytes( block: (CChar) -> () ) -> IO {
        return each_byte( block )
    }

    public func chars( block: (CChar16) -> () ) -> IO {
        return each_char( block )
    }

    public func close( file: StaticString = __FILE__, line: UInt = __LINE__ ) -> Int {
        if _unixFILE != nil {
            var status = pclose( unixFILE )
            if status == -1 {
                status = fclose( unixFILE )
            }
            _unixFILE = nil
            return Int(status)
        }
        return -1
    }

//    public func close_read() {
//        RKNotImplemented( "IO.close_read" )
//    }
//
//    public func close_write() {
//        RKNotImplemented( "IO.close_write" )
//    }

    public var closed: Bool {
        return unixFILE == nil
    }

    public func each_byte( block: (CChar) -> () ) -> IO {
        while true {
            let byte = CChar(fgetc( unixFILE ))
            if eof {
                break
            }
            block( byte )
        }
        return self
    }

    public func each_char( block: (CChar16) -> () ) -> IO {
        read()?.to_s.utf16.each( block )
        return self
    }

    public func each( limit: Int? = nil, _ block: (line: String) -> () ) -> IO {
        return each_line( LINE_SEPARATOR, limit, block )
    }

    public func each( sep: string_like = LINE_SEPARATOR, _ limit: Int? = nil, _ block: (line: String) -> () ) -> IO {
        return each_line( sep, limit, block )
    }

//    public func each_line( limit: Int? = nil, _ block: (line: String) -> () ) -> IO {
//        return each_line( dollarSlash, limit, block )
//    }
//
    public func each_line( sep: string_like = LINE_SEPARATOR, _ limit: Int? = nil, _ block: (line: String) -> () ) -> IO {
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
        return feof( unixFILE ) != 0
    }

    public func fcntl( arg: Int, _ arg2: Int = 0 ) -> Int {
        return Int(_fcntl( Int32(fileno), Int32(arg), Int32(arg2) ))
    }

//    public func fdatasync() {
//        RKNotImplemented( "IO.fdatasync" )
//    }

    public var fileno: Int {
        return Int(Darwin.fileno( unixFILE ))
    }

    public func flush( file: StaticString = __FILE__, line: UInt = __LINE__ ) -> Bool {
        return unixOK( "IO.fflush", fflush( unixFILE ), file: file, line: line )
    }

    public func fsync( file: StaticString = __FILE__, line: UInt = __LINE__ ) -> Bool {
        return flush() && unixOK( "IO.fsync", Darwin.fsync( Int32(fileno) ), file: file, line: line )
    }

    public var getbyte: fixnum? {
        let byte = CChar(fgetc( unixFILE ))
        if feof( unixFILE ) != 0 {
            return nil
        }
        return Int(byte)
    }

    public var getc: String? {
        let byte = CChar(fgetc( unixFILE ))
        if feof( unixFILE ) != 0 {
            return nil
        }
        return String(byte)
    }

    static public let newline = Int8("\n".ord)
    static public let retchar = Int8("\r".ord)

    func gets( sep: string_like = LINE_SEPARATOR ) -> String? {
        let data = Data( capacity: 1_000_000 ) //// TODO: should loop
        if fgets( data.bytes, Int32(data.capacity), unixFILE ) == nil {
            return nil
        }
        lineno++
        data.length = Int(strlen( data.bytes ))
        if data.length > 0 && data.bytes[data.length-1] == IO.newline {
            data.bytes[--data.length] = 0
        }
        if data.length > 0 && data.bytes[data.length-1] == IO.retchar {
            data.bytes[--data.length] = 0
        }
        return data.to_s
    }

    public var inspect: String {
        return self.to_s
    }

    public var internal_encoding: Int {
        return Int(STRING_ENCODING)
    }

//    public func ioctl( integer_cmd: Int, arg: Int ) -> Int {
//        RKNotImplemented( "IO.ioctl" )
//        return 1
//    }

    public var isatty: Bool {
        return Darwin.isatty( Int32(fileno) ) != 0
    }

    public func lines( block: (line: String) -> () ) -> IO {
        return each_line( LINE_SEPARATOR, nil, block )
    }

//    public var pid: Int {
//        /// not possible without re-implementing popen()
//        RKNotImplemented( "IO.pid" )
//        return -1
//    }

    public func print( string: string_like ) -> Int {
        return Int(fputs( string.to_s, unixFILE ))
    }

    public func print( strings: array_like ) {
        for string in strings.to_a {
            print( string )
        }
    }

    func printf( string: string_like ) {
        print( string )
    }

    func putc( obj: Int ) -> Int {
        return Int(fputc( Int32(obj), unixFILE ))
    }

    public func puts( string: string_like ) -> Int {
        return print( string )
    }

    public func puts( strings: array_like ) {
        return print( strings )
    }
    
    public func read( length: Int? = nil, _ outbuf: Data? = nil ) -> Data? {
        let data = outbuf ?? Data( capacity: (length ?? stat?.size ?? 1_000_000)+1 ) ////
        while true {
            let toread = data.capacity-data.length
            let wasread = fread( data.bytes+data.length, 1, toread, unixFILE )
            data.length += wasread
            if wasread != toread {
                break
            }
            data.capacity *= 2
        }
        return ferror( unixFILE ) == 0 || feof( unixFILE ) != 0 ? data : nil
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

    public func readline( sep: string_like = LINE_SEPARATOR ) -> String? {
        return gets( sep )
    }

    public func readlines( /*sep: string_like = dollarSlash, _*/ limit: Int? = nil ) -> [String] {
        var out = [String]()
        each_line( LINE_SEPARATOR, limit, {
            (line) in
            out.append( line )
        } )
        return out
    }

//    public func readlines( limit: Int? = nil ) -> [String] {
//        return readlines( dollarSlash, limit )
//    }

//    public func readpartial( maxlen: Int, _ outbuf: Data? = nil ) -> Data? {
//        RKNotImplemented( "IO.readpartial" )
//        return nil
//    }

    public func reopen( other_IO: IO ) -> IO {
        _unixFILE = other_IO.unixFILE ////
        return self
    }

    public func reopen( path: string_like, _ mode_str: string_like = "r", file: StaticString = __FILE__, line: UInt = __LINE__ ) -> IO? {
        return unixOK( "IO.reopen \(path.to_s)", freopen( path.to_s, mode_str.to_s, self.unixFILE ) == nil ? 1 : 0,
                        file: file, line: line ) ? self : nil
    }

    public func rewind( file: StaticString = __FILE__, line: UInt = __LINE__ ) -> IO {
        Darwin.rewind( unixFILE )
        return self
    }

    public func seek( amount: Int, _ whence: Int = Int(SEEK_SET), file: StaticString = __FILE__, line: UInt = __LINE__ ) -> Bool {
        return unixOK( "IO.seek", fseek( unixFILE, amount, Int32(whence) ), file: file, line: line )
    }

//    public func set_encoding( ext_enc: Int ) -> IO? {
//        RKNotImplemented( "IO.set_encoding" )
//        return nil
//    }

    public var stat: Stat? {
        return Stat( fd: fileno, file: __FILE__, line: __LINE__ )
    }

    public func sysread( maxlen: Int? = nil, _ outbuf: Data? = nil ) -> Data? {
        let data = outbuf ?? Data( capacity: maxlen ?? stat?.size ?? 1_000_000 ) ////
        data.length = Darwin.read( Int32(fileno), data.bytes, data.capacity )
        return data.length > 0 ? data : nil
    }

    public func sysseek( offset: Int, _ whence: Int = Int(SEEK_SET) ) -> Int {
        return Int(lseek( Int32(fileno), off_t(offset), Int32(whence) ))
    }

    public func syswrite( string: data_like ) -> Int {
        return Int(Darwin.write( Int32(fileno), string.to_d.bytes, string.to_d.length ))
    }

    public var tell: Int {
        return pos
    }

    public var to_a: [String] {
        return readlines()
    }

    public var to_i: Int {
        return fileno
    }

    public var to_d: Data {
        if let data = read() {
            return data
        }
        SRLog( "IO.to_d, no data" )
        return "IO.to_d, no data".to_d
    }

    public var to_s: String {
        if let data = read() {
            return data.to_s
        }
        SRLog( "IO.to_s, no data" )
        return "IO.to_s, no data"
    }

    public var tty: Bool {
        return isatty
    }

    public func ungetbyte( string: string_like ) {
        ungetc( Int32(string.to_s.characterAtIndex(0)), unixFILE ) ////
    }

    public func ungetbyte( byte: Int ) {
        ungetc( Int32(byte), unixFILE )
    }

    public func write( string: data_like ) -> fixnum {
        let data = string.to_d
        return fwrite( data.bytes, 1, data.length, unixFILE );
    }

    public func write_nonblock( string: data_like, options: Array<String>? = nil ) -> Int {
        nonblock = true
        return write( string )
    }

    deinit {
        if autoclose {
            close()
        }
    }

}
