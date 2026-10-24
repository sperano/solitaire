import XCTest
@testable import SolitaireKit

final class SolverTests: XCTestCase {
    /// Seed 1 is won in both draw modes, seed 18 is rejected in draw 3 after a few dozen positions,
    /// and seed 4 runs out of budget in both modes (measured over seeds 1 to 40; see the wiki).
    static let solvableSeed: UInt64 = 1
    static let rejectedSeed: UInt64 = 18
    static let rejectedDrawMode = DrawMode.three
    static let hardSeed: UInt64 = 4
    /// The seeds the figures above were measured on.
    static let measuredSeeds: ClosedRange<UInt64> = 1 ... 40
    private static let tinyBudget = 10
    /// A search this small must come back at once, even in a debug build.
    private static let tinyBudgetTimeLimit: TimeInterval = 1

    // MARK: Hand-built positions

    /// Clubs and diamonds done; the king to seven of hearts on top of the seven columns with the
    /// rest of hearts and all spades face down beneath them, no stock: no move at all.
    static func deadlocked() -> GameState {
        let tops = Rank.allCases.filter { $0 >= .seven }.reversed().map { card($0, .hearts) }
        var hidden = (Rank.allCases.filter { $0 < .seven }.map { card($0, .hearts, up: false) }
            + Rank.allCases.map { card($0, .spades, up: false) }).makeIterator()
        let tableau = tops.enumerated().map { column, top in (0 ..< column).compactMap { _ in hidden.next() } + [top] }
        let state = GameState.position(foundations: [fullSuit(.clubs), fullSuit(.diamonds)], tableau: tableau)
        return state!
    }

    func testDeadlockedPositionHasNoSolution() {
        let state = Self.deadlocked()
        XCTAssertEqual(state.availableMoves(), [], "the fixture must offer no move")

        let report = Solver().solve(state)

        XCTAssertEqual(report.outcome, .noSolution)
        XCTAssertEqual(report.nodes, 1, "only the root is expanded")
    }

    func testWonPositionIsSolvedWithNoMoves() {
        let won = blankState(foundations: Suit.allCases.map(fullSuit))
        XCTAssertEqual(Solver().solve(won), Solver.Report(outcome: .solved([]), nodes: 0))
    }

    func testCompletablePositionIsSolvedByFoundationMoves() throws {
        // Clubs and diamonds done, hearts and spades up to the six, the rest in two alternating runs.
        let remaining = Rank.allCases.filter { $0 >= .seven }.reversed()
        let run = { (first: Suit, second: Suit) in
            remaining.enumerated().map { card($1, $0.isMultiple(of: 2) ? first : second) }
        }
        let partial = Rank.allCases.filter { $0 < .seven }
        let state = try XCTUnwrap(GameState.position(
            foundations: [
                fullSuit(.clubs),
                fullSuit(.diamonds),
                partial.map { card($0, .hearts) },
                partial.map { card($0, .spades) },
            ],
            tableau: [run(.spades, .hearts), run(.hearts, .spades)]
        ))

        let report = Solver().solve(state)

        guard case let .solved(moves) = report.outcome else { return XCTFail("\(report.outcome)") }
        XCTAssertEqual(moves.count, 2 * remaining.count)
        XCTAssertTrue(moves.allSatisfy { if case let .move(_, to, 1) = $0 { to.isFoundation } else { false } })
    }

    // MARK: Deals

    func testKnownSolvableSeedIsSolvedAndTheSolutionWins() throws {
        var state = GameState.deal(seed: Self.solvableSeed, drawMode: .one)
        let report = Solver().solve(state)

        guard case let .solved(moves) = report.outcome else { return XCTFail("\(report.outcome)") }
        for move in moves { try state.apply(move) }
        XCTAssertTrue(state.isWon)
        XCTAssertLessThanOrEqual(report.nodes, Solver.defaultNodeBudget)
    }

    /// Vegas allows three passes in draw 3; a solution found under that rule replays within it.
    func testSolutionRespectsVegasPassLimit() throws {
        let found = Solver().firstWinnableDeal(seeds: Self.measuredSeeds, drawMode: .three, scoringMode: .vegas)
        var state = try XCTUnwrap(found, "some measured seed is winnable within three passes")
        guard case let .solved(moves) = Solver().solve(state).outcome
        else { return XCTFail("found but not solved again") }

        for move in moves { try state.apply(move) }
        XCTAssertTrue(state.isWon)
        XCTAssertLessThanOrEqual(state.recycleCount, Scoring.vegasDrawThreePasses - 1)
    }

    func testKnownRejectedSeedHasNoSolution() {
        let report = Solver().solve(.deal(seed: Self.rejectedSeed, drawMode: Self.rejectedDrawMode))
        XCTAssertEqual(report.outcome, .noSolution)
        XCTAssertLessThan(report.nodes, Solver.defaultNodeBudget)
    }

    func testTheSolutionIsFoundInBothDrawModes() throws {
        for mode in DrawMode.allCases {
            var state = GameState.deal(seed: Self.solvableSeed, drawMode: mode)
            guard case let .solved(moves) = Solver().solve(state).outcome else { return XCTFail("\(mode)") }
            for move in moves { try state.apply(move) }
            XCTAssertTrue(state.isWon, "\(mode)")
        }
    }

    // MARK: Budget and cancellation

    func testBudgetBoundsTheNodesAndTheRunningTime() {
        let solver = Solver(nodeBudget: Self.tinyBudget)
        let start = Date()

        let report = solver.solve(.deal(seed: Self.hardSeed, drawMode: .one))

        XCTAssertLessThan(Date().timeIntervalSince(start), Self.tinyBudgetTimeLimit)
        XCTAssertEqual(report.nodes, Self.tinyBudget)
        XCTAssertEqual(report.outcome, .undecided)
    }

    func testCancellationStopsBeforeTheFirstPosition() {
        let report = Solver().solve(.deal(seed: Self.solvableSeed, drawMode: .one)) { true }
        XCTAssertEqual(report, Solver.Report(outcome: .undecided, nodes: 0))
    }

    func testCancellationMidwayReportsUndecided() {
        var calls = 0
        let report = Solver().solve(.deal(seed: Self.solvableSeed, drawMode: .one)) {
            calls += 1
            return calls > Self.tinyBudget
        }
        XCTAssertEqual(report.outcome, .undecided)
        XCTAssertEqual(report.nodes, Self.tinyBudget)
    }
}
