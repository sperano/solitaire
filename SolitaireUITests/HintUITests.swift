import XCTest

/// With `-seed 42` the ace of hearts tops the last column, so the hint sends it to a foundation.
final class HintUITests: SolitaireUITestCase {
    func testHintHighlightsTheAceUntilItMoves() {
        let ace = element("card-AH")
        XCTAssertTrue(ace.waitForExistence(timeout: Self.timeout))
        XCTAssertFalse(ace.isSelected)

        tap("hintButton")
        XCTAssertTrue(ace.isSelected)

        tap("card-AH")
        expectCards(1, in: "foundation-0")
        XCTAssertFalse(ace.isSelected)
    }

    func testHintSaysSoWhenNothingHelps() {
        app.terminate()
        app = launchApp(extraArguments: ["-drawMode", "1", "-position", "deadlocked"])
        XCTAssertFalse(element("noHintLabel").exists)
        tap("hintButton")
        XCTAssertTrue(element("noHintLabel").waitForExistence(timeout: Self.timeout))
    }
}
