import XCTest

/// With `-seed 42` the ace of hearts tops the last column, so the hint sends it to a foundation.
final class HintUITests: SolitaireUITestCase {
    func testHintHighlightsTheAceUntilItMoves() {
        let ace = element("card-AH")
        XCTAssertTrue(ace.waitForExistence(timeout: Self.timeout))
        XCTAssertFalse(ace.isSelected)

        tap("hintButton")
        expectSelected(ace, true)

        tap("card-AH")
        expectCards(1, in: "foundation-0")
        expectSelected(ace, false)
    }

    private func expectSelected(
        _ element: XCUIElement,
        _ selected: Bool,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let predicate = NSPredicate(format: "isSelected == %@", NSNumber(value: selected))
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: element)
        XCTAssertEqual(XCTWaiter.wait(for: [expectation], timeout: Self.timeout), .completed, file: file, line: line)
    }

    func testHintSaysSoWhenNothingHelps() {
        app.terminate()
        app = launchApp(extraArguments: ["-drawMode", "1", "-position", "deadlocked"])
        XCTAssertFalse(element("noHintLabel").exists)
        tap("hintButton")
        XCTAssertTrue(element("noHintLabel").waitForExistence(timeout: Self.timeout))
    }
}
