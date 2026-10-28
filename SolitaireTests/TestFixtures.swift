import Foundation
import SolitaireKit
import XCTest
@testable import Solitaire

extension Game {
    static let completableRemainingCardCount = FixturePosition.completableRemainingCardCount

    /// See `FixturePosition.completable`.
    static func completable(scoringMode: ScoringMode = .none, drawMode: DrawMode = .one) -> Game {
        Game(state: FixturePosition.completable.state(drawMode: drawMode, scoringMode: scoringMode))
    }

    /// See `FixturePosition.oneMoveFromCompletable`.
    static func oneMoveFromCompletable() -> Game {
        Game(state: FixturePosition.oneMoveFromCompletable.state())
    }

    /// `completable()` played until a single card is left to move, which wins the game.
    static func oneMoveFromWinning(drawMode: DrawMode = .one) throws -> Game {
        var game = completable(drawMode: drawMode)
        for _ in 1 ..< completableRemainingCardCount {
            try game.perform(XCTUnwrap(game.nextAutoCompleteMove()))
        }
        return game
    }

    /// `completable()` played to the end.
    static func won() throws -> Game {
        var game = try oneMoveFromWinning()
        try game.perform(XCTUnwrap(game.nextAutoCompleteMove()))
        return game
    }
}

/// Records the haptics a view model plays.
@MainActor
final class HapticsSpy: HapticPlayer {
    private(set) var played: [HapticEvent] = []
    func play(_ event: HapticEvent) { played.append(event) }
}

/// Records the sounds a view model plays.
@MainActor
final class SoundsSpy: SoundPlayer {
    private(set) var played: [SoundEffect] = []
    func play(_ effect: SoundEffect) { played.append(effect) }
}
