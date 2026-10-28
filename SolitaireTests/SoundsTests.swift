import SolitaireKit
import XCTest
@testable import Solitaire

/// Seed 42's tableau tops: 2♣ 8♣ Q♣ 5♥ 6♠ 5♣ A♥, the ace over six face-down cards.
@MainActor
final class SoundsTests: XCTestCase {
    private static let seed: UInt64 = 42
    private static let aceColumn = PileID.tableau(6)

    private func effects(of move: Move, in game: Game) throws -> [SoundEffect] {
        var after = game
        try after.perform(move)
        return SoundEffect.effects(from: game.state, to: after.state)
    }

    func testADrawIsHeardAsADraw() throws {
        let game = Game(seed: Self.seed, drawMode: .one)
        XCTAssertEqual(try effects(of: .draw, in: game), [.draw])
    }

    func testTurningTheWasteBackIsHeardAsADraw() throws {
        var game = Game(seed: Self.seed, drawMode: .one)
        while !game.state.pile(.stock).isEmpty { try game.perform(.draw) }
        XCTAssertEqual(try effects(of: .draw, in: game), [.draw])
    }

    func testUncoveringAFaceDownCardIsHeardAsItTurns() throws {
        let game = Game(seed: Self.seed, drawMode: .one)
        let foundation = try XCTUnwrap(game.autoMoveDestination(count: 1, from: Self.aceColumn))
        let move = Move.move(from: Self.aceColumn, to: foundation, count: 1)
        XCTAssertEqual(try effects(of: move, in: game), [.place, .flip])
    }

    func testAMoveThatUncoversNothingIsHeardAsAPlace() throws {
        let game = Game.completable()
        XCTAssertEqual(try effects(of: XCTUnwrap(game.nextAutoCompleteMove()), in: game), [.place])
    }

    func testTheWinningMoveIsHeardAsTheWin() throws {
        let game = try Game.oneMoveFromWinning()
        XCTAssertEqual(try effects(of: XCTUnwrap(game.nextAutoCompleteMove()), in: game), [.place, .win])
    }

    func testEverySoundIsInTheAppBundle() {
        let bundle = Bundle(for: GameViewModel.self)
        for effect in SoundEffect.allCases {
            XCTAssertNotNil(
                bundle.url(forResource: effect.resourceName, withExtension: SoundEffect.fileExtension), "\(effect)"
            )
        }
    }
}
