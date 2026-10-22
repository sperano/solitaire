import XCTest
@testable import SolitaireKit

final class GameStateMovesTests: XCTestCase {
    private func move(_ from: PileID, _ to: PileID, _ count: Int = 1) -> Move {
        .move(from: from, to: to, count: count)
    }

    func testWasteToTableauLegal() throws {
        var state = blankState(tableau: [[card(.seven, .spades)]], waste: [card(.six, .hearts)])
        try state.apply(move(.waste, .tableau(0)))
        XCTAssertTrue(state.waste.isEmpty)
        XCTAssertEqual(state.tableau[0], [card(.seven, .spades), card(.six, .hearts)])
        XCTAssertEqual(state.moveCount, 1)
    }

    func testWasteToTableauIllegal() {
        let state = blankState(tableau: [[card(.seven, .diamonds)]], waste: [card(.six, .hearts)])
        assertThrows(.illegalPlacement, state, move(.waste, .tableau(0)))
    }

    func testWasteToFoundation() throws {
        var state = blankState(waste: [card(.ace, .hearts)])
        try state.apply(move(.waste, .foundation(2)))
        XCTAssertEqual(state.foundations[2], [card(.ace, .hearts)])
        XCTAssertTrue(state.waste.isEmpty)
    }

    func testWasteToFoundationIllegal() {
        let state = blankState(waste: [card(.two, .spades)])
        assertThrows(.illegalPlacement, state, move(.waste, .foundation(0)))
    }

    func testTableauToFoundationSingleCard() throws {
        var state = blankState(tableau: [[card(.two, .spades), card(.ace, .hearts)]])
        try state.apply(move(.tableau(0), .foundation(0)))
        XCTAssertEqual(state.foundations[0], [card(.ace, .hearts)])
        XCTAssertEqual(state.tableau[0], [card(.two, .spades)])
    }

    func testTableauToFoundationRejectsMultipleCards() {
        let state = blankState(tableau: [[card(.two, .spades), card(.ace, .hearts)]])
        assertThrows(.invalidCount, state, move(.tableau(0), .foundation(0), 2))
    }

    func testFoundationToTableau() throws {
        var state = blankState(
            tableau: [[card(.three, .spades)]],
            foundations: [[card(.ace, .hearts), card(.two, .hearts)]]
        )
        try state.apply(move(.foundation(0), .tableau(0)))
        XCTAssertEqual(state.foundations[0], [card(.ace, .hearts)])
        XCTAssertEqual(state.tableau[0], [card(.three, .spades), card(.two, .hearts)])
    }

    func testMultiCardRunMoves() throws {
        var state = blankState(tableau: [
            [card(.nine, .clubs, up: false), card(.eight, .hearts), card(.seven, .spades)],
            [card(.nine, .spades)],
        ])
        try state.apply(move(.tableau(0), .tableau(1), 2))
        XCTAssertEqual(state.tableau[1], [card(.nine, .spades), card(.eight, .hearts), card(.seven, .spades)])
        XCTAssertEqual(state.tableau[0], [card(.nine, .clubs)])
    }

    func testMovingPartOfFaceUpRun() throws {
        var state = blankState(tableau: [
            [card(.nine, .clubs), card(.eight, .hearts), card(.seven, .spades)],
            [card(.eight, .diamonds)],
        ])
        try state.apply(move(.tableau(0), .tableau(1)))
        XCTAssertEqual(state.tableau[0].count, 2)
        XCTAssertEqual(state.tableau[1], [card(.eight, .diamonds), card(.seven, .spades)])
    }

    func testMovingFaceDownCardThrows() {
        let state = blankState(tableau: [
            [card(.nine, .clubs, up: false), card(.eight, .hearts)],
            [card(.ten, .hearts)],
        ])
        assertThrows(.faceDownCard, state, move(.tableau(0), .tableau(1), 2))
    }

    func testInvalidRunThrowsIllegalPlacement() {
        let state = blankState(tableau: [
            [card(.nine, .clubs), card(.eight, .spades)],
            [card(.ten, .hearts)],
        ])
        assertThrows(.illegalPlacement, state, move(.tableau(0), .tableau(1), 2))
    }

    func testStockIsIllegalSource() {
        let state = blankState(tableau: [[card(.king, .spades)]], stock: [card(.six, .hearts, up: false)])
        assertThrows(.illegalSource, state, move(.stock, .tableau(0)))
    }

    func testStockAndWasteAreIllegalDestinations() {
        let state = blankState(tableau: [[card(.king, .spades)]], waste: [card(.six, .hearts)])
        assertThrows(.illegalDestination, state, move(.tableau(0), .stock))
        assertThrows(.illegalDestination, state, move(.tableau(0), .waste))
        assertThrows(.illegalDestination, state, move(.waste, .stock))
    }

    func testSameSourceAndDestinationThrows() {
        let state = blankState(tableau: [[card(.king, .spades)]], waste: [card(.six, .hearts)])
        assertThrows(.sameDestination, state, move(.tableau(0), .tableau(0)))
        assertThrows(.sameDestination, state, move(.waste, .waste))
    }

    func testZeroOrNegativeCountThrows() {
        let state = blankState(tableau: [[card(.king, .spades)], []])
        assertThrows(.invalidCount, state, move(.tableau(0), .tableau(1), 0))
        assertThrows(.invalidCount, state, move(.tableau(0), .tableau(1), -1))
    }

    func testCountLargerThanPileThrows() {
        let state = blankState(tableau: [[card(.king, .spades)], []])
        assertThrows(.invalidCount, state, move(.tableau(0), .tableau(1), 2))
        assertThrows(.invalidCount, state, move(.tableau(1), .tableau(0)))
    }

    func testMultipleCardsFromWasteOrFoundationThrows() {
        let state = blankState(
            tableau: [[card(.king, .spades)]],
            waste: [card(.six, .hearts), card(.five, .clubs)],
            foundations: [[card(.ace, .hearts), card(.two, .hearts)]]
        )
        assertThrows(.invalidCount, state, move(.waste, .tableau(1), 2))
        assertThrows(.invalidCount, state, move(.foundation(0), .tableau(1), 2))
    }

    func testExposedCardFlipsFaceUp() throws {
        var state = blankState(tableau: [[card(.nine, .clubs, up: false), card(.ace, .hearts)]])
        try state.apply(move(.tableau(0), .foundation(0)))
        XCTAssertEqual(state.tableau[0], [card(.nine, .clubs)])
    }

    func testMovingWholeColumnLeavesItEmpty() throws {
        var state = blankState(tableau: [[card(.king, .spades), card(.queen, .hearts)], []])
        try state.apply(move(.tableau(0), .tableau(1), 2))
        XCTAssertTrue(state.tableau[0].isEmpty)
        XCTAssertNil(state.faceUpStart(inTableau: 0))
        XCTAssertEqual(state.tableau[1].count, 2)
        assertThrows(.invalidCount, state, move(.tableau(0), .tableau(2)))
    }

    func testOnlyKingGoesOnEmptyColumn() {
        let state = blankState(tableau: [[card(.queen, .hearts)], []])
        assertThrows(.illegalPlacement, state, move(.tableau(0), .tableau(1)))
    }

    func testFailedMoveLeavesStateIdentical() {
        let state = blankState(tableau: [[card(.five, .clubs)]], waste: [card(.six, .hearts)])
        var copy = state
        XCTAssertThrowsError(try copy.apply(move(.waste, .foundation(0))))
        XCTAssertEqual(copy, state)
        XCTAssertEqual(copy.moveCount, 0)
    }

    func testCanApplyDoesNotMutate() {
        let state = blankState(tableau: [[card(.seven, .spades)]], waste: [card(.six, .hearts)])
        let snapshot = state
        XCTAssertTrue(state.canApply(move(.waste, .tableau(0))))
        XCTAssertFalse(state.canApply(move(.waste, .foundation(0))))
        XCTAssertEqual(state, snapshot)
    }

    func testMoveCountIncrementsPerSuccessfulMove() throws {
        var state = blankState(tableau: [[card(.seven, .spades)]], waste: [card(.six, .hearts), card(.ace, .clubs)])
        try state.apply(move(.waste, .foundation(0)))
        try state.apply(move(.waste, .tableau(0)))
        XCTAssertEqual(state.moveCount, 2)
    }

    func testOutOfRangeSourceThrows() {
        let state = GameState.deal(seed: 0, drawMode: .one)
        assertThrows(.illegalSource, state, move(.tableau(GameState.tableauColumnCount), .tableau(0)))
        assertThrows(.illegalSource, state, move(.foundation(-1), .tableau(0)))
    }

    func testOutOfRangeDestinationThrows() {
        let state = GameState.deal(seed: 0, drawMode: .one)
        assertThrows(.illegalDestination, state, move(.tableau(0), .foundation(GameState.foundationCount)))
        assertThrows(.illegalDestination, state, move(.tableau(0), .tableau(-1)))
    }
}
