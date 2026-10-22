/// Win and loss counts per draw mode and overall. Overall streaks are tracked on their own,
/// since they cannot be rebuilt from the per-mode records.
public struct GameStatistics: Hashable, Codable, Sendable {
    public internal(set) var overall = StatisticsRecord()
    public internal(set) var drawOne = StatisticsRecord()
    public internal(set) var drawThree = StatisticsRecord()

    public init() {}

    public subscript(drawMode: DrawMode) -> StatisticsRecord {
        switch drawMode {
        case .one: drawOne
        case .three: drawThree
        }
    }

    public mutating func recordWin(drawMode: DrawMode, seconds: Int, moves: Int) {
        overall.recordWin(seconds: seconds, moves: moves)
        update(drawMode) { $0.recordWin(seconds: seconds, moves: moves) }
    }

    public mutating func recordLoss(drawMode: DrawMode) {
        overall.recordLoss()
        update(drawMode) { $0.recordLoss() }
    }

    /// Every record is valid and the overall counts are the sums of the per-mode ones.
    public var isValid: Bool {
        [overall, drawOne, drawThree].allSatisfy(\.isValid)
            && overall.played == drawOne.played + drawThree.played
            && overall.won == drawOne.won + drawThree.won
    }

    private mutating func update(_ drawMode: DrawMode, _ change: (inout StatisticsRecord) -> Void) {
        switch drawMode {
        case .one: change(&drawOne)
        case .three: change(&drawThree)
        }
    }
}

extension GameStatistics {
    enum CodingKeys: String, CodingKey {
        case overall, drawOne, drawThree
    }

    /// Decodes saved statistics and rejects counts that recording results could not produce.
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        overall = try container.decode(StatisticsRecord.self, forKey: .overall)
        drawOne = try container.decode(StatisticsRecord.self, forKey: .drawOne)
        drawThree = try container.decode(StatisticsRecord.self, forKey: .drawThree)
        guard isValid else {
            throw DecodingError.dataCorrupted(.init(
                codingPath: decoder.codingPath, debugDescription: "statistics are inconsistent"
            ))
        }
    }
}
