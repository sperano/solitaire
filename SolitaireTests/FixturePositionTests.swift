import SolitaireKit
import XCTest
@testable import Solitaire

final class FixturePositionTests: XCTestCase {
    func testEveryFixtureIsALegalPositionInTheRequestedModes() {
        for fixture in FixturePosition.allCases {
            let state = fixture.state(drawMode: .three, scoringMode: .vegas)
            XCTAssertTrue(state.isValidPosition, fixture.rawValue)
            XCTAssertEqual(state.drawMode, .three)
            XCTAssertEqual(state.scoringMode, .vegas)
        }
    }

    func testCompletableFinishesInItsRemainingCardCount() throws {
        var game = Game(state: FixturePosition.completable.state())
        XCTAssertTrue(game.canAutoComplete)
        var moves = 0
        while let move = game.nextAutoCompleteMove() {
            try game.perform(move)
            moves += 1
        }
        XCTAssertTrue(game.isWon)
        XCTAssertEqual(moves, FixturePosition.completableRemainingCardCount)
    }

    func testOneMoveFromCompletableNeedsTheWasteCardPlayed() throws {
        var game = Game(state: FixturePosition.oneMoveFromCompletable.state())
        XCTAssertFalse(game.canAutoComplete)
        let destination = try XCTUnwrap(game.autoMoveDestination(count: 1, from: .waste))
        try game.perform(.move(from: .waste, to: destination, count: 1))
        XCTAssertTrue(game.canAutoComplete)
    }

    func testDeadlockedHasNoMoveAtAll() {
        let state = FixturePosition.deadlocked.state()
        XCTAssertEqual(state.availableMoves(), [])
        XCTAssertNil(state.suggestedMove())
        XCTAssertFalse(state.isWon)
    }
}
