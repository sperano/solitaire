import Foundation
import SolitaireKit

/// What survives a relaunch: the game with its undo history, the time already spent on it,
/// and whether it already counts in the statistics.
struct SavedGame: Codable, Equatable {
    var game: Game
    var elapsedSeconds: Int
    /// A move has been made, so abandoning the game counts as a loss even after undoing to the deal.
    var isStarted: Bool
    /// The result is in the statistics; nothing more is recorded for this game.
    var isResultRecorded: Bool

    init(game: Game, elapsedSeconds: Int, isStarted: Bool = false, isResultRecorded: Bool = false) {
        self.game = game
        self.elapsedSeconds = elapsedSeconds
        self.isStarted = isStarted || game.moveCount > 0
        self.isResultRecorded = isResultRecorded
    }

    private enum CodingKeys: String, CodingKey {
        case game, elapsedSeconds, isStarted, isResultRecorded
    }

    /// Saves from before statistics have no flags: a won game is taken as already recorded,
    /// since no statistics existed when it was won.
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let game = try container.decode(Game.self, forKey: .game)
        self.init(
            game: game,
            elapsedSeconds: try container.decode(Int.self, forKey: .elapsedSeconds),
            isStarted: try container.decodeIfPresent(Bool.self, forKey: .isStarted) ?? false,
            isResultRecorded: try container.decodeIfPresent(Bool.self, forKey: .isResultRecorded) ?? game.isWon
        )
    }
}

@MainActor
protocol GameStore {
    func load() -> SavedGame?
    func save(_ saved: SavedGame?)
}

/// Keeps the current game in a JSON file in Application Support; a corrupt save starts a new game.
@MainActor
final class FileGameStore: GameStore {
    private let storage: JSONFileStorage<SavedGame>

    init(url: URL) {
        storage = JSONFileStorage(url: url)
    }

    func load() -> SavedGame? { storage.load() }

    func save(_ saved: SavedGame?) { storage.save(saved) }
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
