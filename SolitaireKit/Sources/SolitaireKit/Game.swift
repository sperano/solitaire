/// A Klondike game in progress: the current position plus the history needed for undo, and the
/// positions undone, for redo, until a new move makes them unreachable.
public struct Game: Hashable, Codable, Sendable {
    public private(set) var state: GameState
    public private(set) var history: [GameState]
    /// The positions undo left, the most recently undone last.
    public private(set) var undone: [GameState]

    public init(seed: UInt64, drawMode: DrawMode, scoringMode: ScoringMode = .none, carriedBalance: Int = 0) {
        self.init(state: .deal(
            seed: seed,
            drawMode: drawMode,
            scoringMode: scoringMode,
            carriedBalance: carriedBalance
        ))
    }

    public init(state: GameState) {
        self.state = state
        history = []
        undone = []
    }

    public var isWon: Bool { state.isWon }
    public var canUndo: Bool { !history.isEmpty }
    public var canRedo: Bool { !undone.isEmpty }
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
        undone = []
    }

    /// Restore the previous position. Returns false when there is nothing to undo.
    @discardableResult
    public mutating func undo() -> Bool {
        guard let previous = history.popLast() else { return false }
        undone.append(state)
        state = previous
        return true
    }

    /// Return to the position the last undo left. Returns false when there is nothing to redo.
    @discardableResult
    public mutating func redo() -> Bool {
        guard let next = undone.popLast() else { return false }
        history.append(state)
        state = next
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

public extension Game {
    internal enum CodingKeys: String, CodingKey {
        case state, history, undone
    }

    /// Decodes a saved game. A save from before redo existed has no `undone` and loads with
    /// nothing to redo.
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        state = try container.decode(GameState.self, forKey: .state)
        history = try container.decode([GameState].self, forKey: .history)
        undone = try container.decodeIfPresent([GameState].self, forKey: .undone) ?? []
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(state, forKey: .state)
        try container.encode(history, forKey: .history)
        try container.encode(undone, forKey: .undone)
    }
}
