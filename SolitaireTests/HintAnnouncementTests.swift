import SolitaireKit
import XCTest
@testable import Solitaire

final class HintAnnouncementTests: XCTestCase {
    private func text(_ move: Move, _ state: GameState) -> String {
        HintAnnouncement.text(for: .move(move), in: state)
    }

    func testNoUsefulMove() {
        let state = FixturePosition.deadlocked.state()
        XCTAssertEqual(HintAnnouncement.text(for: .noUsefulMove, in: state), HintAnnouncement.noUsefulMove)
    }

    func testCardToAFoundation() {
        let state = FixturePosition.oneMoveFromCompletable.state()
        XCTAssertEqual(
            text(.move(from: .waste, to: .foundation(2), count: 1), state),
            "Move seven of hearts to a foundation"
        )
    }

    func testCardOntoACard() {
        let state = FixturePosition.oneMoveFromCompletable.state()
        XCTAssertEqual(
            text(.move(from: .waste, to: .tableau(0), count: 1), state),
            "Move seven of hearts to seven of spades",
            "the text names whatever card tops the destination"
        )
    }

    func testRunIntoAnEmptyColumn() {
        let state = FixturePosition.completable.state()
        XCTAssertEqual(
            text(.move(from: .tableau(0), to: .tableau(2), count: 7), state),
            "Move king of spades and the cards on it to the empty column"
        )
    }

    func testDrawAndRecycle() {
        let dealt = GameState.deal(seed: 42, drawMode: .one)
        XCTAssertEqual(text(.draw, dealt), "Draw from the stock")
        XCTAssertEqual(text(.draw, FixturePosition.oneMoveFromCompletable.state()), "Turn the waste back over")
    }

    func testCountLargerThanThePileFallsBack() {
        let state = FixturePosition.oneMoveFromCompletable.state()
        XCTAssertEqual(text(.move(from: .waste, to: .tableau(0), count: 2), state), HintAnnouncement.noUsefulMove)
    }
}
