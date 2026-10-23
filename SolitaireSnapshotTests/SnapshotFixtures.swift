import SolitaireKit
import SwiftUI
@testable import Solitaire

/// Deterministic boards and models for the snapshots.
@MainActor
enum SnapshotFixtures {
    /// The UI tests' reference deal: tableau tops 2♣ 8♣ Q♣ 5♥ 6♠ 5♣ A♥.
    static let seed: UInt64 = 42
    /// Suggested moves played from the deal to reach the mid-game board.
    static let midGameMoveCount = 12
    /// How far the lifted run is dragged from its column.
    static let liftedRunTranslation = CGSize(width: 36, height: -48)
    /// Elapsed time of the won game: long enough for a time bonus, short enough to read.
    static let wonGameSeconds = 65
    private static let defaultsSuite = "quebec.spe.SolitaireSnapshotTests"

    /// Fresh default settings for every snapshot, so no preference leaks between tests.
    static func settings() -> GameSettings {
        let defaults = UserDefaults(suiteName: defaultsSuite) ?? .standard
        defaults.removePersistentDomain(forName: defaultsSuite)
        return GameSettings(defaults: defaults)
    }

    static func statistics() -> StatisticsModel {
        StatisticsModel(store: InMemoryStatisticsStore())
    }

    /// A model showing `game`, or the reference deal when nil.
    static func viewModel(resuming game: Game? = nil, elapsedSeconds: Int = 0) -> GameViewModel {
        let saved = game.map { SavedGame(game: $0, elapsedSeconds: elapsedSeconds) }
        return GameViewModel(
            store: InMemoryGameStore(saved: saved), settings: settings(), statistics: statistics(), fixedSeed: seed
        )
    }

    /// The reference deal after `midGameMoveCount` suggested moves.
    static func midGame() -> Game {
        var game = Game(seed: seed, drawMode: GameSettings.defaultDrawMode, scoringMode: GameSettings.defaultScoringMode)
        for _ in 0 ..< midGameMoveCount {
            guard let move = game.suggestedMove() else { break }
            try? game.perform(move)
        }
        return game
    }

    /// The face-up run of the first column holding at least two face-up cards, lifted as a drag.
    static func liftedRun(in state: GameState) -> DragInfo? {
        for (index, column) in state.tableau.enumerated() {
            let faceUp = column.filter(\.isFaceUp).count
            if faceUp >= 2 {
                return DragInfo(source: .tableau(index), count: faceUp, translation: liftedRunTranslation)
            }
        }
        return nil
    }

    /// The completable fixture played to the win, with standard scoring so the win panel shows a score.
    static func wonGame() -> Game {
        var game = Game(state: FixturePosition.completable.state(drawMode: .one, scoringMode: .standard))
        while let move = game.nextAutoCompleteMove() {
            try? game.perform(move)
        }
        return game
    }
}
