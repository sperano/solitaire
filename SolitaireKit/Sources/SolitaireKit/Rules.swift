/// Klondike placement rules, independent of any board state.
public enum Rules {
    /// Tableau columns build down in alternating colours; only a king starts an empty column.
    public static func canPlace(_ card: Card, onTableauTop top: Card?) -> Bool {
        guard let top else { return card.rank == .king }
        return top.isFaceUp && top.color != card.color && top.rank == card.rank.next
    }

    /// Foundations build up by suit starting from the ace.
    public static func canPlace(_ card: Card, onFoundationTop top: Card?) -> Bool {
        guard let top else { return card.rank == .ace }
        return top.suit == card.suit && top.rank.next == card.rank
    }

    /// A run is a non-empty, face-up, descending, alternating-colour sequence that can move as a unit.
    public static func isValidRun(_ cards: [Card]) -> Bool {
        guard let first = cards.first, cards.allSatisfy(\.isFaceUp) else { return false }
        var previous = first
        for card in cards.dropFirst() {
            guard canPlace(card, onTableauTop: previous) else { return false }
            previous = card
        }
        return true
    }
}
