import XCTest
@testable import SolitaireKit

final class GameStateDealTests: XCTestCase {
    private let seed: UInt64 = 7
    private lazy var state = GameState.deal(seed: seed, drawMode: .three)

    func testColumnSizesAscend() {
        XCTAssertEqual(state.tableau.count, GameState.tableauColumnCount)
        for (index, column) in state.tableau.enumerated() {
            XCTAssertEqual(column.count, index + 1)
        }
        XCTAssertEqual(state.tableau.map(\.count).reduce(0, +), GameState.tableauCardCount)
    }

    func testOnlyLastCardOfEachColumnIsFaceUp() {
        for column in state.tableau {
            XCTAssertTrue(column.last?.isFaceUp ?? false)
            XCTAssertTrue(column.dropLast().allSatisfy { !$0.isFaceUp })
        }
    }

    func testStockIsFaceDown() {
        XCTAssertEqual(state.stock.count, stockCardCount)
        XCTAssertEqual(stockCardCount, 24)
        XCTAssertTrue(state.stock.allSatisfy { !$0.isFaceUp })
    }

    func testWasteAndFoundationsStartEmpty() {
        XCTAssertTrue(state.waste.isEmpty)
        XCTAssertEqual(state.foundations.count, GameState.foundationCount)
        XCTAssertTrue(state.foundations.allSatisfy(\.isEmpty))
        XCTAssertEqual(state.moveCount, 0)
        XCTAssertFalse(state.isWon)
    }

    func testSeedAndDrawModePreserved() {
        XCTAssertEqual(state.seed, seed)
        XCTAssertEqual(state.drawMode, .three)
        XCTAssertEqual(GameState.deal(seed: seed, drawMode: .one).drawMode, .one)
    }

    func testFaceUpStartIsLastIndex() {
        for column in 0 ..< GameState.tableauColumnCount {
            XCTAssertEqual(state.faceUpStart(inTableau: column), state.tableau[column].count - 1)
        }
    }

    func testFaceUpStartNilForEmptyColumn() {
        XCTAssertNil(blankState().faceUpStart(inTableau: 0))
    }

    func testAllCardsAccountedForOnce() {
        let all = state.stock + state.tableau.flatMap { $0 }
        XCTAssertEqual(Set(all.map(\.id)).count, Deck.cardCount)
    }

    func testSeedDealEqualsShuffledDeckDeal() {
        let viaDeck = GameState.deal(deck: Deck.shuffled(seed: seed), seed: seed, drawMode: .three)
        XCTAssertEqual(state, viaDeck)
    }

    func testDifferentSeedsGiveDifferentDeals() {
        XCTAssertNotEqual(state, GameState.deal(seed: seed + 1, drawMode: .three))
    }

    func testCardsAreDealtFromEndOfDeck() {
        let deck = orderedDeck(tableau: [
            TableauSlot(column: 0, row: 0): card(.ace, .hearts),
            TableauSlot(column: 1, row: 0): card(.two, .clubs),
            TableauSlot(column: 1, row: 1): card(.three, .spades),
            TableauSlot(column: 6, row: 6): card(.king, .diamonds),
        ])
        let dealt = GameState.deal(deck: deck, drawMode: .one)
        XCTAssertEqual(dealt.tableau[0], [card(.ace, .hearts)])
        XCTAssertEqual(dealt.tableau[1], [card(.two, .clubs, up: false), card(.three, .spades)])
        XCTAssertEqual(dealt.tableau[6].last, card(.king, .diamonds))
    }

    func testStockOrderBottomFirstTopLast() {
        let top = [card(.five, .hearts), card(.six, .hearts)]
        let dealt = GameState.deal(deck: orderedDeck(stockTop: top), drawMode: .one)
        XCTAssertEqual(dealt.stock.last?.id, top[0].id)
        XCTAssertEqual(dealt.stock[stockCardCount - 2].id, top[1].id)
    }
}
