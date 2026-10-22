import XCTest
@testable import SolitaireKit

final class StatisticsRecordTests: XCTestCase {
    private static let slowSeconds = 300
    private static let fastSeconds = 120
    private static let manyMoves = 140
    private static let fewMoves = 95

    func testEmptyRecordHasNoRateOrBests() {
        let record = StatisticsRecord()
        XCTAssertEqual(record.played, 0)
        XCTAssertEqual(record.won, 0)
        XCTAssertNil(record.winRate)
        XCTAssertNil(record.bestTimeSeconds)
        XCTAssertNil(record.fewestMoves)
        XCTAssertTrue(record.isValid)
    }

    func testWinCountsAsPlayedAndWonAndSetsBests() {
        var record = StatisticsRecord()
        record.recordWin(seconds: Self.slowSeconds, moves: Self.manyMoves)
        XCTAssertEqual(record.played, 1)
        XCTAssertEqual(record.won, 1)
        XCTAssertEqual(record.lost, 0)
        XCTAssertEqual(record.bestTimeSeconds, Self.slowSeconds)
        XCTAssertEqual(record.fewestMoves, Self.manyMoves)
        XCTAssertEqual(record.winRate, 1)
    }

    func testLossCountsAsPlayedOnly() {
        var record = StatisticsRecord()
        record.recordLoss()
        XCTAssertEqual(record.played, 1)
        XCTAssertEqual(record.won, 0)
        XCTAssertEqual(record.lost, 1)
        XCTAssertEqual(record.winRate, 0)
        XCTAssertNil(record.bestTimeSeconds)
    }

    func testBestTimeAndFewestMovesKeepTheLowestIndependently() {
        var record = StatisticsRecord()
        record.recordWin(seconds: Self.slowSeconds, moves: Self.fewMoves)
        record.recordWin(seconds: Self.fastSeconds, moves: Self.manyMoves)
        XCTAssertEqual(record.bestTimeSeconds, Self.fastSeconds)
        XCTAssertEqual(record.fewestMoves, Self.fewMoves)
        record.recordWin(seconds: Self.slowSeconds, moves: Self.manyMoves)
        XCTAssertEqual(record.bestTimeSeconds, Self.fastSeconds, "a slower win does not replace the best")
    }

    func testWinRateIsWonOverPlayed() {
        var record = StatisticsRecord()
        record.recordWin(seconds: Self.fastSeconds, moves: Self.fewMoves)
        record.recordLoss()
        record.recordLoss()
        record.recordLoss()
        XCTAssertEqual(try XCTUnwrap(record.winRate), 0.25, accuracy: .ulpOfOne)
    }

    func testStreaksGrowWithWinsAndCurrentResetsOnLoss() {
        var record = StatisticsRecord()
        record.recordWin(seconds: Self.fastSeconds, moves: Self.fewMoves)
        record.recordWin(seconds: Self.fastSeconds, moves: Self.fewMoves)
        record.recordWin(seconds: Self.fastSeconds, moves: Self.fewMoves)
        XCTAssertEqual(record.currentStreak, 3)
        XCTAssertEqual(record.longestStreak, 3)

        record.recordLoss()
        XCTAssertEqual(record.currentStreak, 0)
        XCTAssertEqual(record.longestStreak, 3)

        record.recordWin(seconds: Self.fastSeconds, moves: Self.fewMoves)
        XCTAssertEqual(record.currentStreak, 1)
        XCTAssertEqual(record.longestStreak, 3, "a shorter streak does not replace the longest")
        XCTAssertTrue(record.isValid)
    }

    // MARK: Validation

    func testImpossibleCountsAreInvalid() {
        var record = StatisticsRecord()
        record.recordWin(seconds: Self.fastSeconds, moves: Self.fewMoves)

        var moreWonThanPlayed = record
        moreWonThanPlayed.played = 0
        XCTAssertFalse(moreWonThanPlayed.isValid)

        var negative = StatisticsRecord()
        negative.played = -1
        XCTAssertFalse(negative.isValid)

        var full = StatisticsRecord()
        full.played = .max
        XCTAssertFalse(full.isValid, "one more game would overflow")
    }

    func testStreaksOutOfOrderAreInvalid() {
        var record = StatisticsRecord()
        record.recordWin(seconds: Self.fastSeconds, moves: Self.fewMoves)

        var currentAboveLongest = record
        currentAboveLongest.longestStreak = 0
        XCTAssertFalse(currentAboveLongest.isValid)

        var longestAboveWon = record
        longestAboveWon.longestStreak = 2
        XCTAssertFalse(longestAboveWon.isValid)
    }

    func testBestsMustExistExactlyWhenAGameWasWon() {
        var winWithoutBests = StatisticsRecord()
        winWithoutBests.recordWin(seconds: Self.fastSeconds, moves: Self.fewMoves)
        winWithoutBests.fewestMoves = nil
        XCTAssertFalse(winWithoutBests.isValid)

        var bestsWithoutWin = StatisticsRecord()
        bestsWithoutWin.recordLoss()
        bestsWithoutWin.bestTimeSeconds = Self.fastSeconds
        XCTAssertFalse(bestsWithoutWin.isValid)

        var negativeBest = StatisticsRecord()
        negativeBest.recordWin(seconds: Self.fastSeconds, moves: Self.fewMoves)
        negativeBest.bestTimeSeconds = -1
        XCTAssertFalse(negativeBest.isValid)
    }
}
