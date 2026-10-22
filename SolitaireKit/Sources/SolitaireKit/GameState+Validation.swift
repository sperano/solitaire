extension GameState {
    /// Every card appears exactly once and the board has the right number of piles.
    public var isStructurallyValid: Bool {
        guard foundations.count == Self.foundationCount, tableau.count == Self.tableauColumnCount else { return false }
        return Deck.isComplete(stock + waste + foundations.flatMap { $0 } + tableau.flatMap { $0 })
    }

    /// The position could have been reached by legal play: right pile shapes and cards, face-up flags
    /// where play puts them, foundations built by suit from the ace, and a move counter that can still grow.
    public var isValidPosition: Bool {
        isStructurallyValid
            && (0 ..< Int.max).contains(moveCount)
            && stock.allSatisfy { !$0.isFaceUp }
            && waste.allSatisfy(\.isFaceUp)
            && foundations.allSatisfy(Self.isValidFoundation)
            && tableau.allSatisfy(Self.isValidTableauColumn)
    }

    /// Face up, starting with an ace and building up by suit.
    static func isValidFoundation(_ cards: [Card]) -> Bool {
        var top: Card?
        for card in cards {
            guard card.isFaceUp, Rules.canPlace(card, onFoundationTop: top) else { return false }
            top = card
        }
        return true
    }

    /// Face-down cards under a face-up run, with the top card always face up.
    static func isValidTableauColumn(_ cards: [Card]) -> Bool {
        guard !cards.isEmpty else { return true }
        let faceUpStart = cards.firstIndex(where: \.isFaceUp) ?? cards.endIndex
        return Rules.isValidRun(Array(cards[faceUpStart...]))
    }
}
