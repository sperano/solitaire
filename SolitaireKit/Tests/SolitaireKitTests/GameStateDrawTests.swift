import XCTest
@testable import SolitaireKit

final class GameStateDrawTests: XCTestCase {
    private let first = card(.five, .hearts)
    private let second = card(.six, .hearts)
    private let third = card(.seven, .hearts)

    private func dealt(_ mode: DrawMode) -> GameState {
        GameState.deal(deck: orderedDeck(stockTop: [first, second, third]), drawMode: mode)
    }

    func testDrawOneMovesOneCardFaceUp() throws {
        var state = dealt(.one)
        try state.apply(.draw)
        XCTAssertEqual(state.waste, [first])
        XCTAssertEqual(state.stock.count, stockCardCount - 1)
    }

    func testDrawThreeReversesOrderOntoWaste() throws {
        var state = dealt(.three)
        try state.apply(.draw)
        XCTAssertEqual(state.waste, [first, second, third])
        XCTAssertEqual(state.waste.last, third)
        XCTAssertEqual(state.stock.count, stockCardCount - DrawMode.three.cardsPerDraw)
        XCTAssertTrue(state.waste.allSatisfy(\.isFaceUp))
    }

    func testDrawWithFewerThanThreeMovesRemainder() throws {
        var state = dealt(.three)
        state.stock = Array(state.stock.prefix(2))
        let remaining = state.stock
        try state.apply(.draw)
        XCTAssertTrue(state.stock.isEmpty)
        XCTAssertEqual(state.waste.map(\.id), remaining.reversed().map(\.id))
    }

    func testEmptyStockRecyclesWasteFaceDown() throws {
        var state = dealt(.one)
        for _ in 0 ..< stockCardCount { try state.apply(.draw) }
        XCTAssertTrue(state.stock.isEmpty)
        XCTAssertEqual(state.waste.count, stockCardCount)
        try state.apply(.draw)
        XCTAssertTrue(state.waste.isEmpty)
        XCTAssertEqual(state.stock.count, stockCardCount)
        XCTAssertTrue(state.stock.allSatisfy { !$0.isFaceUp })
        try state.apply(.draw)
        XCTAssertEqual(state.waste, [first])
    }

    func testRecycleThreeModeReproducesFirstPass() throws {
        var state = dealt(.three)
        try state.apply(.draw)
        let firstPass = state.waste
        let draws = stockCardCount / DrawMode.three.cardsPerDraw
        for _ in 1 ..< draws { try state.apply(.draw) }
        try state.apply(.draw)
        try state.apply(.draw)
        XCTAssertEqual(state.waste, firstPass)
    }

    func testDrawWithNothingThrows() {
        let state = blankState()
        assertThrows(.nothingToDraw, state, .draw)
    }

    func testMoveCountIncrementsOnSuccessOnly() throws {
        var state = dealt(.one)
        try state.apply(.draw)
        try state.apply(.draw)
        XCTAssertEqual(state.moveCount, 2)
        var empty = blankState()
        XCTAssertThrowsError(try empty.apply(.draw))
        XCTAssertEqual(empty.moveCount, 0)
    }

    func testRecycleCountsAsMove() throws {
        var state = blankState(waste: [first])
        try state.apply(.draw)
        XCTAssertEqual(state.moveCount, 1)
    }

    func testCanApplyDoesNotMutate() {
        let state = dealt(.one)
        let snapshot = state
        XCTAssertTrue(state.canApply(.draw))
        XCTAssertEqual(state, snapshot)
        XCTAssertFalse(blankState().canApply(.draw))
    }
}
