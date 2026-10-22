import SolitaireKit

/// Board positions a UI test can start from with `-position <name>`; the unit tests use them too.
enum FixturePosition: String, CaseIterable {
    /// Clubs and diamonds are complete, hearts and spades are up to the six, and the seven to king
    /// of both sit face up in two alternating runs, so the game can finish itself.
    case completable
    /// `completable` with the seven of hearts in the waste: moving it to its foundation makes the
    /// game completable.
    case oneMoveFromCompletable
    /// No draw and no legal move: the seven columns show the hearts king through seven, one each, over face-down cards, and the stock is empty.
    case deadlocked

    static let argument = "-position"
    private static let firstRemainingRank = Rank.seven
    private static let remainingRanks = Rank.allCases.filter { $0 >= firstRemainingRank }.reversed()
    /// Seven to king of hearts and spades.
    static let completableRemainingCardCount = 2 * remainingRanks.count

    func state(drawMode: DrawMode = .one, scoringMode: ScoringMode = .none) -> GameState {
        let piles = switch self {
        case .completable: Self.completablePiles(sevenOfHeartsInWaste: false)
        case .oneMoveFromCompletable: Self.completablePiles(sevenOfHeartsInWaste: true)
        case .deadlocked: Self.deadlockedPiles
        }
        guard let state = GameState.position(
            waste: piles.waste, foundations: piles.foundations, tableau: piles.tableau,
            drawMode: drawMode, scoringMode: scoringMode
        ) else {
            preconditionFailure("fixture \(rawValue) is not a legal position")
        }
        return state
    }

    private typealias Piles = (waste: [Card], foundations: [[Card]], tableau: [[Card]])

    private static func completablePiles(sevenOfHeartsInWaste: Bool) -> Piles {
        var tableau = [run(startingWith: .spades, then: .hearts), run(startingWith: .hearts, then: .spades)]
        var waste: [Card] = []
        if sevenOfHeartsInWaste, let seven = tableau[1].popLast() {
            waste = [seven]
        }
        let partial = Rank.allCases.filter { $0 < firstRemainingRank }
        let foundations = [
            faceUp(.clubs, Rank.allCases), faceUp(.diamonds, Rank.allCases),
            faceUp(.hearts, partial), faceUp(.spades, partial),
        ]
        return (waste, foundations, tableau)
    }

    /// Clubs and diamonds complete; the king to seven of hearts on top of the seven columns, the
    /// rest of hearts and all spades face down beneath them, as deep as each column allows.
    private static var deadlockedPiles: Piles {
        let tops = faceUp(.hearts, remainingRanks)
        var hidden = (Rank.allCases.filter { $0 < firstRemainingRank }.map { Card(suit: .hearts, rank: $0) }
            + Rank.allCases.map { Card(suit: .spades, rank: $0) }).makeIterator()
        let tableau = tops.enumerated().map { column, top in
            // Column n holds at most n face-down cards; the deck runs out before the last column is full.
            (0 ..< column).compactMap { _ in hidden.next() } + [top]
        }
        return ([], [faceUp(.clubs, Rank.allCases), faceUp(.diamonds, Rank.allCases)], tableau)
    }

    private static func faceUp(_ suit: Suit, _ ranks: some Sequence<Rank>) -> [Card] {
        ranks.map { Card(suit: suit, rank: $0, isFaceUp: true) }
    }

    /// Kings down to sevens, alternating between the two suits.
    private static func run(startingWith first: Suit, then second: Suit) -> [Card] {
        remainingRanks.enumerated().map { offset, rank in
            Card(suit: offset.isMultiple(of: 2) ? first : second, rank: rank, isFaceUp: true)
        }
    }
}
