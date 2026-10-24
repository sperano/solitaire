import SolitaireKit

/// What the hint button shows.
enum Hint: Equatable {
    case move(Move)
    /// Neither a move nor a draw would help.
    case noUsefulMove
}

extension GameViewModel {
    /// The card at `index` of `pile` is part of the hinted move: a card that moves, the card it
    /// lands on, or the top of the stock when the hint is to draw.
    func isHinted(_ pile: PileID, index: Int) -> Bool {
        guard case let .move(move) = hint else { return false }
        let count = state.pile(pile).count
        switch move {
        case .draw:
            return pile == .stock && index == count - 1
        case let .move(from, to, moved):
            if pile == from { return index >= count - moved }
            return pile == to && index == count - 1
        }
    }

    /// `pile` is empty and the hint points at it: a column a king goes to, a foundation an ace goes to, or the stock to
    /// recycle.
    func isHintedEmptySlot(_ pile: PileID) -> Bool {
        guard case let .move(move) = hint, state.pile(pile).isEmpty else { return false }
        switch move {
        case .draw: return pile == .stock
        case let .move(_, to, _): return pile == to
        }
    }

    /// The stock is a single accessibility element, so it reports a draw hint as a whole.
    var isStockHinted: Bool { hint == .move(.draw) }
}
