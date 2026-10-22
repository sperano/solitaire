import XCTest

/// Scoring on the `-seed 42` deal, whose seventh column is the ace of hearts on six face-down cards.
final class ScoringUITests: SolitaireUITestCase {
    private static let standardArguments = ["-drawMode", "1", "-scoringMode", "1"]
    private static let vegasArguments = ["-drawMode", "1", "-scoringMode", "2"]
    private static let noScoringArguments = ["-drawMode", "1", "-scoringMode", "0"]
    /// Ten for the ace reaching a foundation, five for turning over the card under it.
    private static let aceToFoundationScore = "15"
    private static let vegasStartingScore = "-$52"
    private static let vegasAfterOneFoundationCard = "-$47"

    private func expectScore(_ expected: String, file: StaticString = #filePath, line: UInt = #line) {
        let label = element("scoreLabel")
        XCTAssertTrue(label.waitForExistence(timeout: Self.timeout), "scoreLabel not found", file: file, line: line)
        XCTAssertEqual(label.label, "Score \(expected)", file: file, line: line)
    }

    func testStandardScoreCountsAFoundationMoveAndTheFlip() {
        app = launchApp(extraArguments: Self.standardArguments)
        expectScore("0")
        tap("card-AH")
        expectScore(Self.aceToFoundationScore)
    }

    func testUndoTakesThePointsBack() {
        app = launchApp(extraArguments: Self.standardArguments)
        tap("card-AH")
        expectScore(Self.aceToFoundationScore)
        tap("undoButton")
        expectScore("0")
    }

    func testVegasStartsWithTheBuyInAndPaysPerFoundationCard() {
        app = launchApp(extraArguments: Self.vegasArguments)
        expectScore(Self.vegasStartingScore)
        tap("card-AH")
        expectScore(Self.vegasAfterOneFoundationCard)
    }

    func testVegasDrawOneStopsAfterOnePass() {
        app = launchApp(extraArguments: Self.vegasArguments)
        tapStock(times: Self.stockSize)
        expectCards(0, in: "stock")
        tapStock()
        expectCards(Self.stockSize, in: "waste")
        XCTAssertEqual(moves, "\(Self.stockSize)")
    }

    func testNoScoreLabelWithoutScoring() {
        app = launchApp(extraArguments: Self.noScoringArguments)
        XCTAssertTrue(element("movesLabel").waitForExistence(timeout: Self.timeout))
        XCTAssertFalse(element("scoreLabel").waitForExistence(timeout: Self.absenceTimeout))
    }

    func testChoosingVegasInSettingsAppliesToTheNextGame() {
        app = launchApp(extraArguments: Self.standardArguments)
        tap("settingsButton")
        let picker = element("scoringModePicker")
        XCTAssertTrue(picker.waitForExistence(timeout: Self.timeout))
        picker.buttons["Vegas"].tap()
        XCTAssertTrue(element("carryVegasBalanceToggle").waitForExistence(timeout: Self.timeout))
        tap("settingsDoneButton")
        expectScore("0")

        tap("newGameButton")
        expectScore(Self.vegasStartingScore)
    }
}
