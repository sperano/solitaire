/// A deterministic SplitMix64 generator so a seed always produces the same deal.
public struct SeededRandomNumberGenerator: RandomNumberGenerator, Sendable {
    private static let increment: UInt64 = 0x9E37_79B9_7F4A_7C15
    private static let multiplierA: UInt64 = 0xBF58_476D_1CE4_E5B9
    private static let multiplierB: UInt64 = 0x94D0_49BB_1331_11EB

    private var state: UInt64

    public init(seed: UInt64) {
        state = seed
    }

    public mutating func next() -> UInt64 {
        state &+= Self.increment
        var mixed = state
        mixed = (mixed ^ (mixed >> 30)) &* Self.multiplierA
        mixed = (mixed ^ (mixed >> 27)) &* Self.multiplierB
        return mixed ^ (mixed >> 31)
    }
}

public enum Deck: Sendable {
    public static let cardCount = Suit.allCases.count * Rank.allCases.count

    /// The 52 cards in suit then rank order, all face down.
    public static func standard() -> [Card] {
        Suit.allCases.flatMap { suit in
            Rank.allCases.map { Card(suit: suit, rank: $0) }
        }
    }

    /// True when `cards` holds each of the 52 cards exactly once.
    public static func isComplete(_ cards: [Card]) -> Bool {
        cards.count == cardCount && Set(cards.map(\.id)).count == cardCount
    }

    /// A full deck shuffled deterministically from `seed`.
    public static func shuffled(seed: UInt64) -> [Card] {
        var generator = SeededRandomNumberGenerator(seed: seed)
        return standard().shuffled(using: &generator)
    }
}
