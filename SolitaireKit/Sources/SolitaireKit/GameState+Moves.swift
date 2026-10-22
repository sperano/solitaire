extension GameState {
    /// Apply a move, or throw a `MoveError` and leave the state untouched.
    public mutating func apply(_ move: Move) throws {
        var next = self
        switch move {
        case .draw:
            try next.draw()
        case let .move(from, to, count):
            try next.move(count: count, from: from, to: to)
        }
        next.moveCount += 1
        self = next
    }

    /// Whether `move` would succeed from this position.
    public func canApply(_ move: Move) -> Bool {
        var copy = self
        return (try? copy.apply(move)) != nil
    }

    private mutating func draw() throws {
        if stock.isEmpty {
            guard !waste.isEmpty else { throw MoveError.nothingToDraw }
            stock = waste.reversed().map { $0.faceDown() }
            waste = []
            return
        }
        let count = min(drawMode.cardsPerDraw, stock.count)
        let drawn = stock.suffix(count).reversed().map { $0.faceUp() }
        stock.removeLast(count)
        waste.append(contentsOf: drawn)
    }

    private mutating func move(count: Int, from: PileID, to: PileID) throws {
        guard contains(from) else { throw MoveError.illegalSource }
        guard contains(to) else { throw MoveError.illegalDestination }
        guard from != to else { throw MoveError.sameDestination }
        let cards = try cardsToMove(count: count, from: from)
        try validateDestination(to, for: cards)
        var source = pile(from)
        source.removeLast(count)
        if case .tableau = from, let exposed = source.last, !exposed.isFaceUp {
            source[source.count - 1] = exposed.faceUp()
        }
        setPile(from, to: source)
        setPile(to, to: pile(to) + cards)
    }

    private func cardsToMove(count: Int, from: PileID) throws -> [Card] {
        guard count >= 1 else { throw MoveError.invalidCount }
        switch from {
        case .stock:
            throw MoveError.illegalSource
        case .waste, .foundation:
            guard count == 1 else { throw MoveError.invalidCount }
        case .tableau:
            break
        }
        let source = pile(from)
        guard source.count >= count else { throw MoveError.invalidCount }
        let cards = Array(source.suffix(count))
        guard cards.allSatisfy(\.isFaceUp) else { throw MoveError.faceDownCard }
        return cards
    }

    private func validateDestination(_ to: PileID, for cards: [Card]) throws {
        switch to {
        case .stock, .waste:
            throw MoveError.illegalDestination
        case let .foundation(index):
            guard cards.count == 1 else { throw MoveError.invalidCount }
            guard Rules.canPlace(cards[0], onFoundationTop: foundations[index].last) else {
                throw MoveError.illegalPlacement
            }
        case let .tableau(index):
            guard Rules.isValidRun(cards), Rules.canPlace(cards[0], onTableauTop: tableau[index].last) else {
                throw MoveError.illegalPlacement
            }
        }
    }
}
