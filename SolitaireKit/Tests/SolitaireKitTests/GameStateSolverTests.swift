import XCTest
@testable import SolitaireKit

final class GameStateSolverTests: XCTestCase {
    private static let seeds: ClosedRange<UInt64> = 1 ... 30

    func testCandidatesAreLegalMovesAndNeverLeaveAFoundation() {
        for seed in Self.seeds {
            var state = GameState.deal(seed: seed, drawMode: .three)
            // A few draws and foundation moves so there is something on the foundations.
            for _ in 0 ..< 5 { try? state.apply(.draw) }
            for move in state.availableMoves() where move != .draw {
                if case .move(_, let to, _) = move, to.isFoundation { try? state.apply(move) }
            }
            for move in state.solverCandidates() {
                XCTAssertTrue(state.canApply(move), "seed \(seed): \(move)")
                if case .move(let from, _, _) = move { XCTAssertFalse(from.isFoundation, "seed \(seed): \(move)") }
            }
        }
    }

    func testAnAceOnTopIsTheOnlyCandidate() {
        // The ace of spades on top of the waste; the stock still has cards to draw.
        let stock = [card(.king, .clubs, up: false), card(.queen, .clubs, up: false)]
        let state = blankState(tableau: [[card(.five, .hearts)], [card(.six, .spades)]], stock: stock, waste: [card(.ace, .spades)])

        XCTAssertEqual(state.solverCandidates(), [.move(from: .waste, to: .foundation(0), count: 1)])
    }

    func testAFoundationMoveThatCouldStillBeNeededInTheTableauIsNotPlayedAlone() {
        // The seven of hearts could go up, but the black sixes are not on their foundations yet.
        let foundations = [Rank.allCases.filter { $0 <= .six }.map { card($0, .hearts) }]
        let state = blankState(
            tableau: [[card(.eight, .spades)]], stock: [card(.king, .clubs, up: false)], waste: [card(.seven, .hearts)],
            foundations: foundations
        )

        let candidates = state.solverCandidates()
        XCTAssertTrue(candidates.contains(.move(from: .waste, to: .foundation(0), count: 1)))
        XCTAssertTrue(candidates.contains(.move(from: .waste, to: .tableau(0), count: 1)))
        XCTAssertTrue(candidates.contains(.draw))
    }

    func testEmptyingAColumnIsOnlyTriedWhenAKingWaits() {
        let column = [card(.nine, .hearts), card(.eight, .spades)]
        let target = [card(.ten, .clubs)]
        let waiting = blankState(tableau: [column, target], waste: [card(.king, .diamonds)])
        let idle = blankState(tableau: [column, target], waste: [card(.two, .diamonds)])
        let emptying = Move.move(from: .tableau(0), to: .tableau(1), count: column.count)

        XCTAssertTrue(waiting.solverCandidates().contains(emptying))
        XCTAssertFalse(idle.solverCandidates().contains(emptying))
    }

    func testKeyIgnoresWhichColumnHoldsAPileAndTheMoveCount() throws {
        var state = GameState.deal(seed: 1, drawMode: .one)
        var swapped = state
        swapped.tableau.swapAt(0, 6)
        XCTAssertEqual(state.solverKey, swapped.solverKey)

        try state.apply(.draw)
        XCTAssertNotEqual(state.solverKey, swapped.solverKey, "the waste changed")
    }

    func testKeyTellsAFaceDownCardFromAFaceUpOne() {
        let down = blankState(tableau: [[card(.five, .hearts, up: false), card(.four, .spades)]])
        let up = blankState(tableau: [[card(.five, .hearts), card(.four, .spades)]])
        XCTAssertNotEqual(down.solverKey, up.solverKey)
    }

    func testKeyCountsRecyclesOnlyUnderAPassLimit() throws {
        var standard = GameState.deal(seed: 1, drawMode: .one, scoringMode: .standard)
        var vegas = GameState.deal(seed: 1, drawMode: .three, scoringMode: .vegas)
        let standardKey = standard.solverKey
        let vegasKey = vegas.solverKey
        // Go once round the stock: the waste ends up as it started, only the recycle count differs.
        for state in [standard, vegas] where state.remainingRecycles == 0 { throw XCTSkip("needs a pass to spare") }
        while !standard.stock.isEmpty { try standard.apply(.draw) }
        try standard.apply(.draw)
        while !vegas.stock.isEmpty { try vegas.apply(.draw) }
        try vegas.apply(.draw)

        XCTAssertEqual(standard.solverKey, standardKey)
        XCTAssertNotEqual(vegas.solverKey, vegasKey)
    }
}
