/// One standard-scored win in the best-scores table.
public struct BestScore: Hashable, Codable, Sendable {
    /// Points, time bonus included.
    public let score: Int
    public let drawMode: DrawMode
    public let moves: Int
    /// The time the win took; nil for an untimed win.
    public let seconds: Int?
    /// The deal number, so the deal can be played again.
    public let dealNumber: UInt64
    /// When the game was won, in whole seconds since 1970: the engine has no `Date`.
    public let wonAt: Int

    public init(score: Int, drawMode: DrawMode, moves: Int, seconds: Int?, dealNumber: UInt64, wonAt: Int) {
        self.score = score
        self.drawMode = drawMode
        self.moves = moves
        self.seconds = seconds
        self.dealNumber = dealNumber
        self.wonAt = wonAt
    }

    /// Values a standard win could produce: standard scores never drop below zero.
    var isValid: Bool {
        (0 ... Scoring.scoreRange.upperBound).contains(score)
            && moves >= 0
            && seconds.map { $0 >= 0 } ?? true
    }

    /// The higher score first; between equal scores, the earlier win keeps its place.
    static func ranksAhead(_ lhs: BestScore, of rhs: BestScore) -> Bool {
        lhs.score != rhs.score ? lhs.score > rhs.score : lhs.wonAt < rhs.wonAt
    }
}
