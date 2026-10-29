import Foundation
import SolitaireKit

@MainActor
protocol BestScoresStore {
    func load() -> BestScores?
    func save(_ scores: BestScores)
}

/// Keeps the best scores in a JSON file in Application Support, apart from the statistics so
/// each can be reset alone; an unreadable file starts from an empty table.
@MainActor
final class FileBestScoresStore: BestScoresStore {
    private let storage: JSONFileStorage<BestScores>

    init(url: URL) {
        storage = JSONFileStorage(url: url)
    }

    func load() -> BestScores? { storage.load() }

    func save(_ scores: BestScores) { storage.save(scores) }
}

/// For previews and tests.
@MainActor
final class InMemoryBestScoresStore: BestScoresStore {
    private(set) var saved: BestScores?

    init(saved: BestScores? = nil) {
        self.saved = saved
    }

    func load() -> BestScores? { saved }

    func save(_ scores: BestScores) { saved = scores }
}
