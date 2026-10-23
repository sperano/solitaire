import Foundation
import SolitaireKit

/// The player's statistics, persisted through a `StatisticsStore` after every change.
/// Create one per app: each instance holds its own copy and saves all of it.
@MainActor
@Observable
final class StatisticsModel {
    private(set) var statistics: GameStatistics
    private let store: any StatisticsStore

    init(store: any StatisticsStore) {
        self.store = store
        statistics = store.load() ?? GameStatistics()
    }

    /// `seconds` is nil for a win in untimed mode.
    func recordWin(gameID: UInt64, drawMode: DrawMode, seconds: Int?, moves: Int) {
        statistics.recordWin(gameID: gameID, drawMode: drawMode, seconds: seconds, moves: moves)
        store.save(statistics)
    }

    func recordLoss(gameID: UInt64, drawMode: DrawMode) {
        statistics.recordLoss(gameID: gameID, drawMode: drawMode)
        store.save(statistics)
    }

    func reset() {
        statistics = GameStatistics()
        store.save(statistics)
    }
}
