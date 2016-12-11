//
//  Time.swift
//  SwiftRuby
//
//  Created by John Holdsworth on 26/09/2015.
//  Copyright © 2015 John Holdsworth. All rights reserved.
//
//  $Id: //depot/SwiftRuby/Time.swift#10 $
//
//  Repo: https://github.com/RubyNative/SwiftRuby
//
//  See: http://ruby-doc.org/core-2.2.3/Time.html
//

import Darwin

open class Time : RubyObject, string_like {

    open var value = timeval()
    open var tzone = timezone()
    open var tmout: tm?

    open var isUTC = false {
        didSet {
            tmout =  nil
        }
    }

    open class func now() -> Time {
        return Time()
    }

    public convenience override init() {
        self.init( seconds: nil )
        gettimeofday( &value, &tzone )
    }

    public init( seconds: Int?, usec: Int = 0 ) { ///
        super.init()
        if seconds != nil {
            value.tv_sec = seconds!.to_i
            value.tv_usec = suseconds_t(usec.to_i)
        }
    }

    public convenience init( spec: timespec ) {
        self.init( seconds: spec.tv_sec, usec: spec.tv_nsec/1_000 )
    }

    public convenience init( time_f: Double ) {
        let time_i = Int(time_f.to_f)
        self.init( seconds: time_i, usec: Int((time_f.to_f-Double(time_i))*1_000_000) )
    }

    // MARK: Class methods

    open class func at( _ time: Time ) -> Time {
        return Time( seconds: Int(time.value.tv_sec), usec: Int(time.value.tv_usec) )
    }

    open class func at( _ time_f: float_like ) -> Time {
        return Time( time_f: time_f.to_f )
    }

    open class func at( _ time: Int, usec: Double = 0 ) -> Time {
        return Time( seconds: time, usec: Int(usec.to_f) )
    }

    open class func at( _ time: string_like, format: string_like = "%Y-%m-%d %H:%M:%S %z" ) -> Time {
        return strptime( time, format: format )
    }

    open class func strptime( _ time: string_like, format: string_like ) -> Time {
        var mktm = tm()
        _ = Darwin.strptime( time.to_s, format.to_s, &mktm )
        return Time( seconds: mktime( &mktm ) )
    }

    open class func local( _ year: Int = 0, month: Int = 0, day: Int = 0,
            hour: Int = 0, min: Int = 0, sec: Int = 0, usec_with_frac: Double = 0.0 ) -> Time {
        var mktm = tm(tm_sec: Int32(sec), tm_min: Int32(min), tm_hour: Int32(hour),
            tm_mday: 0, tm_mon: Int32(month), tm_year: Int32(year),
            tm_wday: 0, tm_yday: 0, tm_isdst: 0, tm_gmtoff: 0, tm_zone: getenv("TZ"))
        return Time( seconds: mktime( &mktm ) )
    }

    // MARK: Instance methods

    func settm() -> tm {
        if tmout == nil {
            tmout = tm()
            if isUTC {
                gmtime_r( &value.tv_sec, &tmout! )
            }
            else {
                localtime_r( &value.tv_sec, &tmout! );
            }
        }
        return tmout!
    }

    open var asctime: String {
        var out = [CChar]( repeating: 0, count: 30 )
        var tmp = settm()
        asctime_r( &tmp, &out )
        return String( validatingUTF8: out )!
    }

    open var ctime: String {
        return asctime
    }

    open var day: Int {
        return Int(settm().tm_mday)
    }

    open var dst: Bool {
        return settm().tm_isdst != 0
    }

    open func eql( _ other_time: Time ) -> Bool {
        return value.tv_sec == other_time.value.tv_sec && value.tv_usec == other_time.value.tv_usec
    }

    open var friday: Bool {
        return settm().tm_wday == 5
    }

    open var getgm: Time {
        let gm = Time.at( self )
        gm.isUTC = true
        return gm
    }

    open var getlocal: Time {
        let gm = Time.at( self )
        gm.isUTC = false
        return gm
    }

    open func getlocal( _ utc_offset: Int ) -> Time? {
        return nil////
    }

    open var getutc: Time {
        return getgm
    }

    open var gmt: Bool {
        return isUTC
    }

    open var gmt_offset: Int {
        return isUTC ? 0 : settm().tm_gmtoff
    }

    open var gmtime: Time {
        isUTC = true
        return self
    }

    open var gmtoff: Int {
        return gmt_offset
    }

    open var hour: Int {
        return Int(settm().tm_hour)
    }

    open var inspect: String {
        return self.strftime( isUTC ? "%Y-%m-%d %H:%M:%S UTC" : "%Y-%m-%d %H:%M:%S %z" )
    }

    open var isdst: Bool {
        return settm().tm_isdst != 0
    }

    open var localtime: Time {
        return getlocal
    }

    open func localtime( _ utc_offset: Int ) -> Time? {
        return nil////
    }

    open var mday: fixnum {
        return Int(settm().tm_mday)
    }

    open var min: fixnum {
        return Int(settm().tm_min)
    }

    open var mon: fixnum {
        return Int(settm().tm_mon)+1
    }

    open var month: fixnum {
        return Int(settm().tm_mon)
    }

    open var monday: Bool {
        return settm().tm_wday == 1
    }

    open var nsec: Int {
        return Int(value.tv_usec) * 1_000
    }

    open func round( _ ndigits: Int ) -> Time {
        let divisor = pow( 10.0, Double(ndigits.to_i) )
        return Time( time_f: Darwin.round(self.to_f * divisor) / divisor )
    }

    open var saturday: Bool {
        return settm().tm_wday == 6
    }

    open var sec: fixnum {
        return Int(settm().tm_sec)
    }

    open func strftime( _ format: string_like ) -> String {
        var out = [Int8]( repeating: 0, count: 1000 )
        var tmp = settm()
        _ = Darwin.strftime( &out, out.count, format.to_s,  &tmp )
        return String( validatingUTF8: out )!
    }

    open var succ: Time {
        return Time( seconds: value.tv_sec+1, usec: Int(value.tv_usec) )
    }

    open var sunday: Bool {
        return settm().tm_wday == 0
    }

    open var thursday: Bool {
        return settm().tm_wday == 4
    }

    open var to_a: [String] {
        let tmp = settm()
        return [String(tmp.tm_sec), String(tmp.tm_min), String(tmp.tm_hour), String(tmp.tm_mday), String(tmp.tm_mon),
            String(tmp.tm_year), String(tmp.tm_wday), String(tmp.tm_yday), String(tmp.tm_isdst), String(describing: tmp.tm_zone)]
    }

    open var to_f: Double {
        return Double(value.tv_sec) + Double(value.tv_usec)/1_000_000
    }

    open var to_i: Int {
        return Int(value.tv_sec)
    }

    open var to_r: Rational? {
        return nil////
    }

    open var to_s: String {
        return inspect
    }

    open var tuesday: Bool {
        return settm().tm_wday == 2
    }

    open var tv_nsec: Int {
        return Int(value.tv_usec) * 1_000
    }

    open var tv_sec: Int {
        return Int(value.tv_sec)
    }

    open var tv_usec: Int {
        return Int(value.tv_usec)
    }

    open var usec: Int {
        return tv_usec
    }

    open var utc: Time {
        return gmtime
    }

    open func utc( _ utc_offset: Int ) -> Time? {
        return nil///
    }

    open var utc_offset: fixnum {
        return gmt_offset
    }

    open var wday: fixnum {
        return Int(settm().tm_wday)
    }

    open var wednesday: Bool {
        return settm().tm_wday == 3
    }

    open var yday: fixnum {
        return Int(settm().tm_yday)
    }

    open var year: Int {
        return Int(settm().tm_yday)
    }

    open var zone: String {
        return String( validatingUTF8: settm().tm_zone )!
    }

}
