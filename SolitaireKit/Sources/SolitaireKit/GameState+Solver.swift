extension GameState {
    /// The moves the solver tries, best first. Legality is checked with the placement rules
    /// directly rather than through `canApply`, which copies the whole position; the search
    /// applies the move it picks anyway. A safe move to a foundation is played alone: no other
    /// line can do better (see `isSafeFoundationMove`).
    func solverCandidates() -> [Move] {
        let foundationMoves = sources.compactMap(foundationMove(from:))
        if let safe = foundationMoves.first(where: isSafeFoundationMove) { return [safe] }
        let uncovering = tableauMoves(uncovering: true)
            .sorted { faceDownCount(under: $0) > faceDownCount(under: $1) }
        var candidates = foundationMoves + uncovering + wasteToTableauMoves()
        candidates += tableauMoves(uncovering: false).filter(freesCardForFoundation)
        candidates += columnEmptyingMoves()
        if canDrawOrRecycle { candidates.append(.draw) }
        return candidates
    }

    /// Every tableau card is face up and the stock and waste are empty: the lowest card still on
    /// the board always sits on top of its column and its predecessor is on its foundation, so the
    /// game finishes itself from here (this is what the Finish button relies on).
    var isCompletable: Bool {
        stock.isEmpty && waste.isEmpty && tableau.allSatisfy { $0.allSatisfy(\.isFaceUp) }
    }

    /// The waste and every tableau column with a card on top.
    private var sources: [PileID] {
        [.waste] + PileID.allTableau.filter { !pile($0).isEmpty }
    }

    private var canDrawOrRecycle: Bool {
        !stock.isEmpty || (!waste.isEmpty && remainingRecycles != 0)
    }

    private func foundationMove(from source: PileID) -> Move? {
        guard let card = topCard(of: source) else { return nil }
        return foundations.indices
            .first { Rules.canPlace(card, onFoundationTop: foundations[$0].last) }
            .map { .move(from: source, to: .foundation($0), count: 1) }
    }

    /// A card is safe on its foundation once the cards that could be built on it in the tableau,
    /// the opposite colour one rank lower, are on their foundations already. Aces and twos always are.
    private func isSafeFoundationMove(_ move: Move) -> Bool {
        guard case let .move(source, _, _) = move, let card = topCard(of: source) else { return false }
        guard card.rank.rawValue > Self.alwaysSafeRank else { return true }
        let opposite = Suit.allCases.filter { $0.color != card.color }
        return opposite.allSatisfy { foundationCount(of: $0) >= card.rank.rawValue - 1 }
    }

    private static let alwaysSafeRank = 2

    func foundationCount(of suit: Suit) -> Int {
        foundations.first { $0.first?.suit == suit }?.count ?? 0
    }

    /// Whole face-up runs moved to another column. With `uncovering`, only runs lying on a
    /// face-down card; without, only partial runs (the top part of a column's face-up run).
    private func tableauMoves(uncovering: Bool) -> [Move] {
        PileID.allTableau.enumerated().flatMap { index, source -> [Move] in
            guard let start = faceUpStart(inTableau: index) else { return [] }
            let runLength = tableau[index].count - start
            let counts = uncovering ? (start > 0 ? [runLength] : []) : Array((1 ..< max(1, runLength)).reversed())
            return counts.flatMap { count in
                tableauDestinations(for: tableau[index][tableau[index].count - count], from: source)
                    .map { Move.move(from: source, to: $0, count: count) }
            }
        }
    }

    /// The columns `card`, leading a run from `source`, may be placed on. Only one empty column is
    /// worth trying: they are interchangeable.
    private func tableauDestinations(for card: Card, from source: PileID) -> [PileID] {
        var destinations: [PileID] = []
        var emptyTried = false
        for destination in PileID.allTableau where destination != source {
            let top = pile(destination).last
            if top == nil, emptyTried { continue }
            guard Rules.canPlace(card, onTableauTop: top) else { continue }
            if top == nil { emptyTried = true }
            destinations.append(destination)
        }
        return destinations
    }

    private func faceDownCount(under move: Move) -> Int {
        guard case let .move(.tableau(index), _, _) = move else { return 0 }
        return faceDownCount(inTableau: index)
    }

    /// A partial run moved away so the card it covered can go to a foundation.
    private func freesCardForFoundation(_ move: Move) -> Bool {
        guard case let .move(source, _, count) = move else { return false }
        let cards = pile(source)
        let exposed = cards[cards.count - count - 1]
        return foundations.contains { Rules.canPlace(exposed, onFoundationTop: $0.last) }
    }

    private func wasteToTableauMoves() -> [Move] {
        guard let card = waste.last else { return [] }
        return tableauDestinations(for: card, from: .waste).map { .move(from: .waste, to: $0, count: 1) }
    }

    /// A whole column that is not headed by a king moved onto another, when a king is waiting
    /// for the space: on top of the waste, or heading a run that lies on face-down cards.
    private func columnEmptyingMoves() -> [Move] {
        guard hasKingWaitingForSpace else { return [] }
        return PileID.allTableau.enumerated().flatMap { index, source -> [Move] in
            guard faceUpStart(inTableau: index) == 0, let first = tableau[index].first,
                  first.rank != .king else { return [] }
            return tableauDestinations(for: first, from: source)
                .map { Move.move(from: source, to: $0, count: tableau[index].count) }
        }
    }

    private var hasKingWaitingForSpace: Bool {
        if waste.last?.rank == .king { return true }
        return tableau.indices.contains { index in
            guard let start = faceUpStart(inTableau: index), start > 0 else { return false }
            return tableau[index][start].rank == .king
        }
    }

    /// Identifies a position for the transposition table. Columns are sorted, since which column
    /// holds a pile makes no difference, and foundations are counted by suit.
    var solverKey: [UInt8] {
        var key: [UInt8] = []
        key.reserveCapacity(Self.solverKeyCapacity)
        for card in stock { key.append(card.solverByte) }
        key.append(Self.pileSeparator)
        for card in waste { key.append(card.solverByte) }
        key.append(Self.pileSeparator)
        for suit in Suit.allCases { key.append(UInt8(foundationCount(of: suit))) }
        if remainingRecycles != nil { key.append(UInt8(clamping: recycleCount)) }
        for column in tableau.map({ $0.map(\.solverByte) }).sorted(by: { $0.lexicographicallyPrecedes($1) }) {
            key.append(Self.pileSeparator)
            key.append(contentsOf: column)
        }
        return key
    }

    private static let pileSeparator: UInt8 = .max
    /// Every card once, a separator per pile, the foundation counts and the recycle count.
    private static let solverKeyCapacity = Deck.cardCount + tableauColumnCount + 2 + foundationCount + 1
}

private extension Card {
    private static let faceUpFlag: UInt8 = 64

    /// The card in one byte: suit and rank, plus a flag when it is face up.
    var solverByte: UInt8 {
        let suitIndex = UInt8(Suit.allCases.firstIndex(of: suit) ?? 0)
        let value = suitIndex * UInt8(Rank.allCases.count) + UInt8(rank.rawValue - 1)
        return isFaceUp ? value | Self.faceUpFlag : value
    }
}
