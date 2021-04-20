import XCTest

#if !canImport(ObjectiveC)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(sugar_dynamoTests.allTests),
    ]
}
#endif
