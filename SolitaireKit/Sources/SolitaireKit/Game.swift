/// A Klondike game in progress: the current position plus the history needed for undo.
public struct Game: Hashable, Codable, Sendable {
    public private(set) var state: GameState
    public private(set) var history: [GameState]

    public init(seed: UInt64, drawMode: DrawMode, scoringMode: ScoringMode = .none, carriedBalance: Int = 0) {
        self.init(state: .deal(seed: seed, drawMode: drawMode, scoringMode: scoringMode, carriedBalance: carriedBalance))
    }

    public init(state: GameState) {
        self.state = state
        history = []
    }

    public var isWon: Bool { state.isWon }
    public var canUndo: Bool { !history.isEmpty }
    public var moveCount: Int { state.moveCount }
    public var drawMode: DrawMode { state.drawMode }
    public var scoringMode: ScoringMode { state.scoringMode }
    public var score: Int { state.score }
    /// Tapping the stock does something: it draws, or it recycles a waste the scoring mode still allows.
    public var canDraw: Bool { state.canApply(.draw) }

    public mutating func perform(_ move: Move) throws {
        var next = state
        try next.apply(move)
        history.append(state)
        state = next
    }

    /// Restore the previous position. Returns false when there is nothing to undo.
    @discardableResult
    public mutating func undo() -> Bool {
        guard let previous = history.popLast() else { return false }
        state = previous
        return true
    }

    public func canMove(count: Int, from: PileID, to: PileID) -> Bool {
        state.canApply(.move(from: from, to: to, count: count))
    }

    /// Where a tap on the top `count` cards of `from` should send them: a foundation if possible,
    /// otherwise the first tableau column that accepts the run. Cards never leave a foundation this way.
    public func autoMoveDestination(count: Int, from: PileID) -> PileID? {
        if from.isFoundation { return nil }
        if count == 1, let foundation = PileID.allFoundations.first(where: { canMove(count: 1, from: from, to: $0) }) {
            return foundation
        }
        let columns = PileID.allTableau.filter { $0 != from && canMove(count: count, from: from, to: $0) }
        return columns.first { !state.pile($0).isEmpty } ?? columns.first
    }

    /// The stock and waste are empty and every tableau card is face up, so the game can finish itself.
    public var canAutoComplete: Bool {
        !isWon && state.stock.isEmpty && state.waste.isEmpty
            && state.tableau.allSatisfy { $0.allSatisfy(\.isFaceUp) }
            && nextAutoCompleteMove() != nil
    }

    /// See `GameState.availableMoves()`.
    public func availableMoves() -> [Move] { state.availableMoves() }

    /// See `GameState.suggestedMove()`.
    public func suggestedMove() -> Move? { state.suggestedMove() }

    /// The next card that can go to a foundation during auto-completion, if any.
    public func nextAutoCompleteMove() -> Move? {
        for column in PileID.allTableau where !state.pile(column).isEmpty {
            if let destination = PileID.allFoundations.first(where: { canMove(count: 1, from: column, to: $0) }) {
                return .move(from: column, to: destination, count: 1)
            }
        }
        return nil
    }
}
