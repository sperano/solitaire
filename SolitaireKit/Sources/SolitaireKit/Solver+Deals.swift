public extension Solver {
    /// The first of `seeds` whose deal, in the given modes, the solver wins. Nil when none does, or
    /// when `isCancelled` stops the search. `carriedBalance` only matters for the Vegas balance the
    /// deal starts from; the solver ignores the score.
    func firstWinnableDeal(
        seeds: some Sequence<UInt64>, drawMode: DrawMode, scoringMode: ScoringMode, carriedBalance: Int = 0,
        isCancelled: () -> Bool = { false }
    ) -> GameState? {
        for seed in seeds {
            if isCancelled() { return nil }
            let candidate = GameState.deal(
                seed: seed, drawMode: drawMode, scoringMode: scoringMode, carriedBalance: carriedBalance
            )
            if case .solved = solve(candidate, isCancelled: isCancelled).outcome { return candidate }
        }
        return nil
    }
}
