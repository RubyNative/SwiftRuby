//
//  Regex.swift
//  SwiftRuby
//
//  Created by John Holdsworth on 26/09/2015.
//  Copyright © 2015 John Holdsworth. All rights reserved.
//
//  $Id: //depot/SwiftRuby/Regexp.swift#12 $
//
//  Repo: https://github.com/RubyNative/SwiftRuby
//
//  See: http://ruby-doc.org/core-2.2.3/Regexp.html
//

import Foundation

infix operator =~ : ComparisonPrecedence

public func =~ (lhs: String, rhs: String) -> Regexp {
    return Regexp(target: lhs as NSString, pattern: rhs)
}

infix operator !~ : ComparisonPrecedence

public func !~ (lhs: String, rhs: String) -> NotRegexp {
    return NotRegexp(target: lhs as NSString, pattern: rhs)
}

extension String {

    public subscript (pattern: String) -> Regexp {
        return Regexp(target: self as NSString, pattern: pattern)
    }

    public subscript (pattern: String, options: NSRegularExpression.Options) -> Regexp {
        return Regexp(target: self as NSString, pattern: pattern, options: options)
    }

    public subscript (pattern: String, optionString: String) -> Regexp {
        return Regexp(target: self as NSString, pattern: pattern, optionString: optionString)
    }

    public subscript (pattern: String, capture: Int) -> String? {
        return slice(pattern, capture)
    }

    public var mutableString: NSMutableString {
        return NSMutableString(string: self)
    }

    public func gsub(_ pattern: String, _ template: String) -> String {
        let out = self.mutableString
        _ = out[pattern] =~ template
        return out as String
    }

    public func index(_ pattern: String) -> Int? {
        let range = Regexp(target: self as NSString, pattern: pattern).range()
        return range.location != NSNotFound ? range.location : nil
    }

    public var lstrip: String {
        return self["^\\s+"][""]
    }

    public func match(_ pattern: String) -> [String?]? {
        return Regexp(target: self as NSString, pattern: pattern).groups()
    }

    public var rstrip: String {
        return self["\\s*+"][""]
    }

    public func slice(_ pattern: String, _ capture: Int = 0) -> String? {
        return Regexp(target: self as NSString, pattern: pattern)[capture]
    }

    public func scan(_ pattern: String) -> [[String?]] {
        return Regexp(target: self as NSString, pattern: pattern).allGroups()
    }

    public var strip: String {
        return self["^\\s+|\\s+$"][""]
    }

    public func sub(_ pattern: String, _ template: String) -> String {
        let out = self.mutableString
        _ = out[pattern] =~ [template]
        return out as String
    }

}

extension NSMutableString {

    public subscript (pattern: String) -> MutableRegexp {
        return MutableRegexp(target: self, pattern: pattern)
    }

    public subscript (pattern: String, options: NSRegularExpression.Options) -> MutableRegexp {
        return MutableRegexp(target: self, pattern: pattern, options: options)
    }

    public subscript (pattern: String, optionString: String) -> MutableRegexp {
        return MutableRegexp(target: self, pattern: pattern, optionString: optionString)
    }
    
}

open class Regexp: RubyObject {

    let target: NSString
    let regexp: NSRegularExpression
    var file: RegexpFile?

    public convenience init(target: NSString, pattern: String, optionString: String) {
        var options: UInt = 0
        for char in optionString {
            switch char {
            case "i":
                options |= NSRegularExpression.Options.caseInsensitive.rawValue
            case "x":
                options |= NSRegularExpression.Options.allowCommentsAndWhitespace.rawValue
            case "q":
                options |= NSRegularExpression.Options.ignoreMetacharacters.rawValue
            case "m":
                options |= NSRegularExpression.Options.anchorsMatchLines.rawValue
            case "s":
                options |= NSRegularExpression.Options.dotMatchesLineSeparators.rawValue
            case "l":
                options |= NSRegularExpression.Options.useUnixLineSeparators.rawValue
            case "u":
                options |= NSRegularExpression.Options.useUnicodeWordBoundaries.rawValue
            default:
                SRLog("Invalid Regexp option \(char)")
                break
            }
        }
        self.init(target: target, pattern: pattern, options: NSRegularExpression.Options(rawValue: options ))
    }

    public init(target: NSString, pattern: String,
                options: NSRegularExpression.Options = NSRegularExpression.Options(rawValue: 0 )) {
        self.target = target
        do {
            self.regexp = try NSRegularExpression(pattern: pattern, options: options)
        }
        catch let error as NSError {
            SRLog("Regexp pattern: '\(pattern)' compile error: \(error)")
            self.regexp = NSRegularExpression()
        }
    }

    final var targetRange: NSRange {
        return NSMakeRange(0, target.length)
    }

    final func substring(_ range: NSRange) -> String? {
        if (range.location != NSNotFound) {
            return target.substring(with: range)
        } else {
            return nil
        }
    }

    open func doesMatch(_ options: NSRegularExpression.MatchingOptions? = nil) -> Bool {
        return range(options).location != NSNotFound
    }

    open func range(_ options: NSRegularExpression.MatchingOptions? = nil) -> NSRange {
        return regexp.rangeOfFirstMatch(in: target as String, options: options ?? NSRegularExpression.MatchingOptions(rawValue: 0), range: targetRange)
    }

    func matchResults(_ options: NSRegularExpression.MatchingOptions? = nil) -> [NSTextCheckingResult] {
        return regexp.matches(in: target as String, options: options ?? NSRegularExpression.MatchingOptions(rawValue: 0), range: targetRange)
    }

    func replaceWith(_ template: String, options: NSRegularExpression.MatchingOptions? = nil) -> NSMutableString {
        let mutable = /*target as? NSMutableString ??*/ NSMutableString(string: target)
        regexp.replaceMatches(in: mutable, options: options ?? NSRegularExpression.MatchingOptions(rawValue: 0), range: targetRange, withTemplate: template)
        return mutable
    }
    
    func groupsForMatch(_ match: NSTextCheckingResult) -> [String?] {
        var groups = [String?]()
        for groupno in 0...regexp.numberOfCaptureGroups {
            groups.append(substring(match.range(at: groupno) ))
        }
        return groups
    }

    open func dictionary(_ options: NSRegularExpression.MatchingOptions? = nil) -> [String:String] {
        var out = [String:String]()
        for match in matchResults(options) {
            out[substring(match.range(at: 1))!] =
                substring(match.range(at: 2))!
        }
        return out
    }

    open func match(_ options: NSRegularExpression.MatchingOptions? = nil) -> String? {
        return substring(range(options ))
    }

    open func groups(_ options: NSRegularExpression.MatchingOptions? = nil) -> [String?]? {
        if let match = regexp.firstMatch(in: target as String, options: options ?? NSRegularExpression.MatchingOptions(rawValue: 0), range: targetRange) {
            return groupsForMatch(match)
        }
        return nil
    }

    open func allGroups(_ options: NSRegularExpression.MatchingOptions? = nil) -> [[String?]] {
        return matchResults(options).map { self.groupsForMatch($0) }
    }

    open subscript (groupno: Int) -> String? {
        if let match = regexp.firstMatch(in: target as String, options: NSRegularExpression.MatchingOptions(rawValue: 0), range: targetRange) {
            return substring(match.range(at: groupno ))
        }
        return nil
    }

    open subscript (groupno: Int, options: NSRegularExpression.MatchingOptions) -> String? {
        if let match = regexp.firstMatch(in: target as String, options: options, range: targetRange) {
            return substring(match.range(at: groupno ))
        }
        return nil
    }

    open subscript(template: String) -> String {
        return replaceWith(template) as String
    }

    open subscript(template: String, options: NSRegularExpression.MatchingOptions) -> String {
        return replaceWith(template, options: options) as String
    }

    open var boolValue: Bool {
        return doesMatch()
    }

}

open class NotRegexp : Regexp {

    open override var boolValue: Bool {
        return !doesMatch()
    }

}

open class MutableRegexp: Regexp {

    override open subscript (groupno: Int) -> String? {
        get {
            if let match = regexp.firstMatch(in: target as String, options: NSRegularExpression.MatchingOptions(rawValue: 0), range: targetRange) {
                return substring(match.range(at: groupno ))
            }
            return nil
        }
        set(newValue) {
            if let newValue = newValue {
                if let mutableTarget = target as? NSMutableString {
                    for match in Array(matchResults().reversed()) {
                        let replacement = regexp.replacementString(for: match,
                            in: target as String, offset: 0, template: newValue)
                        mutableTarget.replaceCharacters(in: match.range(at: groupno), with: replacement)
                    }
                } else {
                    SRLog("Group modify on non-mutable")
                }
            }
            else {
                SRLog("nil replacement in group modify")
            }

        }
    }

    func substituteMatches(_ substitution: (NSTextCheckingResult, UnsafeMutablePointer<ObjCBool>) -> String) -> Bool {
        let out = NSMutableString()
        var pos = 0

        regexp.enumerateMatches(in: target as String, options: NSRegularExpression.MatchingOptions(rawValue: 0), range: targetRange) {
            (match: NSTextCheckingResult?, flags: NSRegularExpression.MatchingFlags, stop: UnsafeMutablePointer<ObjCBool>) in

            let matchRange = match!.range
            out.append(self.substring(NSMakeRange(pos, matchRange.location-pos ))!) ////
            out.append(substitution(match!, stop ))
            pos = matchRange.location + matchRange.length
        }

        out.append(substring(NSMakeRange(pos, targetRange.length-pos ))!) ////

        if let mutableTarget = target as? NSMutableString {
            if out != target {
                mutableTarget.setString(out as String)
                return true
            }
        } else {
            SRLog("Modify substitute on non-mutable")
        }
        return false
    }
    
}

public func =~ (left: MutableRegexp, right: String) -> Bool {
    return left.substituteMatches({
        (match: NSTextCheckingResult, stop: UnsafeMutablePointer<ObjCBool>) in
        return left.regexp.replacementString(for: match,
            in: left.target as String, offset: 0, template: right)
    })
}

public func =~ (left: MutableRegexp, right: [String]) -> Bool {
    var matchNumber = 0
    return left.substituteMatches({
        (match: NSTextCheckingResult, stop: UnsafeMutablePointer<ObjCBool>) in

        matchNumber += 1
        if matchNumber == right.count {
            stop.pointee = true
        }

        return left.regexp.replacementString(for: match,
            in: left.target as String, offset: 0, template: right[matchNumber-1])
    })
}

public func =~ (left: MutableRegexp, right: (String?) -> String) -> Bool {
    return left.substituteMatches({
        (match: NSTextCheckingResult, stop: UnsafeMutablePointer<ObjCBool>) in
        return right(left.substring(match.range ))
    })
}

public func =~ (left: MutableRegexp, right: ([String?]) -> String) -> Bool {
    return left.substituteMatches({
        (match: NSTextCheckingResult, stop: UnsafeMutablePointer<ObjCBool>) in
        return right(left.groupsForMatch(match ))
    })
}

open class RegexpFile {

    let filepath: String
    let contents: NSMutableString! ////
    let original: String!

    public init?(_ path: String, file: StaticString = #file, line: UInt = #line) {
        filepath = path
        contents = File.read(path)?.to_s.mutableString
        original = contents as String
        if contents == nil {
            SRError("RegexpFile could not read '\(path)'", file: file, line: line)
            return nil
        }
    }

    open subscript(pattern: String) -> MutableRegexp {
        let regexp = MutableRegexp(target: contents, pattern: pattern)
        regexp.file = self // retains until after substitution
        return regexp
    }

    open subscript (pattern: String, options: NSRegularExpression.Options) -> MutableRegexp {
        let regexp = MutableRegexp(target: contents, pattern: pattern, options: options)
        regexp.file = self // retains until after substitution
        return regexp
    }

    open subscript (pattern: String, options: String) -> MutableRegexp {
        let regexp = MutableRegexp(target: contents, pattern: pattern, optionString: options)
        regexp.file = self // retains until after substitution
        return regexp
    }

    deinit {
        if contents as String != original {
            File.write(filepath, contents as String)
        }
    }
    
}
