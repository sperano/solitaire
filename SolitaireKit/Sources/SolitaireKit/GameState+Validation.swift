extension GameState {
    /// Every card appears exactly once and the board has the right number of piles.
    public var isStructurallyValid: Bool {
        guard foundations.count == Self.foundationCount, tableau.count == Self.tableauColumnCount else { return false }
        return Deck.isComplete(stock + waste + foundations.flatMap(\.self) + tableau.flatMap(\.self))
    }

    /// Cards dealt to the stock; nothing ever returns to the stock or waste, so together they never hold more.
    public static let stockDealCount = Deck.cardCount - tableauCardCount

    /// The position could have been reached by legal play: right pile shapes and cards, pile sizes the
    /// deal allows, face-up flags where play puts them, foundations built by suit from the ace, and a
    /// move counter that can still grow, and a score and recycle count the scoring mode allows.
    public var isValidPosition: Bool {
        isStructurallyValid
            && (0 ..< Int.max).contains(moveCount)
            && isValidScoring
            && stock.count + waste.count <= Self.stockDealCount
            && tableau.indices.allSatisfy { faceDownCount(inTableau: $0) <= $0 }
            && stock.allSatisfy { !$0.isFaceUp }
            && waste.allSatisfy(\.isFaceUp)
            && foundations.allSatisfy(Self.isValidFoundation)
            && tableau.allSatisfy(Self.isValidTableauColumn)
    }

    /// Recycles within the mode's limit (and never more than moves made); a score inside
    /// `Scoring.scoreRange`; an unscored game scores 0 and a standard score never drops below 0.
    /// A Vegas balance may be negative.
    var isValidScoring: Bool {
        guard (0 ... moveCount).contains(recycleCount), Scoring.scoreRange.contains(score) else { return false }
        if let limit = Scoring.recycleLimit(mode: scoringMode, drawMode: drawMode),
           recycleCount > limit { return false }
        switch scoringMode {
        case .none: return score == 0
        case .standard: return score >= 0
        case .vegas: return true
        }
    }

    /// Column `n` is dealt `n` face-down cards and never gains more.
    func faceDownCount(inTableau column: Int) -> Int {
        tableau[column].count { !$0.isFaceUp }
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
