import XCTest
@testable import SolitaireKit

final class SolverDealsTests: XCTestCase {
    func testReturnsTheFirstWinnableDealInTheRequestedModes() {
        let seeds = [SolverTests.rejectedSeed, SolverTests.solvableSeed, SolverTests.solvableSeed + 1]
        let found = Solver().firstWinnableDeal(
            seeds: seeds,
            drawMode: SolverTests.rejectedDrawMode,
            scoringMode: .standard
        )

        XCTAssertEqual(found?.seed, SolverTests.solvableSeed)
        XCTAssertEqual(found?.drawMode, SolverTests.rejectedDrawMode)
        XCTAssertEqual(found?.scoringMode, .standard)
    }

    func testCarriedBalanceReachesTheDeal() {
        let found = Solver().firstWinnableDeal(
            seeds: SolverTests.measuredSeeds, drawMode: .three, scoringMode: .vegas, carriedBalance: 100
        )
        XCTAssertEqual(found?.score, 100 - Scoring.vegasBuyIn)
        XCTAssertEqual(found?.scoringMode, .vegas)
    }

    func testNilWhenNoSeedIsWinnableOrNoneIsGiven() {
        let solver = Solver()
        XCTAssertNil(solver.firstWinnableDeal(
            seeds: [SolverTests.rejectedSeed],
            drawMode: SolverTests.rejectedDrawMode,
            scoringMode: .none
        ))
        XCTAssertNil(solver.firstWinnableDeal(seeds: [UInt64](), drawMode: .one, scoringMode: .none))
    }

    func testCancellationStopsTheSearchBeforeTheFirstDeal() {
        var solves = 0
        let found = Solver().firstWinnableDeal(seeds: [SolverTests.solvableSeed], drawMode: .one, scoringMode: .none) {
            solves += 1
            return true
        }
        XCTAssertNil(found)
        XCTAssertEqual(solves, 1)
    }
}
