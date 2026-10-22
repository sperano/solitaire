import Foundation
import SolitaireKit

/// What survives a relaunch: the game with its undo history and the time already spent on it.
struct SavedGame: Codable, Equatable {
    var game: Game
    var elapsedSeconds: Int
}

@MainActor
protocol GameStore {
    func load() -> SavedGame?
    func save(_ saved: SavedGame?)
}

/// Keeps the current game in a JSON file in Application Support.
@MainActor
final class FileGameStore: GameStore {
    private let url: URL

    init(url: URL) {
        self.url = url
    }

    func load() -> SavedGame? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(SavedGame.self, from: data)
    }

    func save(_ saved: SavedGame?) {
        guard let saved else {
            try? FileManager.default.removeItem(at: url)
            return
        }
        guard let data = try? JSONEncoder().encode(saved) else { return }
        try? FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try? data.write(to: url, options: .atomic)
    }
}

/// For previews and tests.
@MainActor
final class InMemoryGameStore: GameStore {
    private(set) var saved: SavedGame?

    init(saved: SavedGame? = nil) {
        self.saved = saved
    }

    func load() -> SavedGame? { saved }

    func save(_ saved: SavedGame?) { self.saved = saved }
}
