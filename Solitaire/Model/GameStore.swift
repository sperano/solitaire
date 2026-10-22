import Foundation
import OSLog
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
    private static let logger = Logger(subsystem: "quebec.spe.Solitaire", category: "GameStore")

    private let url: URL

    init(url: URL) {
        self.url = url
    }

    /// The saved game, or nil when there is none or it cannot be read; a corrupt save starts a new game.
    func load() -> SavedGame? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        do {
            return try JSONDecoder().decode(SavedGame.self, from: data)
        } catch {
            Self.logger.error("Discarding unreadable saved game: \(error.localizedDescription, privacy: .public)")
            return nil
        }
    }

    /// Best effort: a failed write is logged and the game keeps going; the next move tries again.
    func save(_ saved: SavedGame?) {
        do {
            guard let saved else {
                if FileManager.default.fileExists(atPath: url.path) {
                    try FileManager.default.removeItem(at: url)
                }
                return
            }
            let data = try JSONEncoder().encode(saved)
            try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
            try data.write(to: url, options: .atomic)
        } catch {
            Self.logger.error("Could not save the game: \(error.localizedDescription, privacy: .public)")
        }
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
