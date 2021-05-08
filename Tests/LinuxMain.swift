import XCTest

import sugar_dynamoTests

var tests = [XCTestCaseEntry]()
tests += sugar_libraryTests.allTests()
XCTMain(tests)
