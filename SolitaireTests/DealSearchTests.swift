import SolitaireKit
import XCTest
@testable import Solitaire

/// Main-actor isolated: the Swift 6.3 compiler on CI cannot check a `@concurrent` call from a
/// nonisolated async test ("pattern that the region-based isolation checker does not understand").
@MainActor
final class DealSearchTests: XCTestCase {
    /// Seed 1 is won in both draw modes and seed 18 is rejected in draw 3 (see `SolverTests` in the engine package).
    static let solvableSeed: UInt64 = 1
    static let rejectedSeed: UInt64 = 18
    static let rejectedDrawMode = DrawMode.three
    private static let tinyBudget = 1

    func testAWinnableFirstDealIsReturnedAsItIs() async {
        let found = await DealSearch.winnableDeal(
            startingWith: Self.solvableSeed, drawMode: .one, scoringMode: .standard, carriedBalance: 0
        )
        XCTAssertEqual(found?.seed, Self.solvableSeed)
        XCTAssertEqual(found?.scoringMode, .standard)
    }

    func testARejectedFirstDealIsReplacedByAnotherNumberInRange() async {
        let found = await DealSearch.winnableDeal(
            startingWith: Self.rejectedSeed, drawMode: Self.rejectedDrawMode, scoringMode: .none, carriedBalance: 0
        )
        let seed = try? XCTUnwrap(found?.seed)
        XCTAssertNotEqual(seed, Self.rejectedSeed)
        XCTAssertTrue(GameState.dealNumberRange.contains(seed ?? 0))
    }

    func testWhenEveryAttemptRunsOutOfBudgetTheLastDealIsPlayedAnyway() async {
        let found = await DealSearch.winnableDeal(
            startingWith: Self.rejectedSeed, drawMode: .one, scoringMode: .none, carriedBalance: 0,
            solver: Solver(nodeBudget: Self.tinyBudget)
        )
        XCTAssertNotNil(found)
        XCTAssertEqual(found?.drawMode, .one)
    }

    func testACancelledSearchReturnsNil() async {
        let task = Task {
            await DealSearch.winnableDeal(startingWith: Self.rejectedSeed, drawMode: .three, scoringMode: .none, carriedBalance: 0)
        }
        task.cancel()
        let found = await task.value
        XCTAssertNil(found)
    }
}
