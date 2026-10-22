import XCTest
@testable import SolitaireKit

final class GameStatisticsTests: XCTestCase {
    private static let seconds = 200
    private static let moves = 110
    private static let gameID: UInt64 = 1_000

    private func roundTrip(_ statistics: GameStatistics) throws -> GameStatistics {
        try JSONDecoder().decode(GameStatistics.self, from: JSONEncoder().encode(statistics))
    }

    func testResultsCountForTheirDrawModeAndOverall() {
        var statistics = GameStatistics()
        statistics.recordWin(gameID: 1, drawMode: .one, seconds: Self.seconds, moves: Self.moves)
        statistics.recordLoss(gameID: 6, drawMode: .three)
        statistics.recordLoss(gameID: 7, drawMode: .three)

        XCTAssertEqual(statistics[.one].played, 1)
        XCTAssertEqual(statistics[.one].won, 1)
        XCTAssertEqual(statistics[.three].played, 2)
        XCTAssertEqual(statistics[.three].won, 0)
        XCTAssertEqual(statistics.overall.played, 3)
        XCTAssertEqual(statistics.overall.won, 1)
        XCTAssertEqual(statistics.overall.bestTimeSeconds, Self.seconds)
        XCTAssertTrue(statistics.isValid)
    }

    func testOverallStreakBreaksOnALossInEitherMode() {
        var statistics = GameStatistics()
        statistics.recordWin(gameID: 2, drawMode: .one, seconds: Self.seconds, moves: Self.moves)
        statistics.recordLoss(gameID: 8, drawMode: .three)
        statistics.recordWin(gameID: 3, drawMode: .one, seconds: Self.seconds, moves: Self.moves)

        XCTAssertEqual(statistics[.one].currentStreak, 2, "draw-3 losses do not break the draw-1 streak")
        XCTAssertEqual(statistics.overall.currentStreak, 1)
        XCTAssertEqual(statistics.overall.longestStreak, 1)
    }

    func testStatisticsRoundTrip() throws {
        var statistics = GameStatistics()
        statistics.recordWin(gameID: 4, drawMode: .three, seconds: Self.seconds, moves: Self.moves)
        statistics.recordLoss(gameID: 9, drawMode: .one)
        XCTAssertEqual(try roundTrip(statistics), statistics)
        XCTAssertEqual(try roundTrip(GameStatistics()), GameStatistics())
    }

    func testOverallThatDoesNotMatchTheModesIsInvalid() {
        var statistics = GameStatistics()
        statistics.recordLoss(gameID: 10, drawMode: .one)
        statistics.overall = StatisticsRecord()
        XCTAssertFalse(statistics.isValid)
    }

    func testDecodingRejectsInconsistentStatistics() throws {
        var statistics = GameStatistics()
        statistics.recordWin(gameID: 5, drawMode: .one, seconds: Self.seconds, moves: Self.moves)
        var object = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(statistics)) as? [String: Any])
        var drawOne = try XCTUnwrap(object["drawOne"] as? [String: Any])
        drawOne["won"] = 2
        object["drawOne"] = drawOne
        let data = try JSONSerialization.data(withJSONObject: object)
        XCTAssertThrowsError(try JSONDecoder().decode(GameStatistics.self, from: data))
    }

    func testDecodingRejectsMissingRecords() throws {
        let valid = try JSONSerialization.jsonObject(with: JSONEncoder().encode(StatisticsRecord()))
        let data = try JSONSerialization.data(withJSONObject: ["overall": valid, "drawOne": valid])
        XCTAssertThrowsError(try JSONDecoder().decode(GameStatistics.self, from: data), "drawThree is missing")
    }

    func testRecordingTheSameGameAgainIsIgnored() {
        var statistics = GameStatistics()
        statistics.recordWin(gameID: Self.gameID, drawMode: .one, seconds: Self.seconds, moves: Self.moves)
        statistics.recordWin(gameID: Self.gameID, drawMode: .one, seconds: Self.seconds, moves: Self.moves)
        statistics.recordLoss(gameID: Self.gameID, drawMode: .one)
        XCTAssertEqual(statistics.overall.played, 1)
        XCTAssertEqual(statistics.lastRecordedGameID, Self.gameID)

        statistics.recordLoss(gameID: Self.gameID + 1, drawMode: .one)
        XCTAssertEqual(statistics.overall.played, 2)
    }

    func testOverallBestsMustMatchTheModeBests() {
        var statistics = GameStatistics()
        statistics.recordWin(gameID: Self.gameID, drawMode: .one, seconds: Self.seconds, moves: Self.moves)
        var wrongTime = statistics
        wrongTime.overall.bestTimeSeconds = Self.seconds - 1
        XCTAssertFalse(wrongTime.isValid)
        var wrongMoves = statistics
        wrongMoves.overall.fewestMoves = Self.moves + 1
        XCTAssertFalse(wrongMoves.isValid)
    }

    func testOverallBestsAreTheLowestAcrossModes() {
        var statistics = GameStatistics()
        statistics.recordWin(gameID: Self.gameID, drawMode: .one, seconds: Self.seconds, moves: Self.moves + 1)
        statistics.recordWin(gameID: Self.gameID + 1, drawMode: .three, seconds: Self.seconds + 1, moves: Self.moves)
        XCTAssertEqual(statistics.overall.bestTimeSeconds, Self.seconds)
        XCTAssertEqual(statistics.overall.fewestMoves, Self.moves)
        XCTAssertTrue(statistics.isValid)
    }

    func testModeCountsWhoseSumOverflowsAreInvalidNotACrash() {
        var statistics = GameStatistics()
        statistics.drawOne.played = .max - 1
        statistics.drawThree.played = .max - 1
        XCTAssertFalse(statistics.isValid)
    }
}
