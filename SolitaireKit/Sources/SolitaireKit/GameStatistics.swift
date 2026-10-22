/// Win and loss counts per draw mode and overall. Overall streaks are tracked on their own,
/// since they cannot be rebuilt from the per-mode records.
public struct GameStatistics: Hashable, Codable, Sendable {
    public internal(set) var overall = StatisticsRecord()
    public internal(set) var drawOne = StatisticsRecord()
    public internal(set) var drawThree = StatisticsRecord()
    /// The game whose result was recorded last. Statistics and the saved game live in separate
    /// files, so a crash between the two writes can replay a result; this makes the replay a no-op.
    public internal(set) var lastRecordedGameID: UInt64?

    public init() {}

    public subscript(drawMode: DrawMode) -> StatisticsRecord {
        switch drawMode {
        case .one: drawOne
        case .three: drawThree
        }
    }

    /// Records a win for game `gameID`; ignored when that game's result is already recorded.
    public mutating func recordWin(gameID: UInt64, drawMode: DrawMode, seconds: Int, moves: Int) {
        guard claim(gameID) else { return }
        overall.recordWin(seconds: seconds, moves: moves)
        update(drawMode) { $0.recordWin(seconds: seconds, moves: moves) }
    }

    /// Records a loss for game `gameID`; ignored when that game's result is already recorded.
    public mutating func recordLoss(gameID: UInt64, drawMode: DrawMode) {
        guard claim(gameID) else { return }
        overall.recordLoss()
        update(drawMode) { $0.recordLoss() }
    }

    /// Every record is valid and the overall record agrees with the per-mode ones.
    public var isValid: Bool {
        [overall, drawOne, drawThree].allSatisfy(\.isValid)
            && Self.sum(drawOne.played, drawThree.played) == overall.played
            && Self.sum(drawOne.won, drawThree.won) == overall.won
            && overall.bestTimeSeconds == Self.lowest(drawOne.bestTimeSeconds, drawThree.bestTimeSeconds)
            && overall.fewestMoves == Self.lowest(drawOne.fewestMoves, drawThree.fewestMoves)
    }

    private mutating func claim(_ gameID: UInt64) -> Bool {
        guard gameID != lastRecordedGameID else { return false }
        lastRecordedGameID = gameID
        return true
    }

    private mutating func update(_ drawMode: DrawMode, _ change: (inout StatisticsRecord) -> Void) {
        switch drawMode {
        case .one: change(&drawOne)
        case .three: change(&drawThree)
        }
    }

    /// The sum, or nil when it would overflow.
    private static func sum(_ lhs: Int, _ rhs: Int) -> Int? {
        let (result, overflow) = lhs.addingReportingOverflow(rhs)
        return overflow ? nil : result
    }

    private static func lowest(_ lhs: Int?, _ rhs: Int?) -> Int? {
        [lhs, rhs].compactMap { $0 }.min()
    }
}

extension GameStatistics {
    enum CodingKeys: String, CodingKey {
        case overall, drawOne, drawThree, lastRecordedGameID
    }

    /// Decodes saved statistics and rejects counts that recording results could not produce.
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        overall = try container.decode(StatisticsRecord.self, forKey: .overall)
        drawOne = try container.decode(StatisticsRecord.self, forKey: .drawOne)
        drawThree = try container.decode(StatisticsRecord.self, forKey: .drawThree)
        lastRecordedGameID = try container.decodeIfPresent(UInt64.self, forKey: .lastRecordedGameID)
        guard isValid else {
            throw DecodingError.dataCorrupted(.init(
                codingPath: decoder.codingPath, debugDescription: "statistics are inconsistent"
            ))
        }
    }
}
