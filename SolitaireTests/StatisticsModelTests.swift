import SolitaireKit
import XCTest
@testable import Solitaire

@MainActor
final class StatisticsModelTests: XCTestCase {
    private static let seconds = 180
    private static let moves = 120

    func testStartsFromTheStoredStatistics() {
        var stored = GameStatistics()
        stored.recordLoss(drawMode: .one)
        let model = StatisticsModel(store: InMemoryStatisticsStore(saved: stored))
        XCTAssertEqual(model.statistics, stored)
    }

    func testStartsFromZeroWhenNothingIsStored() {
        XCTAssertEqual(StatisticsModel(store: InMemoryStatisticsStore()).statistics, GameStatistics())
    }

    func testEveryResultIsSavedImmediately() {
        let store = InMemoryStatisticsStore()
        let model = StatisticsModel(store: store)

        model.recordWin(drawMode: .three, seconds: Self.seconds, moves: Self.moves)
        XCTAssertEqual(store.saved?[.three].won, 1)

        model.recordLoss(drawMode: .one)
        XCTAssertEqual(store.saved?[.one].played, 1)
        XCTAssertEqual(store.saved, model.statistics)
    }

    func testResetClearsAndSaves() {
        let store = InMemoryStatisticsStore()
        let model = StatisticsModel(store: store)
        model.recordLoss(drawMode: .one)

        model.reset()

        XCTAssertEqual(model.statistics, GameStatistics())
        XCTAssertEqual(store.saved, GameStatistics())
    }
}
