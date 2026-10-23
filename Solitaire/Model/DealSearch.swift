import SolitaireKit

/// Finds a deal the solver can win, off the main actor; cancelling the task stops it.
enum DealSearch {
    /// Deals tried before giving up and playing the last one unverified, so the board never waits
    /// for ever on a solver that keeps running out of budget.
    static let maxAttempts = 100

    /// Tries `first`, then random deal numbers, in the given modes. Returns the first winnable deal,
    /// the last one tried when `maxAttempts` run out, or nil when the task is cancelled.
    @concurrent
    static func winnableDeal(
        startingWith first: UInt64, drawMode: DrawMode, scoringMode: ScoringMode, carriedBalance: Int,
        solver: Solver = Solver()
    ) async -> GameState? {
        var last = first
        let seeds = sequence(first: first) { _ in
            last = UInt64.random(in: GameState.dealNumberRange)
            return last
        }
        let found = solver.firstWinnableDeal(
            seeds: seeds.prefix(maxAttempts), drawMode: drawMode, scoringMode: scoringMode,
            carriedBalance: carriedBalance, isCancelled: { Task.isCancelled }
        )
        if Task.isCancelled { return nil }
        return found ?? .deal(seed: last, drawMode: drawMode, scoringMode: scoringMode, carriedBalance: carriedBalance)
    }
}
