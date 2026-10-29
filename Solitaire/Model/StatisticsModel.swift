import Foundation
import SolitaireKit

/// The player's statistics and best scores, each persisted through its store after every change.
/// Create one per app: each instance holds its own copy and saves all of it.
@MainActor
@Observable
final class StatisticsModel {
    private(set) var statistics: GameStatistics
    private(set) var bestScores: BestScores
    private let store: any StatisticsStore
    private let bestScoresStore: any BestScoresStore
    private let now: () -> Date

    init(
        store: any StatisticsStore,
        bestScoresStore: any BestScoresStore = InMemoryBestScoresStore(),
        now: @escaping () -> Date = Date.init
    ) {
        self.store = store
        self.bestScoresStore = bestScoresStore
        self.now = now
        statistics = store.load() ?? GameStatistics()
        bestScores = bestScoresStore.load() ?? BestScores()
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

    /// Ranks the standard-scored win of `game`, dated now. `score` includes the time bonus;
    /// `seconds` is nil for a win in untimed mode.
    func recordBestScore(of game: Game, gameID: UInt64, score: Int, seconds: Int?) {
        let win = BestScore(
            score: score, drawMode: game.drawMode, moves: game.moveCount, seconds: seconds,
            dealNumber: game.state.seed, wonAt: Int(now().timeIntervalSince1970)
        )
        bestScores.record(win, gameID: gameID)
        bestScoresStore.save(bestScores)
    }

    /// Clears the statistics; the best scores stay.
    func reset() {
        statistics = GameStatistics()
        store.save(statistics)
    }

    func resetBestScores() {
        bestScores = BestScores()
        bestScoresStore.save(bestScores)
    }
}
