import SolitaireKit

/// What VoiceOver says when a hint appears, since the highlight alone is visual.
enum HintAnnouncement {
    static let noUsefulMove = "No useful moves"

    static func text(for hint: Hint, in state: GameState) -> String {
        guard case let .move(move) = hint else { return noUsefulMove }
        switch move {
        case .draw:
            return state.stock.isEmpty ? "Turn the waste back over" : "Draw from the stock"
        case let .move(from, to, count):
            let cards = state.pile(from)
            guard cards.count >= count else { return noUsefulMove }
            let moving = cards[cards.count - count].name
            let what = count == 1 ? moving : "\(moving) and the cards on it"
            return "Move \(what) to \(destination(to, in: state))"
        }
    }

    private static func destination(_ pile: PileID, in state: GameState) -> String {
        if pile.isFoundation { return "a foundation" }
        return state.topCard(of: pile).map(\.name) ?? "the empty column"
    }
}
