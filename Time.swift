//
//  Time.swift
//  SwiftRuby
//
//  Created by John Holdsworth on 26/09/2015.
//  Copyright © 2015 John Holdsworth. All rights reserved.
//
//  $Id: //depot/SwiftRuby/Time.swift#8 $
//
//  Repo: https://github.com/RubyNative/SwiftRuby
//
//  See: http://ruby-doc.org/core-2.2.3/Time.html
//

import Darwin

public class Time : RubyObject, to_s_protocol {

    public var value = timeval()
    public var tzone = timezone()
    public var tmout: tm?

    public var isUTC = false {
        didSet {
            tmout =  nil
        }
    }

    public class func now() -> Time {
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

    public class func at( time: Time ) -> Time {
        return Time( seconds: Int(time.value.tv_sec), usec: Int(time.value.tv_usec) )
    }

    public class func at( time_f: to_f_protocol ) -> Time {
        return Time( time_f: time_f.to_f )
    }

    public class func at( time: Int, usec: Double = 0 ) -> Time {
        return Time( seconds: time, usec: Int(usec.to_f) )
    }

    public class func at( time: to_s_protocol, format: to_s_protocol = "%Y-%m-%d %H:%M:%S %z" ) -> Time {
        return strptime( time, format: format )
    }

    public class func strptime( time: to_s_protocol, format: to_s_protocol ) -> Time {
        var mktm = tm()
        Darwin.strptime( time.to_s, format.to_s, &mktm )
        return Time( seconds: mktime( &mktm ) )
    }

    public class func local( year: Int = 0, month: Int = 0, day: Int = 0,
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

    public var asctime: String {
        var out = [CChar]( count: 30, repeatedValue: 0 )
        var tmp = settm()
        asctime_r( &tmp, &out )
        return String( UTF8String: out )!
    }

    public var ctime: String {
        return asctime
    }

    public var day: Int {
        return Int(settm().tm_mday)
    }

    public var dst: Bool {
        return settm().tm_isdst != 0
    }

    public func eql( other_time: Time ) -> Bool {
        return value.tv_sec == other_time.value.tv_sec && value.tv_usec == other_time.value.tv_usec
    }

    public var friday: Bool {
        return settm().tm_wday == 5
    }

    public var getgm: Time {
        let gm = Time.at( self )
        gm.isUTC = true
        return gm
    }

    public var getlocal: Time {
        let gm = Time.at( self )
        gm.isUTC = false
        return gm
    }

    public func getlocal( utc_offset: Int ) -> Time? {
        return nil////
    }

    public var getutc: Time {
        return getgm
    }

    public var gmt: Bool {
        return isUTC
    }

    public var gmt_offset: Int {
        return isUTC ? 0 : settm().tm_gmtoff
    }

    public var gmtime: Time {
        isUTC = true
        return self
    }

    public var gmtoff: Int {
        return gmt_offset
    }

    public var hour: Int {
        return Int(settm().tm_hour)
    }

    public var inspect: String {
        return self.strftime( isUTC ? "%Y-%m-%d %H:%M:%S UTC" : "%Y-%m-%d %H:%M:%S %z" )
    }

    public var isdst: Bool {
        return settm().tm_isdst != 0
    }

    public var localtime: Time {
        return getlocal
    }

    public func localtime( utc_offset: Int ) -> Time? {
        return nil////
    }

    public var mday: fixnum {
        return Int(settm().tm_mday)
    }

    public var min: fixnum {
        return Int(settm().tm_min)
    }

    public var mon: fixnum {
        return Int(settm().tm_mon)+1
    }

    public var month: fixnum {
        return Int(settm().tm_mon)
    }

    public var monday: Bool {
        return settm().tm_wday == 1
    }

    public var nsec: Int {
        return Int(value.tv_usec) * 1_000
    }

    public func round( ndigits: Int ) -> Time {
        let divisor = pow( 10.0, Double(ndigits.to_i) )
        return Time( time_f: Darwin.round(self.to_f * divisor) / divisor )
    }

    public var saturday: Bool {
        return settm().tm_wday == 6
    }

    public var sec: fixnum {
        return Int(settm().tm_sec)
    }

    public func strftime( format: to_s_protocol ) -> String {
        var out = [Int8]( count: 1000, repeatedValue: 0 )
        var tmp = settm()
        Darwin.strftime( &out, out.count, format.to_s,  &tmp )
        return String( UTF8String: out )!
    }

    public var succ: Time {
        return Time( seconds: value.tv_sec+1, usec: Int(value.tv_usec) )
    }

    public var sunday: Bool {
        return settm().tm_wday == 0
    }

    public var thursday: Bool {
        return settm().tm_wday == 4
    }

    public var to_a: [String] {
        let tmp = settm()
        return [String(tmp.tm_sec), String(tmp.tm_min), String(tmp.tm_hour), String(tmp.tm_mday), String(tmp.tm_mon),
            String(tmp.tm_year), String(tmp.tm_wday), String(tmp.tm_yday), String(tmp.tm_isdst), String(tmp.tm_zone)]
    }

    public var to_f: Double {
        return Double(value.tv_sec) + Double(value.tv_usec)/1_000_000
    }

    public var to_i: Int {
        return Int(value.tv_sec)
    }

    public var to_r: Rational? {
        return nil////
    }

    public var to_s: String {
        return inspect
    }

    public var tuesday: Bool {
        return settm().tm_wday == 2
    }

    public var tv_nsec: Int {
        return Int(value.tv_usec) * 1_000
    }

    public var tv_sec: Int {
        return Int(value.tv_sec)
    }

    public var tv_usec: Int {
        return Int(value.tv_usec)
    }

    public var usec: Int {
        return tv_usec
    }

    public var utc: Time {
        return gmtime
    }

    public func utc( utc_offset: Int ) -> Time? {
        return nil///
    }

    public var utc_offset: fixnum {
        return gmt_offset
    }

    public var wday: fixnum {
        return Int(settm().tm_wday)
    }

    public var wednesday: Bool {
        return settm().tm_wday == 3
    }

    public var yday: fixnum {
        return Int(settm().tm_yday)
    }

    public var year: Int {
        return Int(settm().tm_yday)
    }

    public var zone: String {
        return String( UTF8String: settm().tm_zone )!
    }

}
