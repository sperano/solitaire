/// Results for one group of games: one draw mode, or all of them.
public struct StatisticsRecord: Hashable, Codable, Sendable {
    public internal(set) var played = 0
    public internal(set) var won = 0
    /// Fastest timed win, nil until the first one: untimed wins carry no time.
    public internal(set) var bestTimeSeconds: Int?
    /// Win with the fewest moves, nil until the first win.
    public internal(set) var fewestMoves: Int?
    /// Wins in a row up to the latest game.
    public internal(set) var currentStreak = 0
    public internal(set) var longestStreak = 0

    public init() {}

    public var lost: Int { played - won }

    /// Share of played games that were won, from 0 to 1; nil before the first game.
    public var winRate: Double? {
        played == 0 ? nil : Double(won) / Double(played)
    }

    /// `seconds` is nil for a win in untimed mode, which leaves the best time alone.
    mutating func recordWin(seconds: Int?, moves: Int) {
        played += 1
        won += 1
        if let seconds { bestTimeSeconds = min(bestTimeSeconds ?? seconds, seconds) }
        fewestMoves = min(fewestMoves ?? moves, moves)
        currentStreak += 1
        longestStreak = max(longestStreak, currentStreak)
    }

    mutating func recordLoss() {
        played += 1
        currentStreak = 0
    }

    /// Counts that recording results could produce, with room for one more game.
    public var isValid: Bool {
        (0 ..< Int.max).contains(played)
            && (0 ... played).contains(won)
            && (0 ... won).contains(longestStreak)
            && (0 ... longestStreak).contains(currentStreak)
            && hasBestsOnlyWhenWon
    }

    /// Fewest moves exactly when a game was won; a best time only then, and not necessarily,
    /// since untimed wins record none.
    private var hasBestsOnlyWhenWon: Bool {
        guard won > 0 else { return bestTimeSeconds == nil && fewestMoves == nil }
        guard let fewestMoves, fewestMoves >= 0 else { return false }
        return bestTimeSeconds.map { $0 >= 0 } ?? true
    }
}
