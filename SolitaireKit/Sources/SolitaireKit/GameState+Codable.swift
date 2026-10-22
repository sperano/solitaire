extension GameState {
    enum CodingKeys: String, CodingKey {
        case stock, waste, foundations, tableau, drawMode, seed, moveCount
    }

    /// Decodes a saved position and rejects one that could not come from a real deal,
    /// so a corrupt save is discarded instead of crashing the board.
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            stock: try container.decode([Card].self, forKey: .stock),
            waste: try container.decode([Card].self, forKey: .waste),
            foundations: try container.decode([[Card]].self, forKey: .foundations),
            tableau: try container.decode([[Card]].self, forKey: .tableau),
            drawMode: try container.decode(DrawMode.self, forKey: .drawMode),
            seed: try container.decode(UInt64.self, forKey: .seed),
            moveCount: try container.decode(Int.self, forKey: .moveCount)
        )
        guard isValidPosition else {
            throw DecodingError.dataCorrupted(.init(
                codingPath: decoder.codingPath,
                debugDescription: "saved game is not a position legal play can reach"
            ))
        }
    }
}
