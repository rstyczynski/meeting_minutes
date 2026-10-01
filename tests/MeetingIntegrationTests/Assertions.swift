import Testing

func XCTAssertEqual<T: Equatable>(_ actual: T, _ expected: T) {
    #expect(actual == expected)
}

func XCTAssertTrue(_ value: @autoclosure () -> Bool) {
    #expect(value())
}

func XCTAssertNotNil<T>(_ value: @autoclosure () -> T?) {
    #expect(value() != nil)
}

func XCTAssertGreaterThan<T: Comparable>(_ actual: @autoclosure () -> T,
                                          _ expected: @autoclosure () -> T) {
    #expect(actual() > expected())
}
