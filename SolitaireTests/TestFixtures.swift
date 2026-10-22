import Foundation
import SolitaireKit
import XCTest

extension Game {
    private static let firstRemainingRank = Rank.seven
    private static let remainingRanks = Rank.allCases.filter { $0 >= firstRemainingRank }.reversed()
    /// Seven to king of hearts and spades.
    static let completableRemainingCardCount = 2 * remainingRanks.count

    /// Clubs and diamonds are complete, hearts and spades are up to the six, and the
    /// seven to king of both sit face up in two alternating runs, so the game can finish itself.
    /// Built through JSON because the engine's pile setters are internal to `SolitaireKit`.
    static func completable(scoringMode: ScoringMode = .none, drawMode: DrawMode = .one) throws -> Game {
        var json = try XCTUnwrap(
            JSONSerialization.jsonObject(with: JSONEncoder().encode(GameState.deal(seed: 1, drawMode: drawMode))) as? [String: Any]
        )
        func encode(_ cards: [Card]) throws -> Any {
            try JSONSerialization.jsonObject(with: JSONEncoder().encode(cards))
        }
        func faceUp(_ suit: Suit, _ ranks: some Sequence<Rank>) -> [Card] {
            ranks.map { Card(suit: suit, rank: $0, isFaceUp: true) }
        }
        /// Kings down to sevens, alternating between the two suits.
        func run(startingWith first: Suit, then second: Suit) -> [Card] {
            remainingRanks.enumerated().map { offset, rank in
                Card(suit: offset.isMultiple(of: 2) ? first : second, rank: rank, isFaceUp: true)
            }
        }
        let partial = Rank.allCases.filter { $0 < firstRemainingRank }
        json["stock"] = []
        json["waste"] = []
        json["scoringMode"] = scoringMode.rawValue
        json["foundations"] = try [
            encode(faceUp(.clubs, Rank.allCases)), encode(faceUp(.diamonds, Rank.allCases)),
            encode(faceUp(.hearts, partial)), encode(faceUp(.spades, partial)),
        ]
        json["tableau"] = try [encode(run(startingWith: .spades, then: .hearts)), encode(run(startingWith: .hearts, then: .spades))]
            + Array(repeating: [Any](), count: GameState.tableauColumnCount - 2)
        let state = try JSONDecoder().decode(GameState.self, from: JSONSerialization.data(withJSONObject: json))
        return Game(state: state)
    }

    /// `completable()` played until a single card is left to move, which wins the game.
    static func oneMoveFromWinning(drawMode: DrawMode = .one) throws -> Game {
        var game = try completable(drawMode: drawMode)
        for _ in 1 ..< completableRemainingCardCount {
            try game.perform(XCTUnwrap(game.nextAutoCompleteMove()))
        }
        return game
    }

    /// `completable()` played to the end.
    static func won() throws -> Game {
        var game = try oneMoveFromWinning()
        try game.perform(XCTUnwrap(game.nextAutoCompleteMove()))
        return game
    }
}
