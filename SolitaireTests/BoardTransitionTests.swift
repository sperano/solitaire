import SolitaireKit
import XCTest
@testable import Solitaire

final class BoardTransitionTests: XCTestCase {
    /// Seed 42 ends column 7 with the ace of hearts.
    private let dealt = GameState.deal(seed: 42, drawMode: .one)
    private let aceColumn = PileID.tableau(6)

    private func applying(_ moves: Move..., to state: GameState) throws -> GameState {
        var next = state
        for move in moves { try next.apply(move) }
        return next
    }

    func testNothingFliesWhenNothingChanged() {
        XCTAssertEqual(BoardTransition.flights(from: dealt, to: dealt), [])
    }

    func testADrawFliesTheTopStockCardFaceDownToFaceUp() throws {
        let drawn = try applying(.draw, to: dealt)
        let flights = BoardTransition.flights(from: dealt, to: drawn)
        XCTAssertEqual(flights.count, 1)
        let flight = try XCTUnwrap(flights.first)
        XCTAssertEqual(flight.from, CardSlot(pile: .stock, index: dealt.stock.count - 1))
        XCTAssertEqual(flight.to, CardSlot(pile: .waste, index: 0))
        XCTAssertFalse(flight.before.isFaceUp)
        XCTAssertTrue(flight.after.isFaceUp)
        XCTAssertEqual(flight.id, flight.after.id)
    }

    func testAMoveFliesOnlyTheMovedCardNotTheOneItUncovers() throws {
        let moved = try applying(.move(from: aceColumn, to: .foundation(0), count: 1), to: dealt)
        let flights = BoardTransition.flights(from: dealt, to: moved)
        XCTAssertEqual(flights.map(\.after.id), ["A♥"])
        XCTAssertEqual(flights.first?.from, CardSlot(pile: aceColumn, index: GameState.tableauColumnCount - 1))
        XCTAssertEqual(flights.first?.to, CardSlot(pile: .foundation(0), index: 0))
    }

    func testUndoFliesTheCardBack() throws {
        let moved = try applying(.move(from: aceColumn, to: .foundation(0), count: 1), to: dealt)
        let flights = BoardTransition.flights(from: moved, to: dealt)
        XCTAssertEqual(flights.map(\.after.id), ["A♥"])
        XCTAssertEqual(flights.first?.to.pile, aceColumn)
    }

    func testARunFliesBottomCardFirst() throws {
        let before = FixturePosition.completable.state()
        let run = before.tableau[0].count
        let after = try applying(.move(from: .tableau(0), to: .tableau(2), count: run), to: before)
        let flights = BoardTransition.flights(from: before, to: after)
        XCTAssertEqual(flights.map(\.to.index), Array(0 ..< run))
        XCTAssertEqual(flights.map(\.from.index), Array(0 ..< run))
        XCTAssertEqual(flights.first?.after.rank, .king)
    }

    func testRecyclingFliesTheWholeWasteBack() throws {
        var state = dealt
        while !state.stock.isEmpty { try state.apply(.draw) }
        let recycled = try applying(.draw, to: state)
        let flights = BoardTransition.flights(from: state, to: recycled)
        XCTAssertEqual(flights.count, dealt.stock.count)
        XCTAssertTrue(flights.allSatisfy { $0.from.pile == .waste && $0.to.pile == .stock && !$0.after.isFaceUp })
    }

    func testCardsListsEveryCardOnce() {
        let cards = BoardTransition.cards(in: dealt)
        XCTAssertEqual(cards.count, Deck.cardCount)
        XCTAssertEqual(Set(cards.map(\.card.id)).count, Deck.cardCount)
    }
}
