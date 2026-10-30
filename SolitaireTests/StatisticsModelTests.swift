import SolitaireKit
import XCTest
@testable import Solitaire

@MainActor
final class StatisticsModelTests: XCTestCase {
    private static let seconds = 180
    private static let moves = 120

    func testStartsFromTheStoredStatistics() {
        var stored = GameStatistics()
        stored.recordLoss(gameID: 1, drawMode: .one)
        let model = StatisticsModel(store: InMemoryStatisticsStore(saved: stored))
        XCTAssertEqual(model.statistics, stored)
    }

    func testStartsFromZeroWhenNothingIsStored() {
        XCTAssertEqual(StatisticsModel(store: InMemoryStatisticsStore()).statistics, GameStatistics())
    }

    func testEveryResultIsSavedImmediately() {
        let store = InMemoryStatisticsStore()
        let model = StatisticsModel(store: store)

        model.recordWin(gameID: 1, drawMode: .three, seconds: Self.seconds, moves: Self.moves)
        XCTAssertEqual(store.saved?[.three].won, 1)

        model.recordLoss(gameID: 2, drawMode: .one)
        XCTAssertEqual(store.saved?[.one].played, 1)
        XCTAssertEqual(store.saved, model.statistics)
    }

    func testResetClearsAndSaves() {
        let store = InMemoryStatisticsStore()
        let model = StatisticsModel(store: store)
        model.recordLoss(gameID: 1, drawMode: .one)

        model.reset()

        XCTAssertEqual(model.statistics, GameStatistics())
        XCTAssertEqual(store.saved, GameStatistics())
    }

    func testTheSameGameIsRecordedOnce() {
        let store = InMemoryStatisticsStore()
        let model = StatisticsModel(store: store)
        model.recordWin(gameID: 1, drawMode: .one, seconds: Self.seconds, moves: Self.moves)
        model.recordWin(gameID: 1, drawMode: .one, seconds: Self.seconds, moves: Self.moves)
        XCTAssertEqual(store.saved?.overall.won, 1)
    }

    // MARK: Best scores

    private static let score = 3_500
    private static let wonAt = Date(timeIntervalSince1970: 1_800_000_000)

    func testABestScoreIsDatedAndSavedApartFromTheStatistics() throws {
        let statisticsStore = InMemoryStatisticsStore()
        let bestScoresStore = InMemoryBestScoresStore()
        let model = StatisticsModel(store: statisticsStore, bestScoresStore: bestScoresStore) { Self.wonAt }
        let game = try Game.won()

        model.recordBestScore(of: game, gameID: 1, score: Self.score, seconds: Self.seconds)

        let best = try XCTUnwrap(bestScoresStore.saved?[.one].first)
        XCTAssertEqual(best.score, Self.score)
        XCTAssertEqual(best.wonAt, Int(Self.wonAt.timeIntervalSince1970))
        XCTAssertEqual(best.moves, game.moveCount)
        XCTAssertEqual(best.dealNumber, game.state.seed)
        XCTAssertNil(statisticsStore.saved, "ranking a score records no result")
    }

    func testStartsFromTheStoredBestScores() {
        var stored = BestScores()
        let win = BestScore(
            score: Self.score, drawMode: .three, moves: Self.moves, seconds: nil, dealNumber: 1, wonAt: 0
        )
        stored.record(win, gameID: 1)
        let model = StatisticsModel(
            store: InMemoryStatisticsStore(),
            bestScoresStore: InMemoryBestScoresStore(saved: stored)
        )
        XCTAssertEqual(model.bestScores, stored)
    }

    func testEachResetLeavesTheOtherTable() throws {
        let statisticsStore = InMemoryStatisticsStore()
        let bestScoresStore = InMemoryBestScoresStore()
        let model = StatisticsModel(store: statisticsStore, bestScoresStore: bestScoresStore)
        model.recordWin(gameID: 1, drawMode: .one, seconds: Self.seconds, moves: Self.moves)
        model.recordBestScore(of: try Game.won(), gameID: 1, score: Self.score, seconds: Self.seconds)

        model.reset()
        XCTAssertEqual(model.bestScores[.one].count, 1, "resetting statistics keeps the best scores")

        model.recordWin(gameID: 2, drawMode: .one, seconds: Self.seconds, moves: Self.moves)
        model.resetBestScores()
        XCTAssertEqual(model.statistics.overall.won, 1, "resetting best scores keeps the statistics")
        XCTAssertEqual(bestScoresStore.saved, BestScores())
    }
}
