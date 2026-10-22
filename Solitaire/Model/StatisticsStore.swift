import Foundation
import SolitaireKit

@MainActor
protocol StatisticsStore {
    func load() -> GameStatistics?
    func save(_ statistics: GameStatistics)
}

/// Keeps the statistics in a JSON file in Application Support; an unreadable file starts from zero.
@MainActor
final class FileStatisticsStore: StatisticsStore {
    private let storage: JSONFileStorage<GameStatistics>

    init(url: URL) {
        storage = JSONFileStorage(url: url)
    }

    func load() -> GameStatistics? { storage.load() }

    func save(_ statistics: GameStatistics) { storage.save(statistics) }
}

/// For previews and tests.
@MainActor
final class InMemoryStatisticsStore: StatisticsStore {
    private(set) var saved: GameStatistics?

    init(saved: GameStatistics? = nil) {
        self.saved = saved
    }

    func load() -> GameStatistics? { saved }

    func save(_ statistics: GameStatistics) { saved = statistics }
}
