/// The highest standard-scored wins, kept per draw mode. Vegas games are not ranked: every Vegas
/// win pays the same.
public struct BestScores: Hashable, Codable, Sendable {
    /// Wins kept for each draw mode, and shown for all of them together.
    public static let capacity = 10

    public internal(set) var drawOne: [BestScore] = []
    public internal(set) var drawThree: [BestScore] = []
    /// The game whose win was recorded last, so a result replayed after a crash is a no-op
    /// (as in `GameStatistics`).
    public internal(set) var lastRecordedGameID: UInt64?

    public init() {}

    /// Best first.
    public subscript(drawMode: DrawMode) -> [BestScore] {
        switch drawMode {
        case .one: drawOne
        case .three: drawThree
        }
    }

    /// The best of both draw modes, best first.
    public var overall: [BestScore] {
        Array((drawOne + drawThree).sorted(by: BestScore.ranksAhead).prefix(Self.capacity))
    }

    /// Ranks the win of game `gameID`; it stays only if it makes its draw mode's top ten.
    /// Ignored when that game's win is already recorded.
    public mutating func record(_ win: BestScore, gameID: UInt64) {
        guard gameID != lastRecordedGameID else { return }
        lastRecordedGameID = gameID
        switch win.drawMode {
        case .one: drawOne = Self.inserting(win, into: drawOne)
        case .three: drawThree = Self.inserting(win, into: drawThree)
        }
    }

    /// Each list holds valid wins of its own draw mode, best first, within the capacity.
    public var isValid: Bool {
        Self.isValid(drawOne, drawMode: .one) && Self.isValid(drawThree, drawMode: .three)
    }

    private static func inserting(_ win: BestScore, into list: [BestScore]) -> [BestScore] {
        let index = list.firstIndex { BestScore.ranksAhead(win, of: $0) } ?? list.endIndex
        var result = list
        result.insert(win, at: index)
        return Array(result.prefix(capacity))
    }

    private static func isValid(_ list: [BestScore], drawMode: DrawMode) -> Bool {
        list.count <= capacity
            && list.allSatisfy { $0.isValid && $0.drawMode == drawMode }
            && zip(list, list.dropFirst()).allSatisfy { !BestScore.ranksAhead($1, of: $0) }
    }
}

extension BestScores {
    enum CodingKeys: String, CodingKey {
        case drawOne, drawThree, lastRecordedGameID
    }

    /// Decodes saved best scores and rejects lists that recording wins could not produce.
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        drawOne = try container.decode([BestScore].self, forKey: .drawOne)
        drawThree = try container.decode([BestScore].self, forKey: .drawThree)
        lastRecordedGameID = try container.decodeIfPresent(UInt64.self, forKey: .lastRecordedGameID)
        guard isValid else {
            throw DecodingError.dataCorrupted(.init(
                codingPath: decoder.codingPath, debugDescription: "best scores are inconsistent"
            ))
        }
    }
}
