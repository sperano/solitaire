extension GameState {
    /// Every legal move from this position: the draw (or recycle) first, then moves from the waste,
    /// the foundations and the tableau, each to the foundations and then to the tableau.
    public func availableMoves() -> [Move] {
        var moves = canApply(.draw) ? [Move.draw] : []
        for (source, count) in movableRuns {
            for destination in PileID.allFoundations + PileID.allTableau where destination != source {
                let move = Move.move(from: source, to: destination, count: count)
                if canApply(move) { moves.append(move) }
            }
        }
        return moves
    }

    /// The move a hint shows, in order of preference: a card to a foundation, a tableau run that
    /// uncovers a face-down card, a waste card to the tableau, then the draw. Moves that only
    /// shuffle cards between columns or take them back off a foundation are never suggested.
    /// Returns nil when none of these is possible.
    public func suggestedMove() -> Move? {
        let moves = availableMoves()
        let preferences: [(Move) -> Bool] = [
            isFoundationMove, uncoversFaceDownCard, { isMove($0, from: .waste) }, { $0 == .draw },
        ]
        return preferences.lazy.compactMap { moves.first(where: $0) }.first
    }

    /// Every pile and run size that could be picked up: the top card of the waste and each
    /// foundation, and every face-up run of each tableau column.
    private var movableRuns: [(PileID, Int)] {
        var runs: [(PileID, Int)] = waste.isEmpty ? [] : [(.waste, 1)]
        runs += PileID.allFoundations.filter { !pile($0).isEmpty }.map { ($0, 1) }
        for (index, column) in PileID.allTableau.enumerated() {
            guard let start = faceUpStart(inTableau: index) else { continue }
            runs += (1 ... tableau[index].count - start).map { (column, $0) }
        }
        return runs
    }

    private func isFoundationMove(_ move: Move) -> Bool {
        guard case let .move(from, to, _) = move else { return false }
        return to.isFoundation && !from.isFoundation
    }

    /// Moves a column's whole face-up run off a face-down card, which then turns over.
    private func uncoversFaceDownCard(_ move: Move) -> Bool {
        guard case let .move(.tableau(index), to, count) = move, to.isTableau,
              let start = faceUpStart(inTableau: index) else { return false }
        return start > 0 && count == tableau[index].count - start
    }

    private func isMove(_ move: Move, from source: PileID) -> Bool {
        guard case let .move(from, _, _) = move else { return false }
        return from == source
    }
}
