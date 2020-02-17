import XCTest

import pm_http_serverTests

var tests = [XCTestCaseEntry]()
tests += pm_http_serverTests.allTests()
XCTMain(tests)
