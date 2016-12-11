//
//  SwiftRubyTests.swift
//  SwiftRubyTests
//
//  Created by John Holdsworth on 30/09/2015.
//  Copyright © 2015 John Holdsworth. All rights reserved.
//
//  $Id: //depot/SwiftRuby/SwiftRubyTests/SwiftRubyTests.swift#14 $
//
//  Repo: https://github.com/RubyNative/SwiftRuby
//

import XCTest
@testable import SwiftRuby

class RubyNativeTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testKit() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.

        XCTAssertEqual( "€".to_d.to_s.ord.chr, "€", "basic unicode" )

        let invalid =  "/tmp/tmp/tmp"
        XCTAssertFalse( Dir.mkdir( invalid ), "failed create directory " )
        XCTAssertFalse( FileUtils.mkdir( invalid ), "failed create directory " )

        let testdir = "/tmp/rktest"
        XCTAssert( FileUtils.rm_rf( testdir ), "reset test directory" )
        XCTAssert( Dir.mkdir( testdir ), "recreate test driectory" )
        XCTAssert( Dir.chdir( testdir ), "chdir test directory" )

        let string1 = "🇩🇪🇺🇸🇫🇷🇮🇹🇬🇧\n🇪🇸🇯🇵🇷🇺🇨🇳\n"
        XCTAssertEqual( File.write( "same1.txt", string1 ), string1.utf8.count, "write same1" )

        let string2 = StringIO( "🇩🇪🇺🇸🇫🇷🇮🇹🇬🇧\n" )
        string2.write( "🇪🇸🇯🇵🇷🇺🇨🇳\n" )

        XCTAssertEqual( File.write( "same2.txt", string2 ), string2.data.length, "write same2" )

        XCTAssertEqual( File.open( "same1.txt" )!.to_a, ["🇩🇪🇺🇸🇫🇷🇮🇹🇬🇧", "🇪🇸🇯🇵🇷🇺🇨🇳"], "readlines file" )

        string2.rewind()
        XCTAssertEqual( string2.to_a, ["🇩🇪🇺🇸🇫🇷🇮🇹🇬🇧", "🇪🇸🇯🇵🇷🇺🇨🇳"], "readlines stringIO" )

        if let file = File.open( "diff1.txt", "w" ) {
            file.write( string2 )
            file.write( string2 )
        }

        let refernce = "€ Unicode String €"
        var string3 = ""
        StringIO( refernce ).each_char {
            (char) in
            string3 += Int(char).chr
        }

        XCTAssertEqual( string3, refernce, "char block" )

        XCTAssertTrue( FileUtils.compare_file( "same1.txt", "same2.txt" ), "basic same" )
        XCTAssertFalse( FileUtils.compare_file( "same1.txt", "diff1.txt" ), "basic diff" )

        XCTAssertTrue( FileUtils.compare_stream( File.open( "same1.txt" )!, File.open( "same2.txt" )! ), "stream compare" )
        XCTAssertFalse( FileUtils.compare_stream( File.open( "same1.txt" )!, File.open( "diff1.txt" )! ), "stream diff" )

        XCTAssert( fabs( Time().to_f - File.mtime( "diff1.txt" )!.to_f ) <= 5.0, "modification time" )

        let largeFile = "/Applications/Xcode.app/Contents/Frameworks/IDEKit.framework/IDEKit"
        XCTAssert( File.open( largeFile )!.read()! == IO.popen( "cat \(largeFile)" )!.read()!, "large file" )

        WARNING_DISPOSITION = .ignore
        for mode in [0o700, 0o070, 0o007, 0o000] {
            File.chmod( mode, "diff1.txt" )
            XCTAssertEqual( File.open( "diff1.txt", "r" ) != nil, File.readable( "diff1.txt" ), "permission \(mode)" )
        }

        let files = ["diff1.txt", "same1.txt", "same2.txt"]
        XCTAssertEqual( Dir.glob( "*.txt", testdir )!.sorted(), files, "glob directory" )
        XCTAssertEqual( Dir.open( "." )!.to_a.sorted(), [".", ".."]+files, "read directory" )
        XCTAssertEqual( Kernel.open( "| ls \(testdir)" )!.to_a, files, "read popen" )

        XCTAssertEqual("🇩🇪🇺🇸\n🇩🇪🇺🇸\n"["^(..)🇺🇸", .anchorsMatchLines]["$1🇪🇸"], "🇩🇪🇪🇸\n🇩🇪🇪🇸\n", "unicode replace")
        XCTAssertEqual("🇩🇪🇺🇸\n🇩🇪🇺🇸\n"["^(.*)🇺🇸", "m"]["$1🇪🇸"], "🇩🇪🇪🇸\n🇩🇪🇪🇸\n", "unicode replace")

        XCTAssertEqual("🇩🇪a🇺🇸a🇫🇷a🇮🇹a🇬🇧"[2], "🇺🇸", "basic subscript")
        XCTAssertEqual("🇩🇪a🇺🇸a🇫🇷a🇮🇹a🇬🇧"[2, 3], "🇺🇸a🇫🇷", "simple subscript")
        XCTAssertEqual("🇩🇪a🇺🇸a🇫🇷a🇮🇹a🇬🇧"[2..<7], "🇺🇸a🇫🇷a🇮🇹", "range subscript")

        XCTAssertEqual("🇩🇪a🇺🇸a🇫🇷a🇮🇹a🇬🇧".sub("a", "b"), "🇩🇪b🇺🇸a🇫🇷a🇮🇹a🇬🇧", "single replace")
        XCTAssertEqual("🇩🇪a🇺🇸a🇫🇷a🇮🇹a🇬🇧"["🇺🇸(.)"][1], "a", "regexp group")
        XCTAssertEqual("   abc   ".index( "abc" ), 3, "index")
        XCTAssertEqual("   abc   ".strip, "abc", "strip")

        XCTAssertEqual("🇩🇪a🇺🇸a🇫🇷a🇮🇹a🇬🇧"[-1], "🇬🇧", "-ve subscript")
        XCTAssertEqual("🇩🇪a🇺🇸a🇫🇷a🇮🇹a🇬🇧"[-3, -1], "🇮🇹a", "two -ve subscript")
        XCTAssertEqual("🇩🇪a🇺🇸a🇫🇷a🇮🇹a🇬🇧"[-5, NSNotFound], "🇫🇷a🇮🇹a🇬🇧", "-ve to end")

        WARNING_DISPOSITION = .warn
        STRING_INDEX_DISPOSITION = .truncate

        XCTAssertEqual("🇩🇪a🇺🇸a🇫🇷a🇮🇹a🇬🇧"[0, 20], "🇩🇪a🇺🇸a🇫🇷a🇮🇹a🇬🇧", "start + len")
        XCTAssertEqual("🇩🇪a🇺🇸a🇫🇷a🇮🇹a🇬🇧"[-20, -1], "🇩🇪a🇺🇸a🇫🇷a🇮🇹a", "start < front")
        XCTAssertEqual("🇩🇪a🇺🇸a🇫🇷a🇮🇹a🇬🇧"[-2, 20], "a🇬🇧", "start + end > back")
        XCTAssertEqual("🇩🇪a🇺🇸a🇫🇷a🇮🇹a🇬🇧"[-2, -20], "", "end < start")
        XCTAssertEqual("🇩🇪a🇺🇸a🇫🇷a🇮🇹a🇬🇧"[20, 0], "", "start > back")

        let testPath = "/a/b/c.d"
        XCTAssertEqual( File.dirname( testPath ), "/a/b", "dirname" )
        XCTAssertEqual( File.basename( testPath ), "c.d", "basename" )
        XCTAssertEqual( File.extname( testPath ), "d", "extname" )
        XCTAssertEqual( File.extremoved( testPath ), "/a/b/c", "removeext" )

        XCTAssertEqual( Dir.home(), ENV["HOME"], "home directory" )
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
    
}
