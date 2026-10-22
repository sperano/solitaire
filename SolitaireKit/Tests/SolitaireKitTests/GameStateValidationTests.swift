import XCTest
@testable import SolitaireKit

final class GameStateValidationTests: XCTestCase {
    private let seed: UInt64 = 3

    private var dealt: GameState { .deal(seed: seed, drawMode: .three) }

    /// A legal mid-game position reached by real moves.
    private func played() throws -> GameState {
        var state = dealt
        try state.apply(.draw)
        try state.apply(.draw)
        return state
    }

    // MARK: Structure

    func testDealtStateIsStructurallyValid() {
        XCTAssertTrue(dealt.isStructurallyValid)
    }

    func testStateWithDuplicateOrMissingCardsIsInvalid() {
        XCTAssertFalse(blankState(tableau: [[card(.ace, .spades)]]).isStructurallyValid)
    }

    // MARK: Position

    func testDealtAndPlayedStatesAreValidPositions() throws {
        XCTAssertTrue(dealt.isValidPosition)
        XCTAssertTrue(try played().isValidPosition)
    }

    func testNegativeOrMaximalMoveCountIsInvalid() {
        var state = dealt
        state.moveCount = -1
        XCTAssertFalse(state.isValidPosition)
        state.moveCount = .max
        XCTAssertFalse(state.isValidPosition, "the next move would overflow")
    }

    func testFaceUpStockCardIsInvalid() {
        var state = dealt
        state.stock[0] = state.stock[0].faceUp()
        XCTAssertFalse(state.isValidPosition)
    }

    func testFaceDownWasteCardIsInvalid() throws {
        var state = try played()
        state.waste[0] = state.waste[0].faceDown()
        XCTAssertFalse(state.isValidPosition)
    }

    func testFaceDownTableauTopIsInvalid() {
        var state = dealt
        let column = GameState.tableauColumnCount - 1
        state.tableau[column][state.tableau[column].count - 1] = state.tableau[column].last!.faceDown()
        XCTAssertFalse(state.isValidPosition)
    }

    // MARK: Foundations

    func testFoundationMustStartWithAnAceAndFollowSuit() {
        XCTAssertTrue(GameState.isValidFoundation([]))
        XCTAssertTrue(GameState.isValidFoundation(Array(fullSuit(.hearts).prefix(3))))
        XCTAssertFalse(GameState.isValidFoundation([card(.two, .hearts)]))
        XCTAssertFalse(GameState.isValidFoundation([card(.ace, .hearts), card(.two, .spades)]))
        XCTAssertFalse(GameState.isValidFoundation([card(.ace, .hearts), card(.three, .hearts)]))
        XCTAssertFalse(GameState.isValidFoundation([card(.ace, .hearts, up: false)]))
    }

    // MARK: Tableau

    func testTableauColumnNeedsFaceDownCardsUnderAFaceUpRun() {
        XCTAssertTrue(GameState.isValidTableauColumn([]))
        XCTAssertTrue(GameState.isValidTableauColumn([
            card(.two, .clubs, up: false), card(.nine, .spades), card(.eight, .hearts),
        ]))
        XCTAssertFalse(GameState.isValidTableauColumn([card(.nine, .spades, up: false)]), "top must be face up")
        XCTAssertFalse(GameState.isValidTableauColumn([
            card(.nine, .spades), card(.two, .clubs, up: false), card(.eight, .hearts),
        ]), "face-down card above a face-up one")
        XCTAssertFalse(GameState.isValidTableauColumn([card(.nine, .spades), card(.eight, .clubs)]), "same colour run")
    }

    // MARK: Pile sizes

    func testAllCardsInTheStockIsInvalid() {
        var state = dealt
        state.stock = Deck.standard()
        state.tableau = Array(repeating: [], count: GameState.tableauColumnCount)
        XCTAssertTrue(state.isStructurallyValid, "every card is still present exactly once")
        XCTAssertFalse(state.isValidPosition)
    }

    func testMoreFaceDownCardsThanTheDealGaveIsInvalid() {
        var state = dealt
        let moved = state.tableau[GameState.tableauColumnCount - 1].removeFirst()
        state.tableau[0].insert(moved, at: 0)
        XCTAssertFalse(state.isValidPosition, "column 0 is dealt no face-down card")
    }
}
