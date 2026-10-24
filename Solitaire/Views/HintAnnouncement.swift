import SolitaireKit

/// What VoiceOver says when a hint appears, since the highlight alone is visual.
enum HintAnnouncement {
    static var noUsefulMove: String { String(localized: "No useful moves", comment: "Hint found nothing") }

    static func text(for hint: Hint, in state: GameState) -> String {
        guard case let .move(move) = hint else { return noUsefulMove }
        switch move {
        case .draw:
            return state.stock.isEmpty
                ? String(localized: "Turn the waste back over", comment: "Hint: recycle the waste into the stock")
                : String(localized: "Draw from the stock", comment: "Hint")
        case let .move(from, to, count):
            let cards = state.pile(from)
            guard cards.count >= count else { return noUsefulMove }
            let moving = cards[cards.count - count].nameInSentence
            let what = count == 1
                ? moving
                : String(localized: "\(moving) and the cards on it", comment: "Hint: a card and the run above it")
            return sentence(moving: what, to: to, in: state)
        }
    }

    private static func sentence(moving what: String, to pile: PileID, in state: GameState) -> String {
        if pile.isFoundation {
            return String(localized: "Move \(what) to a foundation", comment: "Hint")
        }
        guard let top = state.topCard(of: pile) else {
            return String(localized: "Move \(what) to the empty column", comment: "Hint")
        }
        return String(localized: "Move \(what) to \(top.nameInSentence)", comment: "Hint: the card, then its target")
    }
}
