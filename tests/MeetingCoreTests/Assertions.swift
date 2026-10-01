import Testing

func XCTAssertEqual<T: Equatable>(_ actual: T, _ expected: T) {
    #expect(actual == expected)
}

func XCTAssertTrue(_ value: @autoclosure () -> Bool) {
    #expect(value())
}

func XCTAssertNil<T>(_ value: T?) {
    #expect(value == nil)
}

func XCTAssertThrowsError<T>(_ operation: @autoclosure () throws -> T) {
    var threw = false
    do { _ = try operation() } catch { threw = true }
    #expect(threw)
}
