extension GameState {
    /// A position built from explicit piles, for test and UI-test fixtures. Missing foundations and
    /// tableau columns are empty. Returns nil when legal play could not reach the position
    /// (see `isValidPosition`).
    public static func position(
        stock: [Card] = [],
        waste: [Card] = [],
        foundations: [[Card]] = [],
        tableau: [[Card]] = [],
        drawMode: DrawMode = .one,
        scoringMode: ScoringMode = .none,
        score: Int = 0,
        moveCount: Int = 0
    ) -> GameState? {
        guard foundations.count <= foundationCount, tableau.count <= tableauColumnCount else { return nil }
        let state = GameState(
            stock: stock,
            waste: waste,
            foundations: foundations + Array(repeating: [], count: foundationCount - foundations.count),
            tableau: tableau + Array(repeating: [], count: tableauColumnCount - tableau.count),
            drawMode: drawMode,
            seed: 0,
            moveCount: moveCount,
            scoringMode: scoringMode,
            score: score,
            recycleCount: 0
        )
        return state.isValidPosition ? state : nil
    }
}
