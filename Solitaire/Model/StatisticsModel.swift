import Foundation
import SolitaireKit

/// The player's statistics, persisted through a `StatisticsStore` after every change.
@MainActor
@Observable
final class StatisticsModel {
    private(set) var statistics: GameStatistics
    private let store: any StatisticsStore

    init(store: any StatisticsStore) {
        self.store = store
        statistics = store.load() ?? GameStatistics()
    }

    func recordWin(drawMode: DrawMode, seconds: Int, moves: Int) {
        statistics.recordWin(drawMode: drawMode, seconds: seconds, moves: moves)
        store.save(statistics)
    }

    func recordLoss(drawMode: DrawMode) {
        statistics.recordLoss(drawMode: drawMode)
        store.save(statistics)
    }

    func reset() {
        statistics = GameStatistics()
        store.save(statistics)
    }
}
