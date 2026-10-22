import XCTest
@testable import SolitaireKit

final class GameStatisticsTests: XCTestCase {
    private static let seconds = 200
    private static let moves = 110

    private func roundTrip(_ statistics: GameStatistics) throws -> GameStatistics {
        try JSONDecoder().decode(GameStatistics.self, from: JSONEncoder().encode(statistics))
    }

    func testResultsCountForTheirDrawModeAndOverall() {
        var statistics = GameStatistics()
        statistics.recordWin(drawMode: .one, seconds: Self.seconds, moves: Self.moves)
        statistics.recordLoss(drawMode: .three)
        statistics.recordLoss(drawMode: .three)

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
        statistics.recordWin(drawMode: .one, seconds: Self.seconds, moves: Self.moves)
        statistics.recordLoss(drawMode: .three)
        statistics.recordWin(drawMode: .one, seconds: Self.seconds, moves: Self.moves)

        XCTAssertEqual(statistics[.one].currentStreak, 2, "draw-3 losses do not break the draw-1 streak")
        XCTAssertEqual(statistics.overall.currentStreak, 1)
        XCTAssertEqual(statistics.overall.longestStreak, 1)
    }

    func testStatisticsRoundTrip() throws {
        var statistics = GameStatistics()
        statistics.recordWin(drawMode: .three, seconds: Self.seconds, moves: Self.moves)
        statistics.recordLoss(drawMode: .one)
        XCTAssertEqual(try roundTrip(statistics), statistics)
        XCTAssertEqual(try roundTrip(GameStatistics()), GameStatistics())
    }

    func testOverallThatDoesNotMatchTheModesIsInvalid() {
        var statistics = GameStatistics()
        statistics.recordLoss(drawMode: .one)
        statistics.overall = StatisticsRecord()
        XCTAssertFalse(statistics.isValid)
    }

    func testDecodingRejectsInconsistentStatistics() throws {
        var statistics = GameStatistics()
        statistics.recordWin(drawMode: .one, seconds: Self.seconds, moves: Self.moves)
        var object = try XCTUnwrap(JSONSerialization.jsonObject(with: JSONEncoder().encode(statistics)) as? [String: Any])
        var drawOne = try XCTUnwrap(object["drawOne"] as? [String: Any])
        drawOne["won"] = 2
        object["drawOne"] = drawOne
        let data = try JSONSerialization.data(withJSONObject: object)
        XCTAssertThrowsError(try JSONDecoder().decode(GameStatistics.self, from: data))
    }

    func testDecodingRejectsMissingRecords() throws {
        let data = try JSONSerialization.data(withJSONObject: ["overall": [String: Any]()])
        XCTAssertThrowsError(try JSONDecoder().decode(GameStatistics.self, from: data))
    }
}
