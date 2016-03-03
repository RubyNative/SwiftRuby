//
//  Regex.swift
//  SwiftRuby
//
//  Created by John Holdsworth on 26/09/2015.
//  Copyright © 2015 John Holdsworth. All rights reserved.
//
//  $Id: //depot/SwiftRuby/Regexp.swift#8 $
//
//  Repo: https://github.com/RubyNative/SwiftRuby
//
//  See: http://ruby-doc.org/core-2.2.3/Regexp.html
//

import Foundation

infix operator =~ { associativity left precedence 135 }

public func =~ ( lhs: String, rhs: String ) -> Regexp {
    return Regexp( target: lhs, pattern: rhs )
}

infix operator !~ { associativity left precedence 135 }

public func !~ ( lhs: String, rhs: String ) -> NotRegexp {
    return NotRegexp( target: lhs, pattern: rhs )
}

extension String {

    public subscript ( pattern: String ) -> Regexp {
        return Regexp( target: self, pattern: pattern )
    }

    public subscript ( pattern: String, options: NSRegularExpressionOptions ) -> Regexp {
        return Regexp( target: self, pattern: pattern, options: options )
    }

    public subscript ( pattern: String, optionString: String ) -> Regexp {
        return Regexp( target: self, pattern: pattern, optionString: optionString )
    }

    public subscript ( pattern: String, capture: Int ) -> String? {
        return slice( pattern, capture )
    }

    public var mutableString: NSMutableString {
        return NSMutableString( string: self )
    }

    public func gsub( pattern: String, _ template: String ) -> String {
        let out = self.mutableString
        out[pattern] =~ template
        return out as String
    }

    public func index( pattern: String ) -> Int? {
        let range = Regexp( target: self, pattern: pattern ).range()
        return range.location != NSNotFound ? range.location : nil
    }

    public var lstrip: String {
        return self["^\\s+"][""]
    }

    public func match( pattern: String ) -> [String?]? {
        return Regexp( target: self, pattern: pattern ).groups()
    }

    public var rstrip: String {
        return self["\\s*+"][""]
    }

    public func slice( pattern: String, _ capture: Int = 0 ) -> String? {
        return Regexp( target: self, pattern: pattern )[capture]
    }

    public func scan( pattern: String ) -> [[String?]] {
        return Regexp( target: self, pattern: pattern ).allGroups()
    }

    public var strip: String {
        return self["^\\s+|\\s+$"][""]
    }

    public func sub( pattern: String, _ template: String ) -> String {
        let out = self.mutableString
        out[pattern] =~ [template]
        return out as String
    }

}

extension NSMutableString {

    public subscript ( pattern: String ) -> MutableRegexp {
        return MutableRegexp( target: self, pattern: pattern )
    }

    public subscript ( pattern: String, options: NSRegularExpressionOptions ) -> MutableRegexp {
        return MutableRegexp( target: self, pattern: pattern, options: options )
    }

    public subscript ( pattern: String, optionString: String ) -> MutableRegexp {
        return MutableRegexp( target: self, pattern: pattern, optionString: optionString )
    }
    
}

public class Regexp: RubyObject, BooleanType {

    let target: NSString
    let regexp: NSRegularExpression
    var file: RegexpFile?

    public convenience init( target: NSString, pattern: String, optionString: String ) {
        var options: UInt = 0
        for char in optionString.characters {
            switch char {
            case "i":
                options |= NSRegularExpressionOptions.CaseInsensitive.rawValue
            case "x":
                options |= NSRegularExpressionOptions.AllowCommentsAndWhitespace.rawValue
            case "q":
                options |= NSRegularExpressionOptions.IgnoreMetacharacters.rawValue
            case "m":
                options |= NSRegularExpressionOptions.AnchorsMatchLines.rawValue
            case "s":
                options |= NSRegularExpressionOptions.DotMatchesLineSeparators.rawValue
            case "l":
                options |= NSRegularExpressionOptions.UseUnixLineSeparators.rawValue
            case "u":
                options |= NSRegularExpressionOptions.UseUnicodeWordBoundaries.rawValue
            default:
                SRLog( "Invalid Regexp option \(char)" )
                break
            }
        }
        self.init( target: target, pattern: pattern, options: NSRegularExpressionOptions( rawValue: options ) )
    }

    public init( target: NSString, pattern: String,
                options: NSRegularExpressionOptions = NSRegularExpressionOptions( rawValue: 0 ) ) {
        self.target = target
        do {
            self.regexp = try NSRegularExpression( pattern: pattern, options: options )
        }
        catch let error as NSError {
            SRLog( "Regexp pattern: '\(pattern)' compile error: \(error)" )
            self.regexp = NSRegularExpression()
        }
    }

    final var targetRange: NSRange {
        return NSMakeRange( 0, target.length )
    }

    final func substring( range: NSRange ) -> String? {
        if ( range.location != NSNotFound ) {
            return target.substringWithRange( range )
        } else {
            return nil
        }
    }

    public func doesMatch( options: NSMatchingOptions? = nil ) -> Bool {
        return range( options ).location != NSNotFound
    }

    public func range( options: NSMatchingOptions? = nil ) -> NSRange {
        return regexp.rangeOfFirstMatchInString( target as String, options: options ?? NSMatchingOptions(rawValue: 0), range: targetRange )
    }

    func matchResults( options: NSMatchingOptions? = nil ) -> [NSTextCheckingResult] {
        return regexp.matchesInString( target as String, options: options ?? NSMatchingOptions(rawValue: 0), range: targetRange )
    }

    func replaceWith( template: String, options: NSMatchingOptions? = nil ) -> NSMutableString {
        let mutable = /*target as? NSMutableString ??*/ NSMutableString( string: target )
        regexp.replaceMatchesInString( mutable, options: options ?? NSMatchingOptions(rawValue: 0), range: targetRange, withTemplate: template )
        return mutable
    }
    
    func groupsForMatch( match: NSTextCheckingResult ) -> [String?] {
        var groups = [String?]()
        for groupno in 0...regexp.numberOfCaptureGroups {
            groups.append( substring( match.rangeAtIndex( groupno ) ) )
        }
        return groups
    }

    public func dictionary( options: NSMatchingOptions? = nil ) -> [String:String] {
        var out = [String:String]()
        for match in matchResults(options) {
            out[substring(match.rangeAtIndex(1))!] =
                substring(match.rangeAtIndex(2))!
        }
        return out
    }

    public func match( options: NSMatchingOptions? = nil ) -> String? {
        return substring( range( options ) )
    }

    public func groups( options: NSMatchingOptions? = nil ) -> [String?]? {
        if let match = regexp.firstMatchInString(target as String, options: options ?? NSMatchingOptions(rawValue: 0), range: targetRange ) {
            return groupsForMatch( match )
        }
        return nil
    }

    public func allGroups( options: NSMatchingOptions? = nil ) -> [[String?]] {
        return matchResults( options ).map { self.groupsForMatch( $0 ) }
    }

    public subscript ( groupno: Int ) -> String? {
        if let match = regexp.firstMatchInString( target as String, options: NSMatchingOptions(rawValue: 0), range: targetRange ) {
            return substring( match.rangeAtIndex( groupno ) )
        }
        return nil
    }

    public subscript ( groupno: Int, options: NSMatchingOptions ) -> String? {
        if let match = regexp.firstMatchInString( target as String, options: options, range: targetRange ) {
            return substring( match.rangeAtIndex( groupno ) )
        }
        return nil
    }

    public subscript( template: String ) -> String {
        return replaceWith( template ) as String
    }

    public subscript( template: String, options: NSMatchingOptions ) -> String {
        return replaceWith( template, options: options ) as String
    }

    public var boolValue: Bool {
        return doesMatch()
    }

}

public class NotRegexp : Regexp {

    public override var boolValue: Bool {
        return !doesMatch()
    }

}

public class MutableRegexp: Regexp {

    override public subscript ( groupno: Int ) -> String? {
        get {
            if let match = regexp.firstMatchInString( target as String, options: NSMatchingOptions(rawValue: 0), range: targetRange ) {
                return substring( match.rangeAtIndex( groupno ) )
            }
            return nil
        }
        set( newValue ) {
            if let newValue = newValue {
                if let mutableTarget = target as? NSMutableString {
                    for match in Array(matchResults().reverse()) {
                        let replacement = regexp.replacementStringForResult( match,
                            inString: target as String, offset: 0, template: newValue )
                        mutableTarget.replaceCharactersInRange( match.rangeAtIndex(groupno), withString: replacement )
                    }
                } else {
                    SRLog( "Group modify on non-mutable" )
                }
            }
            else {
                SRLog( "nil replacement in group modify" )
            }

        }
    }

    func substituteMatches( substitution: (NSTextCheckingResult, UnsafeMutablePointer<ObjCBool>) -> String ) -> Bool {
        let out = NSMutableString()
        var pos = 0

        regexp.enumerateMatchesInString( target as String, options: NSMatchingOptions(rawValue: 0), range: targetRange ) {
            (match: NSTextCheckingResult?, flags: NSMatchingFlags, stop: UnsafeMutablePointer<ObjCBool>) in

            let matchRange = match!.range
            out.appendString( self.substring( NSMakeRange( pos, matchRange.location-pos ) )! ) ////
            out.appendString( substitution( match!, stop ) )
            pos = matchRange.location + matchRange.length
        }

        out.appendString( substring( NSMakeRange( pos, targetRange.length-pos ) )! ) ////

        if let mutableTarget = target as? NSMutableString {
            if out != target {
                mutableTarget.setString( out as String )
                return true
            }
        } else {
            SRLog( "Modify substitute on non-mutable" )
        }
        return false
    }
    
}

public func =~ ( left: MutableRegexp, right: String ) -> Bool {
    return left.substituteMatches( {
        (match: NSTextCheckingResult, stop: UnsafeMutablePointer<ObjCBool>) in
        return left.regexp.replacementStringForResult( match,
            inString: left.target as String, offset: 0, template: right )
    } )
}

public func =~ ( left: MutableRegexp, right: [String] ) -> Bool {
    var matchNumber = 0
    return left.substituteMatches( {
        (match: NSTextCheckingResult, stop: UnsafeMutablePointer<ObjCBool>) in

        matchNumber += 1
        if matchNumber == right.count {
            stop.memory = true
        }

        return left.regexp.replacementStringForResult( match,
            inString: left.target as String, offset: 0, template: right[matchNumber-1] )
    } )
}

public func =~ ( left: MutableRegexp, right: (String?) -> String ) -> Bool {
    return left.substituteMatches( {
        (match: NSTextCheckingResult, stop: UnsafeMutablePointer<ObjCBool>) in
        return right( left.substring( match.range ) )
    } )
}

public func =~ ( left: MutableRegexp, right: ([String?]) -> String ) -> Bool {
    return left.substituteMatches( {
        (match: NSTextCheckingResult, stop: UnsafeMutablePointer<ObjCBool>) in
        return right( left.groupsForMatch( match ) )
    } )
}

public class RegexpFile {

    let filepath: String
    let contents: NSMutableString! ////
    let original: String!

    public init?( _ path: String, file: StaticString = __FILE__, line: UInt = __LINE__ ) {
        filepath = path
        contents = File.read( path )?.to_s.mutableString
        original = contents as String
        if contents == nil {
            SRError( "RegexpFile could not read '\(path)'", file: file, line: line )
            return nil
        }
    }

    public subscript( pattern: String ) -> MutableRegexp {
        let regexp = MutableRegexp( target: contents, pattern: pattern )
        regexp.file = self // retains until after substitution
        return regexp
    }

    public subscript ( pattern: String, options: NSRegularExpressionOptions ) -> MutableRegexp {
        let regexp = MutableRegexp( target: contents, pattern: pattern, options: options )
        regexp.file = self // retains until after substitution
        return regexp
    }

    public subscript ( pattern: String, options: String ) -> MutableRegexp {
        let regexp = MutableRegexp( target: contents, pattern: pattern, optionString: options )
        regexp.file = self // retains until after substitution
        return regexp
    }

    deinit {
        if contents != original {
            File.write( filepath, contents as String )
        }
    }
    
}
