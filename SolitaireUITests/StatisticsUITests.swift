import XCTest

/// Statistics start empty under `--ui-testing`; abandoning a started game is the result UI tests can
/// produce, and the `completable` position, finished, a win.
final class StatisticsUITests: SolitaireUITestCase {
    private func abandonStartedGame() {
        tap("card-AH")
        XCTAssertEqual(moves, "1")
        tap("newGameButton")
        tap("confirmNewGameButton")
        XCTAssertEqual(moves, "0")
    }

    private func openStatistics() {
        tap("settingsButton")
        scrollTo("statisticsLink").tap()
        XCTAssertTrue(element("statsPlayed").waitForExistence(timeout: Self.timeout))
    }

    private func expectStat(
        _ identifier: String,
        _ expected: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertEqual(value(of: identifier), expected, identifier, file: file, line: line)
    }

    func testEmptyStatisticsShowDashes() {
        openStatistics()
        expectStat("statsPlayed", "0")
        expectStat("statsWinRate", "none")
        expectStat("statsBestTime", "none")
        expectStat("statsFewestMoves", "none")
    }

    func testAbandonedGameCountsAsALoss() {
        abandonStartedGame()
        openStatistics()
        expectStat("statsPlayed", "1")
        expectStat("statsWon", "0")
        expectStat("statsWinRate", "0%")
        expectStat("statsCurrentStreak", "0")
    }

    func testLossOnlyCountsForItsDrawMode() {
        abandonStartedGame()
        openStatistics()
        element("statisticsScopePicker").buttons["Draw 3"].tap()
        expectStat("statsPlayed", "0")
        element("statisticsScopePicker").buttons["Draw 1"].tap()
        expectStat("statsPlayed", "1")
    }

    func testResetAsksThenClears() {
        abandonStartedGame()
        openStatistics()
        tap("resetStatisticsButton")
        tap("confirmResetStatisticsButton")
        expectStat("statsPlayed", "0")
    }

    private func winCompletableGame() {
        app.terminate()
        app = launchApp(extraArguments: ["-drawMode", "1", "-position", "completable"])
        tap("autoCompleteButton")
        tap("winNewGameButton")
    }

    private func openBestScores() {
        openStatistics()
        scrollTo("bestScoresLink").tap()
        XCTAssertTrue(element("resetBestScoresButton").waitForExistence(timeout: Self.timeout))
    }

    func testBestScoresStartEmpty() {
        openBestScores()
        XCTAssertTrue(element("bestScoresEmptyLabel").exists)
        XCTAssertFalse(element("bestScore-1").exists)
    }

    func testAStandardWinIsRankedThenReset() {
        winCompletableGame()
        openBestScores()
        let first = element("bestScore-1")
        XCTAssertTrue(first.exists)
        XCTAssertTrue(first.label.contains("points"), first.label)
        XCTAssertFalse(element("bestScore-2").exists)

        tap("resetBestScoresButton")
        tap("confirmResetBestScoresButton")
        XCTAssertTrue(element("bestScoresEmptyLabel").waitForExistence(timeout: Self.timeout))
    }

    func testAWinIsRankedOnlyForItsDrawMode() {
        winCompletableGame()
        openStatistics()
        element("statisticsScopePicker").buttons["Draw 3"].tap()
        scrollTo("bestScoresLink").tap()
        XCTAssertTrue(element("bestScoresEmptyLabel").waitForExistence(timeout: Self.timeout))
    }
}
