import XCTest
@testable import SolitaireKit

final class GameStateHintsTests: XCTestCase {
    private static let seeds: [UInt64] = [1, 7, 42, 1_234]
    private static let playedMoves = 30
    private static let allPiles: [PileID] = [.stock, .waste] + PileID.allFoundations + PileID.allTableau

    /// Every move the engine accepts, found by trying every source, destination and count.
    private func bruteForceMoves(_ state: GameState) -> Set<Move> {
        var moves: Set<Move> = state.canApply(.draw) ? [.draw] : []
        for from in Self.allPiles {
            for to in Self.allPiles {
                for count in 1 ... Rank.allCases.count {
                    let move = Move.move(from: from, to: to, count: count)
                    if state.canApply(move) { moves.insert(move) }
                }
            }
        }
        return moves
    }

    private func assertAvailableMovesAreExactlyTheLegalOnes(
        _ state: GameState,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let available = state.availableMoves()
        XCTAssertEqual(Set(available), bruteForceMoves(state), file: file, line: line)
        XCTAssertEqual(available.count, Set(available).count, "no move is listed twice", file: file, line: line)
    }

    // MARK: availableMoves

    func testAvailableMovesOfDealsAreExactlyTheLegalMoves() {
        for seed in Self.seeds {
            for drawMode in DrawMode.allCases {
                assertAvailableMovesAreExactlyTheLegalOnes(.deal(seed: seed, drawMode: drawMode))
            }
        }
    }

    /// Plays the suggested move, or the last available one, to reach varied mid-game positions.
    func testAvailableMovesStayExactThroughPlay() throws {
        for seed in Self.seeds {
            var state = GameState.deal(seed: seed, drawMode: .three, scoringMode: .vegas)
            for _ in 0 ..< Self.playedMoves {
                assertAvailableMovesAreExactlyTheLegalOnes(state)
                guard let move = state.suggestedMove() ?? state.availableMoves().last else { break }
                try state.apply(move)
            }
        }
    }

    func testDrawComesFirst() {
        XCTAssertEqual(GameState.deal(seed: 1, drawMode: .one).availableMoves().first, .draw)
    }

    func testNoMovesOnABlockedBoard() {
        let state = blankState(tableau: [[card(.two, .clubs)]])
        XCTAssertEqual(state.availableMoves(), [])
        XCTAssertNil(state.suggestedMove())
    }

    func testWholeAndPartialRunsAreListed() {
        let state = blankState(tableau: [
            [card(.nine, .clubs, up: false), card(.eight, .hearts), card(.seven, .spades)],
            [card(.nine, .spades)], [card(.eight, .diamonds)],
        ])
        let moves = state.availableMoves()
        XCTAssertTrue(moves.contains(.move(from: .tableau(0), to: .tableau(1), count: 2)))
        XCTAssertTrue(moves.contains(.move(from: .tableau(0), to: .tableau(2), count: 1)))
    }

    // MARK: suggestedMove

    func testFoundationMoveComesFirst() {
        let state = blankState(
            tableau: [
                [card(.nine, .clubs, up: false), card(.seven, .hearts)],
                [card(.eight, .spades)],
                [card(.ace, .diamonds)],
            ],
            stock: [card(.king, .clubs, up: false)],
            waste: [card(.seven, .diamonds)]
        )
        XCTAssertEqual(state.suggestedMove(), .move(from: .tableau(2), to: .foundation(0), count: 1))
    }

    func testWasteCardToAFoundationIsSuggested() {
        let state = blankState(stock: [card(.king, .clubs, up: false)], waste: [card(.ace, .spades)])
        XCTAssertEqual(state.suggestedMove(), .move(from: .waste, to: .foundation(0), count: 1))
    }

    func testRunThatUncoversAFaceDownCardComesBeforeTheWaste() {
        let state = blankState(
            tableau: [
                [card(.nine, .clubs, up: false), card(.seven, .hearts)],
                [card(.eight, .spades)],
                [card(.eight, .clubs)],
            ],
            stock: [card(.king, .clubs, up: false)],
            waste: [card(.seven, .diamonds)]
        )
        XCTAssertEqual(state.suggestedMove(), .move(from: .tableau(0), to: .tableau(1), count: 1))
    }

    func testKingMovesIntoAnEmptyColumnToUncoverACard() {
        let state = blankState(tableau: [
            [card(.nine, .clubs, up: false), card(.king, .hearts), card(.queen, .spades)],
            [],
        ])
        XCTAssertEqual(state.suggestedMove(), .move(from: .tableau(0), to: .tableau(1), count: 2))
    }

    func testWasteToTableauComesBeforeTheDraw() {
        let state = blankState(
            tableau: [[card(.eight, .spades)]],
            stock: [card(.king, .clubs, up: false)],
            waste: [card(.seven, .hearts)]
        )
        XCTAssertEqual(state.suggestedMove(), .move(from: .waste, to: .tableau(0), count: 1))
    }

    func testDrawWhenNothingElseHelps() {
        let state = blankState(tableau: [[card(.two, .clubs)]], stock: [card(.king, .clubs, up: false)])
        XCTAssertEqual(state.suggestedMove(), .draw)
    }

    func testRecyclingTheWasteCountsAsADraw() {
        let state = blankState(tableau: [[card(.two, .clubs)]], waste: [card(.queen, .clubs)])
        XCTAssertEqual(state.suggestedMove(), .draw)
    }

    func testNoDrawOnceVegasPassesAreUsedUp() throws {
        var state = blankState(scoringMode: .vegas, tableau: [[card(.two, .clubs)]], waste: [card(.queen, .clubs)])
        state.recycleCount = try XCTUnwrap(Scoring.recycleLimit(mode: .vegas, drawMode: .one))
        XCTAssertFalse(state.availableMoves().contains(.draw))
        XCTAssertNil(state.suggestedMove())
    }

    func testRunShuffledBetweenColumnsIsNeverSuggested() {
        let state = blankState(tableau: [[card(.seven, .hearts)], [card(.eight, .spades)], [card(.eight, .clubs)]])
        XCTAssertFalse(state.availableMoves().isEmpty)
        XCTAssertNil(state.suggestedMove())
    }

    func testPartOfARunAboveAFaceDownCardIsNotSuggested() {
        let state = blankState(tableau: [
            [card(.nine, .clubs, up: false), card(.eight, .hearts), card(.seven, .spades)], [card(.eight, .diamonds)],
        ])
        XCTAssertTrue(state.availableMoves().contains(.move(from: .tableau(0), to: .tableau(1), count: 1)))
        XCTAssertNil(state.suggestedMove())
    }

    func testKingRunAloneInItsColumnIsNotMovedToAnotherEmptyColumn() {
        let state = blankState(tableau: [[card(.king, .hearts)], []])
        XCTAssertTrue(state.availableMoves().contains(.move(from: .tableau(0), to: .tableau(1), count: 1)))
        XCTAssertNil(state.suggestedMove())
    }

    func testCardsAreNotTakenBackOffAFoundation() {
        let state = blankState(
            tableau: [[card(.three, .hearts)]],
            foundations: [[card(.ace, .spades), card(.two, .spades)]]
        )
        XCTAssertTrue(state.availableMoves().contains(.move(from: .foundation(0), to: .tableau(0), count: 1)))
        XCTAssertNil(state.suggestedMove())
    }

    func testAceIsNotMovedBetweenFoundations() {
        let state = blankState(foundations: [[card(.ace, .spades)]])
        XCTAssertTrue(state.availableMoves().contains(.move(from: .foundation(0), to: .foundation(1), count: 1)))
        XCTAssertNil(state.suggestedMove())
    }

    func testSuggestedMoveIsAlwaysLegal() throws {
        for seed in Self.seeds {
            var state = GameState.deal(seed: seed, drawMode: .one)
            for _ in 0 ..< Self.playedMoves {
                guard let move = state.suggestedMove() else { break }
                XCTAssertTrue(state.canApply(move))
                try state.apply(move)
            }
        }
    }

    func testGameForwardsToItsState() {
        let game = Game(seed: 42, drawMode: .one)
        XCTAssertEqual(game.availableMoves(), game.state.availableMoves())
        XCTAssertEqual(game.suggestedMove(), game.state.suggestedMove())
    }
}
