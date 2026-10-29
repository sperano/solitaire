import XCTest
@testable import SolitaireKit

final class BestScoresTests: XCTestCase {
    private static let moves = 120
    private static let seconds = 240
    private static let dealNumber: UInt64 = 1_234_567
    private static let firstWin = 1_800_000_000

    private func win(_ score: Int, _ drawMode: DrawMode = .one, at offset: Int = 0) -> BestScore {
        BestScore(
            score: score, drawMode: drawMode, moves: Self.moves, seconds: Self.seconds,
            dealNumber: Self.dealNumber, wonAt: Self.firstWin + offset
        )
    }

    /// Records each win as its own game, in order.
    private func recording(_ wins: [BestScore]) -> BestScores {
        var scores = BestScores()
        for (gameID, win) in wins.enumerated() { scores.record(win, gameID: UInt64(gameID)) }
        return scores
    }

    private func roundTrip(_ scores: BestScores) throws -> BestScores {
        try JSONDecoder().decode(BestScores.self, from: JSONEncoder().encode(scores))
    }

    func testWinsAreKeptBestFirstForTheirDrawMode() {
        let scores = recording([win(500), win(900, .three), win(700)])
        XCTAssertEqual(scores[.one].map(\.score), [700, 500])
        XCTAssertEqual(scores[.three].map(\.score), [900])
        XCTAssertTrue(scores.isValid)
    }

    func testOnlyTheTopTenAreKept() {
        let wins = (1 ... BestScores.capacity + 2).map { win($0 * 100, at: $0) }
        let scores = recording(wins)
        XCTAssertEqual(scores[.one].count, BestScores.capacity)
        XCTAssertEqual(scores[.one].last?.score, 300, "the two lowest dropped out")

        var full = scores
        full.record(win(100, at: 99), gameID: 99)
        XCTAssertEqual(full[.one], scores[.one], "a win below the table changes nothing")
    }

    func testAnEqualScoreRanksBehindTheEarlierWin() {
        let scores = recording([win(800, at: 0), win(800, at: 5)])
        XCTAssertEqual(scores[.one].map(\.wonAt), [Self.firstWin, Self.firstWin + 5])
    }

    func testOverallMergesBothDrawModesWithinTheCapacity() {
        let wins = (1 ... BestScores.capacity)
            .flatMap { [win($0 * 10, .one, at: $0), win($0 * 10 + 5, .three, at: $0)] }
        let overall = recording(wins).overall
        XCTAssertEqual(overall.count, BestScores.capacity)
        XCTAssertEqual(overall.first?.score, 105)
        XCTAssertEqual(overall.first?.drawMode, .three)
        XCTAssertEqual(overall.map(\.score), overall.map(\.score).sorted(by: >))
    }

    func testTheSameGameIsRecordedOnce() {
        var scores = BestScores()
        scores.record(win(600), gameID: 7)
        scores.record(win(600), gameID: 7)
        XCTAssertEqual(scores[.one].count, 1)
        XCTAssertEqual(scores.lastRecordedGameID, 7)
    }

    func testBestScoresRoundTrip() throws {
        let scores = recording([win(500), win(900, .three)])
        XCTAssertEqual(try roundTrip(scores), scores)
        XCTAssertEqual(try roundTrip(BestScores()), BestScores())
    }

    func testListsRecordingCouldNotProduceAreRejected() throws {
        var unsorted = recording([win(500), win(700)])
        unsorted.drawOne.reverse()
        var wrongMode = BestScores()
        wrongMode.drawOne = [win(500, .three)]
        var negative = BestScores()
        negative.drawThree = [win(-5, .three)]
        var tooMany = BestScores()
        tooMany.drawOne = (0 ... BestScores.capacity).map { win(100, at: $0) }

        for scores in [unsorted, wrongMode, negative, tooMany] {
            XCTAssertFalse(scores.isValid)
            XCTAssertThrowsError(try roundTrip(scores))
        }
    }
}
