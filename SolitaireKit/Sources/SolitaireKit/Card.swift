/// The colour of a card, which drives the alternating rule on the tableau.
public enum CardColor: Sendable, Hashable {
    case red
    case black
}

public enum Suit: String, CaseIterable, Codable, Hashable, Sendable {
    case clubs
    case diamonds
    case hearts
    case spades

    public var color: CardColor {
        switch self {
        case .diamonds, .hearts: .red
        case .clubs, .spades: .black
        }
    }

    public var symbol: String {
        switch self {
        case .clubs: "♣"
        case .diamonds: "♦"
        case .hearts: "♥"
        case .spades: "♠"
        }
    }

    public var name: String { rawValue }
}

public enum Rank: Int, CaseIterable, Codable, Hashable, Comparable, Sendable {
    case ace = 1
    case two, three, four, five, six, seven, eight, nine, ten
    case jack, queen, king

    public static func < (lhs: Rank, rhs: Rank) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    /// The rank one step higher, or nil for a king.
    public var next: Rank? { Rank(rawValue: rawValue + 1) }

    public var symbol: String {
        switch self {
        case .ace: "A"
        case .jack: "J"
        case .queen: "Q"
        case .king: "K"
        default: String(rawValue)
        }
    }

    public var name: String {
        switch self {
        case .ace: "ace"
        case .two: "two"
        case .three: "three"
        case .four: "four"
        case .five: "five"
        case .six: "six"
        case .seven: "seven"
        case .eight: "eight"
        case .nine: "nine"
        case .ten: "ten"
        case .jack: "jack"
        case .queen: "queen"
        case .king: "king"
        }
    }
}

public struct Card: Hashable, Codable, Sendable, Identifiable, CustomStringConvertible {
    public let suit: Suit
    public let rank: Rank
    public var isFaceUp: Bool

    public init(suit: Suit, rank: Rank, isFaceUp: Bool = false) {
        self.suit = suit
        self.rank = rank
        self.isFaceUp = isFaceUp
    }

    /// Stable identity independent of the face-up state.
    public var id: String { "\(rank.symbol)\(suit.symbol)" }

    public var color: CardColor { suit.color }

    public var description: String { id }

    /// A human-readable name such as "seven of hearts".
    public var name: String { "\(rank.name) of \(suit.name)" }

    public func faceUp() -> Card { Card(suit: suit, rank: rank, isFaceUp: true) }

    public func faceDown() -> Card { Card(suit: suit, rank: rank, isFaceUp: false) }
}
