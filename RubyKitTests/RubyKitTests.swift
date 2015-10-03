//
//  RubyNativeTests.swift
//  RubyNativeTests
//
//  Created by John Holdsworth on 30/09/2015.
//  Copyright © 2015 John Holdsworth. All rights reserved.
//
//  $Id: //depot/RubyKit/RubyKitTests/RubyKitTests.swift#6 $
//
//  Repo: https://github.com/RubyNative/RubyKit
//

import XCTest
import RubyKit

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

        let invalid =  "/xx/xx"
        XCTAssertFalse( Dir.mkdir( invalid ), "failed create directory " )
        XCTAssertFalse( FileUtils.mkdir( invalid ), "failed create directory " )

        let testdir = "/tmp/rktest"
        XCTAssert( FileUtils.rm_rf( testdir ), "reset test directory" )
        XCTAssert( Dir.mkdir( testdir ), "recreate test driectory" )
        XCTAssert( Dir.chdir( testdir ), "chdir test directory" )

        let string1 = "🇩🇪🇺🇸🇫🇷🇮🇹🇬🇧\n🇪🇸🇯🇵🇷🇺🇨🇳\n"
        XCTAssert( File.write( "same1.txt", string1 ) == string1.utf8.count, "write same1" )

        let string2 = StringIO( "🇩🇪🇺🇸🇫🇷🇮🇹🇬🇧\n" )
        string2.write( "🇪🇸🇯🇵🇷🇺🇨🇳\n" )

        XCTAssert( File.write( "same2.txt", string2 ) == string2.data.length, "write same2" )

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

        XCTAssert( fabs( Time().to_f - File.mtime( "diff1.txt" )!.to_f ) < 1.0, "modification time" )

        WARNING_DISPOSITION = .Ignore
        for mode in [0o700, 0o070, 0o007, 0o000] {
            File.chmod( mode, "diff1.txt" )
            XCTAssertEqual( File.open( "diff1.txt", "r" ) != nil, File.readable( "diff1.txt" ), "permission \(mode)" )
        }

        let files = ["diff1.txt", "same1.txt", "same2.txt"]
        XCTAssertEqual( Dir.glob( "*.txt" )!.sort(), files, "read directory" )
        XCTAssertEqual( Dir.glob( "**.txt", testdir )!.sort(), files.map { testdir+"/"+$0 }, "read directory" )
        XCTAssertEqual( Dir.open( "." )!.to_a.sort(), [".", ".."]+files, "read directory" )
        XCTAssertEqual( Kernel.open( "| ls \(testdir)" )!.to_a.sort(), files, "read popen" )
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measureBlock {
            // Put the code you want to measure the time of here.
        }
    }
    
}
