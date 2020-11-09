//
//  IO.swift
//  SwiftRuby
//
//  Created by John Holdsworth on 26/09/2015.
//  Copyright © 2015 John Holdsworth. All rights reserved.
//
//  $Id: //depot/SwiftRuby/IO.swift#15 $
//
//  Repo: https://github.com/RubyNative/SwiftRuby
//
//  See: http://ruby-doc.org/core-2.2.3/IO.html
//

import Darwin

public let EWOULDBLOCKWaitReadable = EWOULDBLOCK
public let EWOULDBLOCKWaitWritable = EWOULDBLOCK

private let selectBitsPerFlag: Int32 = 32
private let selectShift = 5
private let selectBitMask = (1<<selectShift)-1

public func FD_ZERO(_ flags: UnsafeMutablePointer<Int32>) {
    memset(flags, 0, MemoryLayout<fd_set>.size)
}

public func FD_CLR(_ fd: Int, _ flags: UnsafeMutablePointer<Int32>) {
    let set = flags + Int(fd>>selectShift)
    set.pointee &= ~Int32(1<<(fd&selectBitMask))
}

public func FD_SET(_ fd: Int, _ flags: UnsafeMutablePointer<Int32>) {
    let set = flags + Int(fd>>selectShift)
    set.pointee |= Int32(1<<(fd&selectBitMask))
}

public func FD_ISSET(_ fd: Int, _ flags: UnsafeMutablePointer<Int32>) -> Bool {
    let set = flags + Int(fd>>selectShift)
    return (set.pointee & Int32(1<<(fd&selectBitMask))) != 0
}

public func ==(lhs: IO, rhs: IO) -> Bool {
    if let lhData = lhs.read(), let rhData = rhs.read() {
        return lhData == rhData
    }
    return false
}

open class IO: RubyObject, string_like, data_like {

    fileprivate var _unixFILE: UnsafeMutablePointer<FILE>?
    open var unixFILE: UnsafeMutablePointer<FILE>? {
        get {
            if _unixFILE == nil {
                SRLog("Get of nil IO.unixFILE")
            }
            return _unixFILE
        }
    }

    open var autoclose = true
    public let binmode = true
    open var lineno = 0

    open var sync = true {
        didSet {
            flush()
            setvbuf(unixFILE, nil, sync ? _IONBF : _IOFBF, 0)
        }
    }

    open var nonblock = false {
        didSet {
            var flags = fcntl(Int(F_GETFL), 0)
            if nonblock {
                flags |= Int(O_NONBLOCK)
            }
            else {
                flags &= ~Int(O_NONBLOCK)
            }
            fcntl(Int(F_SETFL), flags)
        }
    }

    open var close_on_exec = false {
        didSet {
            if close_on_exec {
                fcntl(Int(F_SETFD), Int(FD_CLOEXEC))
            }
        }
    }

    open var pos: Int {
        get {
            return Int(ftell(unixFILE))
        }
        set {
            seek(newValue)
        }
    }

    public init(what: String?, unixFILE: UnsafeMutablePointer<FILE>?, file: StaticString = #file, line: UInt = #line) {
        super.init()
        if unixFILE == nil && what != nil {
            SRError("\(what!) failed", file: file, line: line)
        }
        self._unixFILE = unixFILE
    }

    open func ifValid() -> IO? {
        return _unixFILE != nil ? self : nil
    }

    // MARK: Class methods

    open class func binread(_ name: string_like, _ length: Int? = nil, _ offset: Int? = nil) -> Data? {
        return self.read(name, length, offset)
    }

    open class func binwrite(_ name: string_like, _ string: data_like, _ offset: Int? = nil) -> fixnum? {
        return self.write(name, string, offset)
    }

    open class func copy_stream(_ src: IO, _ dst: IO, _ copy_length: Int? = nil, _ src_offset: Int? = nil) -> Int {
        if src_offset != nil {
            src.seek(src_offset!, Int(SEEK_SET))
        }
        var copied = 0
        let data = Data(capacity: 1024*1024)
        while let data = src.read(data.capacity, data) {
            copied += data.length
            dst.write(data)
            data.length = 0
        }
        return copied
    }

    open class func for_fd(_ fd: Int, _ mode: string_like, opt: Array<String>? = nil, file: StaticString = #file, line: UInt = #line) -> IO? {
        return IO(what: "fdopen \(fd)", unixFILE: fdopen(Int32(fd), mode.to_s), file: file, line: line).ifValid()
    }

    open class func foreach(_ name: string_like, _ sep: string_like = LINE_SEPARATOR,
                                _ limit: Int? = nil, _ block: (_ line: String) -> ()) {
        if let nameInt = Int(name.to_s),
            let ioFile = File.open(nameInt, "r") {
            ioFile.each_line(sep, limit, block)
        }
    }

    open class func foreach(_ name: string_like, _ limit: Int? = nil, _ block: (_ line: String) -> ()) {
        foreach(name, LINE_SEPARATOR, limit, block)
    }

    open class func new(_ fd: Int, _ mode: string_like = "r", file: StaticString = #file, line: UInt = #line) -> IO? {
        return for_fd(fd, mode, file: file, line: line)
    }

    open class func open(_ fd: Int, _ mode: string_like = "r", file: StaticString = #file, line: UInt = #line) -> IO? {
        return for_fd(fd, mode, file: file, line: line)
    }

    open class func pipe(_ file: StaticString = #file, line: UInt = #line) -> (reader: IO?, writer: IO?) {
        var fds = [Int32](repeating: 0, count: 0)
        _ = Darwin.pipe(&fds)
        return (IO.new(Int(fds[0]), "r", file: file, line: line), IO.new(Int(fds[1]), "w", file: file, line: line))
    }

    open class func popen(_ command: string_like, _ mode: string_like = "r", file: StaticString = #file, line: UInt = #line) -> IO? {
        return IO(what: "IO.popen '\(command)'", unixFILE: _popen(command.to_s, mode.to_s), file: file, line: line).ifValid()
    }

    open class func read(_ name: string_like, _ length: Int? = nil, _ offset: Int? = nil, file: StaticString = #file, line: UInt = #line) -> Data? {
        if let nameInt = Int(name.to_s),
            let ioFile = File.open(nameInt, "r") {
            if offset != nil {
                ioFile.seek(offset!, Int(SEEK_SET), file: file, line: line)
            }
            return ioFile.read(length)
        }
        return nil
    }

    open class func readlines(_ name: string_like, _ sep: string_like = LINE_SEPARATOR, _ limit: Int? = nil, file: StaticString = #file, line: UInt = #line) -> [String]? {
        if let nameInt = Int(name.to_s),
            let ioFile = File.open(nameInt, "r", file: file, line: line) {
            var out = [String]()
            ioFile.each_line(sep, limit, {
                (line) in
                out.append(line)
            })
            return out
        }
        return nil
    }

    open class func readlines(_ name: string_like, _ limit: Int? = nil, file: StaticString = #file, line: UInt = #line) -> [String]? {
        return readlines(name, LINE_SEPARATOR, limit, file: file, line: line)
    }

    open class func select(_ read_array: [IO]?, _ write_array: [IO]? = nil, _ error_array: [IO]? = nil,
                        timeout: Double? = nil, file: StaticString = #file, line: UInt = #line)
                            -> (readable: [IO], writable: [IO], errored: [IO])? {

        let read_flags = malloc(MemoryLayout<fd_set>.size)!.assumingMemoryBound(to: Int32.self)
        let write_flags = malloc(MemoryLayout<fd_set>.size)!.assumingMemoryBound(to: Int32.self)
        let error_flags = malloc(MemoryLayout<fd_set>.size)!.assumingMemoryBound(to: Int32.self)
        var max_fd = -1

        for (array, flags) in [(read_array, read_flags), (write_array, write_flags), (error_array, error_flags)] {
            FD_ZERO(flags)
            if array != nil {
                for io in array! {
                    FD_SET(io.fileno, flags)
                    if max_fd < io.fileno {
                        max_fd = io.fileno
                    }
                }
            }
        }

        var time: Time?
        if timeout != nil {
            time = Time(time_f: timeout!)
        }

        func mutablePointer<T>(_ val: inout T) -> UnsafeMutablePointer<T> {
            return withUnsafeMutablePointer (to: &val) {
                UnsafeMutablePointer($0)
            }
        }


        let selected = read_flags.withMemoryRebound(to: fd_set.self, capacity: 1) { read_set in
            return write_flags.withMemoryRebound(to: fd_set.self, capacity: 1) { write_set in
                return error_flags.withMemoryRebound(to: fd_set.self, capacity: 1) { error_set in
                    Darwin.select(Int32(max_fd), read_set, write_set, error_set,
                                   time != nil ? mutablePointer(&time!.value) : nil)
                }
            }
        }

        var out: (readable: [IO], writable: [IO], errored: [IO])?

        if selected < 0 {
            unixOK("IO.select", selected, file: file, line: line)
        }
        else if selected > 0 {
            var readable = [IO](), writable = [IO](), errored = [IO]()

            for (array, flags, out) in [
                (read_array, read_flags, mutablePointer(&readable)),
                (write_array, write_flags, mutablePointer(&writable)),
                (error_array, error_flags, mutablePointer(&errored))] {
                if array != nil {
                    for io in array! {
                       if FD_ISSET(io.fileno, flags) {
                            out.pointee.append(io)
                        }
                    }
                }
            }

            out = (readable, writable, errored)
        }

        free(read_flags)
        free(write_flags)
        free(error_flags)
        return out
    }

    open class func sysopen(_ path: string_like, _ mode: Int = Int(O_RDONLY), _ perm: Int = 0o644) -> fixnum {
        return Int(Darwin.open(path.to_s, CInt(mode), mode_t(perm)))
    }

    @discardableResult
    open class func write(_ name: string_like, _ string: data_like, _ offset: Int? = 0, _ open_args: String? = nil, file: StaticString = #file, line: UInt = #line) -> fixnum? {
        if let ioFile = File.open(name, open_args ?? "w", file: file, line: line) {
            if offset != nil {
                ioFile.seek(offset!, Int(SEEK_SET), file: file, line: line)
            }
            return ioFile.write(string)
        }
        return nil
    }

    // MARK: Instance methods

//    public func advise(advice: Int, _ offset: Int = 0, _ len: Int = 0) {
//        RKNotImplemented("IO.advise")
//    }

    open func bytes(_ block: (CChar) -> ()) -> IO {
        return each_byte(block)
    }

    open func chars(_ block: (CChar16) -> ()) -> IO {
        return each_char(block)
    }

    @discardableResult
    open func close(_ file: StaticString = #file, line: UInt = #line) -> Int {
        if _unixFILE != nil {
            var status = _pclose(unixFILE!)
            if status == -1 {
                status = fclose(unixFILE)
            }
            _unixFILE = nil
            return Int(status)
        }
        return -1
    }

//    public func close_read() {
//        RKNotImplemented("IO.close_read")
//    }
//
//    public func close_write() {
//        RKNotImplemented("IO.close_write")
//    }

    open var closed: Bool {
        return unixFILE == nil
    }

    open func each_byte(_ block: (CChar) -> ()) -> IO {
        while true {
            let byte = CChar(fgetc(unixFILE))
            if eof {
                break
            }
            block(byte)
        }
        return self
    }

    @discardableResult
    open func each_char(_ block: (CChar16) -> ()) -> IO {
        read()?.to_s.utf16.each(block)
        return self
    }

    open func each(_ limit: Int? = nil, _ block: (_ line: String) -> ()) -> IO {
        return each_line(LINE_SEPARATOR, limit, block)
    }

    open func each(_ sep: string_like = LINE_SEPARATOR, _ limit: Int? = nil, _ block: (_ line: String) -> ()) -> IO {
        return each_line(sep, limit, block)
    }

//    public func each_line(limit: Int? = nil, _ block: (line: String) -> ()) -> IO {
//        return each_line(dollarSlash, limit, block)
//    }
//
    @discardableResult
    open func each_line(_ sep: string_like = LINE_SEPARATOR, _ limit: Int? = nil, _ block: (_ line: String) -> ()) -> IO {
        var count = 0
        while let line = readline(sep) {
            block(line)
            if limit != nil {
                count += 1
                if count >= limit! {
                    break
                }
            }
        }
        return self
    }

    open var eof: Bool {
        return feof(unixFILE) != 0
    }

    @discardableResult
    open func fcntl(_ arg: Int, _ arg2: Int = 0) -> Int {
        return Int(fcntl3(Int32(fileno), Int32(arg), Int32(arg2)))
    }

//    public func fdatasync() {
//        RKNotImplemented("IO.fdatasync")
//    }

    open var fileno: Int {
        return Int(Darwin.fileno(unixFILE))
    }

    @discardableResult
    open func flush(_ file: StaticString = #file, line: UInt = #line) -> Bool {
        return unixOK("IO.fflush", fflush(unixFILE), file: file, line: line)
    }

    open func fsync(_ file: StaticString = #file, line: UInt = #line) -> Bool {
        return flush() && unixOK("IO.fsync", Darwin.fsync(Int32(fileno)), file: file, line: line)
    }

    open var getbyte: fixnum? {
        let byte = CChar(fgetc(unixFILE))
        if feof(unixFILE) != 0 {
            return nil
        }
        return Int(byte)
    }

    open var getc: String? {
        let byte = CChar(fgetc(unixFILE))
        if feof(unixFILE) != 0 {
            return nil
        }
        return String(byte)
    }

    static public let newline = Int8("\n".ord)
    static public let retchar = Int8("\r".ord)

    func gets(_ sep: string_like = LINE_SEPARATOR) -> String? {
        let data = Data(capacity: 1_000_000) //// TODO: should loop
        if fgets(data.bytes, Int32(data.capacity), unixFILE) == nil {
            return nil
        }
        lineno += 1
        data.length = Int(strlen(data.bytes))
        if data.length > 0 && data.bytes[data.length-1] == IO.newline {
            data.length -= 1
            data.bytes[data.length] = 0
        }
        if data.length > 0 && data.bytes[data.length-1] == IO.retchar {
            data.length -= 1
            data.bytes[data.length] = 0
        }
        return data.to_s
    }

    open var inspect: String {
        return self.to_s
    }

    open var internal_encoding: Int {
        return Int(STRING_ENCODING.rawValue)
    }

//    public func ioctl(integer_cmd: Int, arg: Int) -> Int {
//        RKNotImplemented("IO.ioctl")
//        return 1
//    }

    open var isatty: Bool {
        return Darwin.isatty(Int32(fileno)) != 0
    }

    open func lines(_ block: (_ line: String) -> ()) -> IO {
        return each_line(LINE_SEPARATOR, nil, block)
    }

//    public var pid: Int {
//        /// not possible without re-implementing popen()
//        RKNotImplemented("IO.pid")
//        return -1
//    }

    @discardableResult
    open func print(_ string: string_like) -> Int {
        return Int(fputs(string.to_s, unixFILE))
    }

    open func print(_ strings: array_like) {
        for string in strings.to_a {
            print(string)
        }
    }

    func printf(_ string: string_like) {
        print(string)
    }

    func putc(_ obj: Int) -> Int {
        return Int(fputc(Int32(obj), unixFILE))
    }

    open func puts(_ string: string_like) -> Int {
        return print(string)
    }

    open func puts(_ strings: array_like) {
        return print(strings)
    }
    
    open func read(_ length: Int? = nil, _ outbuf: Data? = nil) -> Data? {
        let data = outbuf ?? Data(capacity: (length ?? stat?.size ?? 1_000_000)+1) ////
        while true {
            let toread = data.capacity-data.length
            let wasread = fread(data.bytes+data.length, 1, toread, unixFILE)
            data.length += wasread
            if wasread != toread {
                break
            }
            data.capacity *= 2
        }
        return ferror(unixFILE) == 0 || feof(unixFILE) != 0 ? data : nil
    }

    open func read_nonblock(_ length: Int? = nil, _ outbuf: Data? = nil) -> Data? {
        nonblock = true
        return read(length, outbuf)
    }

    open var readbyte: fixnum? {
        return getbyte
    }

    open var readchar: String? {
        return getc
    }

    open func readline(_ sep: string_like = LINE_SEPARATOR) -> String? {
        return gets(sep)
    }

    open func readlines(/*sep: string_like = dollarSlash, _*/ _ limit: Int? = nil) -> [String] {
        var out = [String]()
        each_line(LINE_SEPARATOR, limit, {
            (line) in
            out.append(line)
        })
        return out
    }

//    public func readlines(limit: Int? = nil) -> [String] {
//        return readlines(dollarSlash, limit)
//    }

//    public func readpartial(maxlen: Int, _ outbuf: Data? = nil) -> Data? {
//        RKNotImplemented("IO.readpartial")
//        return nil
//    }

    open func reopen(_ other_IO: IO) -> IO {
        _unixFILE = other_IO.unixFILE ////
        return self
    }

    open func reopen(_ path: string_like, _ mode_str: string_like = "r", file: StaticString = #file, line: UInt = #line) -> IO? {
        return unixOK("IO.reopen \(path.to_s)", freopen(path.to_s, mode_str.to_s, self.unixFILE) == nil ? 1 : 0,
                        file: file, line: line) ? self : nil
    }

    open func rewind(_ file: StaticString = #file, line: UInt = #line) -> IO {
        Darwin.rewind(unixFILE)
        return self
    }

    @discardableResult
    open func seek(_ amount: Int, _ whence: Int = Int(SEEK_SET), file: StaticString = #file, line: UInt = #line) -> Bool {
        return unixOK("IO.seek", fseek(unixFILE, amount, Int32(whence)), file: file, line: line)
    }

//    public func set_encoding(ext_enc: Int) -> IO? {
//        RKNotImplemented("IO.set_encoding")
//        return nil
//    }

    open var stat: Stat? {
        return Stat(fd: fileno, file: #file, line: #line)
    }

    open func sysread(_ maxlen: Int? = nil, _ outbuf: Data? = nil) -> Data? {
        let data = outbuf ?? Data(capacity: maxlen ?? stat?.size ?? 1_000_000) ////
        data.length = Darwin.read(Int32(fileno), data.bytes, data.capacity)
        return data.length > 0 ? data : nil
    }

    open func sysseek(_ offset: Int, _ whence: Int = Int(SEEK_SET)) -> Int {
        return Int(lseek(Int32(fileno), off_t(offset), Int32(whence)))
    }

    open func syswrite(_ string: data_like) -> Int {
        return Int(Darwin.write(Int32(fileno), string.to_d.bytes, string.to_d.length))
    }

    open var tell: Int {
        return pos
    }

    open var to_a: [String] {
        return readlines()
    }

    open var to_i: Int {
        return fileno
    }

    open var to_d: Data {
        if let data = read() {
            return data
        }
        SRLog("IO.to_d, no data")
        return "IO.to_d, no data".to_d
    }

    open var to_s: String {
        if let data = read() {
            return data.to_s
        }
        SRLog("IO.to_s, no data")
        return "IO.to_s, no data"
    }

    open var tty: Bool {
        return isatty
    }

    open func ungetbyte(_ string: string_like) {
        ungetc(Int32(string.to_s.characterAtIndex(0)), unixFILE) ////
    }

    open func ungetbyte(_ byte: Int) {
        ungetc(Int32(byte), unixFILE)
    }

    @discardableResult
    open func write(_ string: data_like) -> fixnum {
        let data = string.to_d
        return fwrite(data.bytes, 1, data.length, unixFILE);
    }

    open func write_nonblock(_ string: data_like, options: Array<String>? = nil) -> Int {
        nonblock = true
        return write(string)
    }

    deinit {
        if autoclose {
            close()
        }
    }

}
