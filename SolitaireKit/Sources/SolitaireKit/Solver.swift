/// Looks for a way to win from a position: a depth-first search over the moves that can help,
/// with a transposition table so no position is explored twice and a node budget so a hard deal
/// cannot run for ever.
///
/// The search is not exhaustive: it never takes a card back off a foundation, and only moves
/// cards between columns when that uncovers a card, frees a card for a foundation or empties a
/// column for a king (see `GameState.solverCandidates()`). So `.noSolution` means none of those
/// lines wins, which is what deciding whether to deal a game needs.
public struct Solver: Sendable {
    public static let defaultNodeBudget = 50_000

    public enum Outcome: Equatable, Sendable {
        /// The moves, in order, that win from the position. The search stops once every card is
        /// face up with the stock and waste empty; the foundation moves that finish from there are
        /// appended, so the whole line can be replayed.
        case solved([Move])
        /// Every line the solver considers was tried, and none wins.
        case noSolution
        /// The budget ran out, or the search was cancelled, first.
        case undecided
    }

    public struct Report: Equatable, Sendable {
        public let outcome: Outcome
        /// Positions expanded; never more than the budget.
        public let nodes: Int
    }

    /// The most positions one search expands.
    public let nodeBudget: Int

    public init(nodeBudget: Int = defaultNodeBudget) {
        self.nodeBudget = nodeBudget
    }

    /// The foundation moves that finish a completable position, lowest card first.
    static func finishingMoves(from position: GameState) -> [Move] {
        var state = position
        var moves: [Move] = []
        while !state.isWon, let move = Game(state: state).nextAutoCompleteMove() {
            guard (try? state.apply(move)) != nil else { break }
            moves.append(move)
        }
        return moves
    }

    /// `isCancelled` is checked before each position, so a search off the main thread can stop early.
    public func solve(_ state: GameState, isCancelled: () -> Bool = { false }) -> Report {
        withoutActuallyEscaping(isCancelled) { isCancelled in
            var search = Search(budget: nodeBudget, isCancelled: isCancelled)
            let outcome: Outcome = switch search.run(from: state) {
            case let .won(path, position): .solved(path + Self.finishingMoves(from: position))
            case .exhausted: .noSolution
            case .stopped: .undecided
            }
            return Report(outcome: outcome, nodes: search.nodes)
        }
    }
}

/// The depth-first search, with its own stack of frames: a winning line can be a few hundred
/// moves long, and the solver runs on background threads whose stacks are small.
private struct Search {
    enum Result {
        /// The moves to a position that completes itself, and that position.
        case won([Move], GameState)
        case exhausted
        case stopped
    }

    /// A position being explored, the move that reached it and the candidates still to try.
    private struct Frame {
        let state: GameState
        let enteringMove: Move?
        let candidates: [Move]
        var nextCandidate = 0
    }

    let budget: Int
    let isCancelled: () -> Bool
    private(set) var nodes = 0
    private var frames: [Frame] = []
    private var visited: Set<[UInt8]> = []

    init(budget: Int, isCancelled: @escaping () -> Bool) {
        self.budget = budget
        self.isCancelled = isCancelled
    }

    mutating func run(from root: GameState) -> Result {
        if root.isCompletable { return .won([], root) }
        if let stopped = expand(root, reachedBy: nil) { return stopped }
        while var frame = frames.popLast() {
            guard frame.nextCandidate < frame.candidates.count else { continue }
            let move = frame.candidates[frame.nextCandidate]
            frame.nextCandidate += 1
            frames.append(frame)
            var next = frame.state
            guard (try? next.apply(move)) != nil else { continue }
            if next.isCompletable { return .won(path + [move], next) }
            guard visited.insert(next.solverKey).inserted else { continue }
            if let stopped = expand(next, reachedBy: move) { return stopped }
        }
        return .exhausted
    }

    /// Pushes a position not seen before, or reports that the budget or a cancellation stops the search.
    private mutating func expand(_ state: GameState, reachedBy move: Move?) -> Result? {
        guard nodes < budget, !isCancelled() else { return .stopped }
        nodes += 1
        if move == nil { visited.insert(state.solverKey) }
        frames.append(Frame(state: state, enteringMove: move, candidates: state.solverCandidates()))
        return nil
    }

    /// The moves that led to the position on top of the stack.
    private var path: [Move] { frames.compactMap(\.enteringMove) }
}
