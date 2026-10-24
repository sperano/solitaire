import XCTest
@testable import SolitaireKit

final class GameTests: XCTestCase {
    private let seed: UInt64 = 11

    private func game(_ state: GameState) -> Game { Game(state: state) }

    func testNewGameStartsClean() {
        let game = Game(seed: seed, drawMode: .three)
        XCTAssertFalse(game.canUndo)
        XCTAssertFalse(game.isWon)
        XCTAssertEqual(game.moveCount, 0)
        XCTAssertEqual(game.drawMode, .three)
        XCTAssertEqual(game.state, GameState.deal(seed: seed, drawMode: .three))
    }

    func testPerformRecordsHistory() throws {
        var game = Game(seed: seed, drawMode: .one)
        try game.perform(.draw)
        XCTAssertTrue(game.canUndo)
        XCTAssertEqual(game.history.count, 1)
        XCTAssertEqual(game.moveCount, 1)
    }

    func testFailedPerformDoesNotRecordHistory() {
        var game = game(blankState())
        XCTAssertThrowsError(try game.perform(.draw))
        XCTAssertFalse(game.canUndo)
    }

    func testUndoRestoresExactState() throws {
        var game = Game(seed: seed, drawMode: .one)
        let before = game.state
        try game.perform(.draw)
        XCTAssertTrue(game.undo())
        XCTAssertEqual(game.state, before)
        XCTAssertFalse(game.canUndo)
    }

    func testUndoOnEmptyHistoryReturnsFalse() {
        var game = Game(seed: seed, drawMode: .one)
        XCTAssertFalse(game.undo())
    }

    func testMultipleUndos() throws {
        var game = Game(seed: seed, drawMode: .one)
        var snapshots = [game.state]
        for _ in 0 ..< 3 {
            try game.perform(.draw)
            snapshots.append(game.state)
        }
        for expected in snapshots.dropLast().reversed() {
            XCTAssertTrue(game.undo())
            XCTAssertEqual(game.state, expected)
        }
        XCTAssertFalse(game.undo())
    }

    func testUndoThenRedoRestoresTheState() throws {
        var game = Game(seed: seed, drawMode: .one)
        try game.perform(.draw)
        let afterDraw = game
        XCTAssertFalse(game.canRedo)
        XCTAssertTrue(game.undo())
        XCTAssertTrue(game.canRedo)
        XCTAssertTrue(game.redo())
        XCTAssertEqual(game.state, afterDraw.state)
        XCTAssertEqual(game.history, afterDraw.history)
        XCTAssertFalse(game.canRedo)
        XCTAssertTrue(game.canUndo)
    }

    func testRedoOnNothingUndoneReturnsFalse() throws {
        var game = Game(seed: seed, drawMode: .one)
        XCTAssertFalse(game.redo())
        try game.perform(.draw)
        XCTAssertFalse(game.redo())
        XCTAssertEqual(game.moveCount, 1)
    }

    func testRedoReplaysSeveralUndosInOrder() throws {
        var game = Game(seed: seed, drawMode: .one)
        var snapshots: [GameState] = []
        for _ in 0 ..< 3 {
            try game.perform(.draw)
            snapshots.append(game.state)
        }
        for _ in snapshots { XCTAssertTrue(game.undo()) }
        for expected in snapshots {
            XCTAssertTrue(game.redo())
            XCTAssertEqual(game.state, expected)
        }
        XCTAssertFalse(game.redo())
    }

    func testANewMoveClearsWhatCouldBeRedone() throws {
        var game = Game(seed: seed, drawMode: .one)
        try game.perform(.draw)
        try game.perform(.draw)
        XCTAssertTrue(game.undo())
        XCTAssertTrue(game.undo())
        try game.perform(.draw)
        XCTAssertFalse(game.canRedo)
        XCTAssertFalse(game.redo())
    }

    func testAFailedMoveKeepsWhatCouldBeRedone() throws {
        var game = Game(seed: seed, drawMode: .one)
        try game.perform(.draw)
        XCTAssertTrue(game.undo())
        XCTAssertThrowsError(try game.perform(.move(from: .foundation(0), to: .tableau(0), count: 1)))
        XCTAssertTrue(game.canRedo)
    }

    func testRedoRestoresTheScore() throws {
        var game = Game(state: blankState(scoringMode: .standard, waste: [card(.ace, .hearts)]))
        try game.perform(.move(from: .waste, to: .foundation(0), count: 1))
        XCTAssertTrue(game.undo())
        XCTAssertEqual(game.score, 0)
        XCTAssertTrue(game.redo())
        XCTAssertEqual(game.score, Scoring.toFoundationPoints)
    }

    func testCanMoveMatchesCanApply() {
        let game = game(blankState(tableau: [[card(.seven, .spades)]], waste: [card(.six, .hearts)]))
        XCTAssertTrue(game.canMove(count: 1, from: .waste, to: .tableau(0)))
        XCTAssertFalse(game.canMove(count: 1, from: .waste, to: .foundation(0)))
    }

    func testIsWonFalseAfterDeal() {
        XCTAssertFalse(Game(seed: seed, drawMode: .one).isWon)
    }

    func testIsWonWithFullFoundations() {
        let state = blankState(foundations: Suit.allCases.map(fullSuit))
        XCTAssertTrue(Game(state: state).isWon)
        let almost = blankState(foundations: Suit.allCases.map { Array(fullSuit($0).dropLast()) })
        XCTAssertFalse(Game(state: almost).isWon)
    }

    // MARK: Auto move

    func testAutoMovePrefersFoundationOverTableau() {
        let game = game(blankState(tableau: [[card(.ace, .hearts)], [card(.two, .spades)]]))
        XCTAssertEqual(game.autoMoveDestination(count: 1, from: .tableau(0)), .foundation(0))
    }

    func testAutoMoveFromWasteToFoundation() {
        let game = game(blankState(waste: [card(.ace, .spades)]))
        XCTAssertEqual(game.autoMoveDestination(count: 1, from: .waste), .foundation(0))
    }

    func testAutoMovePicksNonEmptyColumnOverEarlierEmptyOne() {
        let state = blankState(tableau: [
            [card(.nine, .clubs, up: false), card(.six, .hearts)], [], [card(.seven, .spades)],
        ])
        XCTAssertEqual(Game(state: state).autoMoveDestination(count: 1, from: .tableau(0)), .tableau(2))
    }

    func testAutoMoveKingGoesToEmptyColumnOtherThanSource() {
        let state = blankState(tableau: [[card(.king, .hearts)]])
        XCTAssertEqual(Game(state: state).autoMoveDestination(count: 1, from: .tableau(0)), .tableau(1))
    }

    func testAutoMoveMultiCardRunSkipsFoundation() {
        let state = blankState(tableau: [
            [card(.five, .hearts), card(.four, .clubs)], [card(.six, .spades)],
        ])
        XCTAssertEqual(Game(state: state).autoMoveDestination(count: 2, from: .tableau(0)), .tableau(1))
    }

    func testAutoMoveFromFoundationIsNil() {
        let game = game(blankState(
            tableau: [[card(.three, .spades)]],
            foundations: [[card(.ace, .hearts), card(.two, .hearts)]]
        ))
        XCTAssertNil(game.autoMoveDestination(count: 1, from: .foundation(0)))
    }

    func testAutoMoveNilWhenNothingLegal() {
        let game = game(blankState(tableau: [[card(.five, .clubs)]]))
        XCTAssertNil(game.autoMoveDestination(count: 1, from: .tableau(0)))
    }

    // MARK: Auto complete

    func testCanAutoCompleteWhenOnlyFaceUpTableauRemains() {
        let state = blankState(tableau: [[card(.two, .hearts), card(.ace, .hearts)]])
        XCTAssertTrue(Game(state: state).canAutoComplete)
    }

    func testCannotAutoCompleteWithStockWasteOrFaceDownCards() {
        let faceUp = [[card(.two, .hearts)]]
        XCTAssertFalse(Game(state: blankState(tableau: faceUp, stock: [card(.ace, .clubs, up: false)])).canAutoComplete)
        XCTAssertFalse(Game(state: blankState(tableau: faceUp, waste: [card(.ace, .clubs)])).canAutoComplete)
        XCTAssertFalse(Game(state: blankState(tableau: [[card(.two, .hearts, up: false)]])).canAutoComplete)
        XCTAssertFalse(Game(seed: seed, drawMode: .one).canAutoComplete)
    }

    func testCannotAutoCompleteOnceWon() {
        XCTAssertFalse(Game(state: blankState(foundations: Suit.allCases.map(fullSuit))).canAutoComplete)
    }

    func testNextAutoCompleteMoveFindsFoundationMove() {
        let state = blankState(tableau: [[card(.two, .hearts)], [card(.ace, .hearts)]])
        XCTAssertEqual(
            Game(state: state).nextAutoCompleteMove(),
            .move(from: .tableau(1), to: .foundation(0), count: 1)
        )
    }

    func testNextAutoCompleteMoveNilWhenNoneExists() {
        let state = blankState(tableau: [[card(.two, .hearts)]])
        XCTAssertNil(Game(state: state).nextAutoCompleteMove())
    }

    // MARK: Scoring

    func testNewGameCarriesScoringModeAndBalance() {
        let game = Game(seed: 1, drawMode: .three, scoringMode: .vegas, carriedBalance: Scoring.vegasBuyIn)
        XCTAssertEqual(game.scoringMode, .vegas)
        XCTAssertEqual(game.score, 0)
    }

    func testUndoRestoresTheScore() throws {
        var game = Game(state: blankState(scoringMode: .standard, waste: [card(.ace, .hearts)]))
        try game.perform(.move(from: .waste, to: .foundation(0), count: 1))
        XCTAssertEqual(game.score, Scoring.toFoundationPoints)
        game.undo()
        XCTAssertEqual(game.score, 0)
    }

    func testCanDrawIsFalseWhenVegasPassesAreUsedUp() {
        XCTAssertTrue(Game(state: blankState(waste: [card(.five, .clubs)])).canDraw)
        XCTAssertFalse(Game(state: blankState(scoringMode: .vegas, waste: [card(.five, .clubs)])).canDraw)
        XCTAssertFalse(Game(state: blankState()).canDraw)
    }
}
