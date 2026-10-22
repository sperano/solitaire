extension GameState {
    enum CodingKeys: String, CodingKey {
        case stock, waste, foundations, tableau, drawMode, seed, moveCount, scoringMode, score, recycleCount
    }

    /// Decodes a saved position and rejects one that could not come from a real deal,
    /// so a corrupt save is discarded instead of crashing the board. Saves from before
    /// scoring existed have none of the scoring fields and load as unscored games; a save
    /// with only some of them is corrupt.
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let scoring = try Self.decodeScoring(from: container)
        self.init(
            stock: try container.decode([Card].self, forKey: .stock),
            waste: try container.decode([Card].self, forKey: .waste),
            foundations: try container.decode([[Card]].self, forKey: .foundations),
            tableau: try container.decode([[Card]].self, forKey: .tableau),
            drawMode: try container.decode(DrawMode.self, forKey: .drawMode),
            seed: try container.decode(UInt64.self, forKey: .seed),
            moveCount: try container.decode(Int.self, forKey: .moveCount),
            scoringMode: scoring.mode,
            score: scoring.score,
            recycleCount: scoring.recycleCount
        )
        guard isValidPosition else {
            throw DecodingError.dataCorrupted(.init(
                codingPath: decoder.codingPath,
                debugDescription: "saved game is not a position legal play can reach"
            ))
        }
    }

    private static let scoringKeys: [CodingKeys] = [.scoringMode, .score, .recycleCount]

    /// All three scoring fields, or the unscored defaults when a pre-scoring save has none of them.
    private static func decodeScoring(
        from container: KeyedDecodingContainer<CodingKeys>
    ) throws -> (mode: ScoringMode, score: Int, recycleCount: Int) {
        guard scoringKeys.contains(where: container.contains) else { return (.none, 0, 0) }
        return (
            try container.decode(ScoringMode.self, forKey: .scoringMode),
            try container.decode(Int.self, forKey: .score),
            try container.decode(Int.self, forKey: .recycleCount)
        )
    }
}
