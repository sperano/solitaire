extension GameState {
    enum CodingKeys: String, CodingKey {
        case stock, waste, foundations, tableau, drawMode, seed, moveCount, scoringMode, score, recycleCount
    }

    /// Decodes a saved position and rejects one that could not come from a real deal,
    /// so a corrupt save is discarded instead of crashing the board. Saves from before
    /// scoring existed have no scoring fields and load as unscored games.
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            stock: try container.decode([Card].self, forKey: .stock),
            waste: try container.decode([Card].self, forKey: .waste),
            foundations: try container.decode([[Card]].self, forKey: .foundations),
            tableau: try container.decode([[Card]].self, forKey: .tableau),
            drawMode: try container.decode(DrawMode.self, forKey: .drawMode),
            seed: try container.decode(UInt64.self, forKey: .seed),
            moveCount: try container.decode(Int.self, forKey: .moveCount),
            scoringMode: try container.decodeIfPresent(ScoringMode.self, forKey: .scoringMode) ?? .none,
            score: try container.decodeIfPresent(Int.self, forKey: .score) ?? 0,
            recycleCount: try container.decodeIfPresent(Int.self, forKey: .recycleCount) ?? 0
        )
        guard isValidPosition else {
            throw DecodingError.dataCorrupted(.init(
                codingPath: decoder.codingPath,
                debugDescription: "saved game is not a position legal play can reach"
            ))
        }
    }
}
