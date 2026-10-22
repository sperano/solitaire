/// Point values and pass limits for standard and Vegas scoring.
public enum Scoring {
    // Standard scoring.
    public static let wasteToTableauPoints = 5
    public static let toFoundationPoints = 10
    public static let flipPoints = 5
    public static let foundationToTableauPoints = -15
    public static let drawOneRecyclePoints = -100
    /// A win gets `timeBonusNumerator / seconds` extra points, once the game took at least this long.
    public static let timeBonusMinimumSeconds = 30
    public static let timeBonusNumerator = 700_000

    /// Every score stays in this range, far beyond what play can reach, so a tampered save or
    /// carried balance can never overflow an update.
    public static let scoreRange = -1_000_000_000_000 ... 1_000_000_000_000

    // Vegas scoring, in dollars.
    public static let vegasBuyIn = 52
    public static let vegasPointsPerFoundationCard = 5
    /// Passes through the stock a Vegas game allows, by draw mode.
    public static let vegasDrawOnePasses = 1
    public static let vegasDrawThreePasses = 3

    /// The score a new game starts with; Vegas pays the buy-in out of the carried balance.
    public static func initialScore(mode: ScoringMode, carriedBalance: Int) -> Int {
        mode == .vegas ? clamped(clamped(carriedBalance) - vegasBuyIn) : 0
    }

    /// Passes through the stock a Vegas game allows in `drawMode`.
    public static func vegasPasses(drawMode: DrawMode) -> Int {
        drawMode == .one ? vegasDrawOnePasses : vegasDrawThreePasses
    }

    /// How many times the waste may be turned back into the stock, or nil when there is no limit.
    public static func recycleLimit(mode: ScoringMode, drawMode: DrawMode) -> Int? {
        mode == .vegas ? vegasPasses(drawMode: drawMode) - 1 : nil
    }

    /// Extra points for winning a standard game in `elapsedSeconds`; zero for other modes and short games.
    public static func timeBonus(mode: ScoringMode, elapsedSeconds: Int) -> Int {
        guard mode == .standard, elapsedSeconds >= timeBonusMinimumSeconds else { return 0 }
        return timeBonusNumerator / elapsedSeconds
    }

    /// The score after `move` took `before` to `after`. Standard scores never drop below zero.
    static func score(after move: Move, from before: GameState, to after: GameState) -> Int {
        switch before.scoringMode {
        case .none:
            return before.score
        case .standard:
            return clamped(max(0, clamped(before.score) + standardPoints(for: move, from: before, to: after)))
        case .vegas:
            return clamped(clamped(before.score) + vegasPoints(for: move))
        }
    }

    /// `score` limited to `scoreRange`.
    public static func clamped(_ score: Int) -> Int {
        min(max(score, scoreRange.lowerBound), scoreRange.upperBound)
    }

    private static func standardPoints(for move: Move, from before: GameState, to after: GameState) -> Int {
        switch move {
        case .draw:
            let recycled = before.stock.isEmpty
            return recycled && before.drawMode == .one ? drawOneRecyclePoints : 0
        case let .move(from, to, _):
            return transferPoints(from: from, to: to) + flipBonus(from: from, before: before, after: after)
        }
    }

    private static func transferPoints(from: PileID, to: PileID) -> Int {
        switch (from, to) {
        case (.waste, .tableau): wasteToTableauPoints
        case (.waste, .foundation), (.tableau, .foundation): toFoundationPoints
        case (.foundation, .tableau): foundationToTableauPoints
        default: 0
        }
    }

    private static func flipBonus(from: PileID, before: GameState, after: GameState) -> Int {
        guard case let .tableau(column) = from else { return 0 }
        let flipped = before.faceDownCount(inTableau: column) > after.faceDownCount(inTableau: column)
        return flipped ? flipPoints : 0
    }

    private static func vegasPoints(for move: Move) -> Int {
        guard case let .move(from, to, _) = move else { return 0 }
        switch (from, to) {
        case (.foundation, .foundation): return 0
        case (_, .foundation): return vegasPointsPerFoundationCard
        case (.foundation, _): return -vegasPointsPerFoundationCard
        default: return 0
        }
    }
}
