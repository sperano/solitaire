/// The full position of a Klondike game. The last element of each pile is its top card.
public struct GameState: Hashable, Codable, Sendable {
    public static let tableauColumnCount = 7
    public static let foundationCount = 4
    /// Cards dealt to the tableau: 1 + 2 + … + 7.
    public static let tableauCardCount = tableauColumnCount * (tableauColumnCount + 1) / 2

    public internal(set) var stock: [Card]
    public internal(set) var waste: [Card]
    public internal(set) var foundations: [[Card]]
    public internal(set) var tableau: [[Card]]
    public let drawMode: DrawMode
    public let seed: UInt64
    public internal(set) var moveCount: Int

    /// Deal a new game from the deck produced by `seed`.
    public static func deal(seed: UInt64, drawMode: DrawMode) -> GameState {
        deal(deck: Deck.shuffled(seed: seed), seed: seed, drawMode: drawMode)
    }

    /// Deal a new game from an explicit deck; cards are dealt from the end of the array.
    public static func deal(deck: [Card], seed: UInt64 = 0, drawMode: DrawMode) -> GameState {
        precondition(Deck.isComplete(deck), "a Klondike deal needs each of the 52 cards exactly once")
        var remaining = deck
        var tableau = Array(repeating: [Card](), count: tableauColumnCount)
        for row in 0 ..< tableauColumnCount {
            for column in row ..< tableauColumnCount {
                var card = remaining.removeLast()
                card.isFaceUp = column == row
                tableau[column].append(card)
            }
        }
        return GameState(
            stock: remaining.map { $0.faceDown() },
            waste: [],
            foundations: Array(repeating: [], count: foundationCount),
            tableau: tableau,
            drawMode: drawMode,
            seed: seed,
            moveCount: 0
        )
    }

    public func pile(_ id: PileID) -> [Card] {
        switch id {
        case .stock: stock
        case .waste: waste
        case let .foundation(index): foundations[index]
        case let .tableau(index): tableau[index]
        }
    }

    public func topCard(of id: PileID) -> Card? { pile(id).last }

    /// Every foundation holds a complete suit.
    public var isWon: Bool {
        foundations.allSatisfy { $0.count == Rank.allCases.count }
    }

    /// Index of the first face-up card in a tableau column, or nil when the column is empty.
    public func faceUpStart(inTableau column: Int) -> Int? {
        tableau[column].firstIndex(where: \.isFaceUp)
    }

    /// The index exists for this board: a valid foundation or tableau column, or the stock or waste.
    public func contains(_ id: PileID) -> Bool {
        switch id {
        case .stock, .waste: true
        case let .foundation(index): foundations.indices.contains(index)
        case let .tableau(index): tableau.indices.contains(index)
        }
    }

    /// Every card appears exactly once and the board has the right number of piles.
    public var isStructurallyValid: Bool {
        guard foundations.count == Self.foundationCount, tableau.count == Self.tableauColumnCount else { return false }
        return Deck.isComplete(stock + waste + foundations.flatMap { $0 } + tableau.flatMap { $0 })
    }

    mutating func setPile(_ id: PileID, to cards: [Card]) {
        switch id {
        case .stock: stock = cards
        case .waste: waste = cards
        case let .foundation(index): foundations[index] = cards
        case let .tableau(index): tableau[index] = cards
        }
    }
}
