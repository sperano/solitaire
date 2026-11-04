import SolitaireKit
import XCTest
@testable import Solitaire

/// The English names; `LocalizableCatalogTests` checks every one is translated.
final class DisplayNamesTests: XCTestCase {
    private static let manyMoves = 12

    func testCardNames() {
        XCTAssertEqual(Card(suit: .hearts, rank: .seven).spokenName, "seven of hearts")
        XCTAssertEqual(Card(suit: .spades, rank: .ace).spokenName, "ace of spades")
        XCTAssertEqual(Rank.king.spokenName, "king")
        XCTAssertEqual(Suit.diamonds.spokenName, "diamonds")
    }

    func testEnglishSentencesNameTheCardWithoutAnArticle() {
        for suit in Suit.allCases {
            for rank in Rank.allCases {
                let card = Card(suit: suit, rank: rank)
                XCTAssertEqual(card.nameInSentence, card.spokenName)
            }
        }
        XCTAssertEqual(Card(suit: .clubs, rank: .queen).nameInSentence, "queen of clubs")
    }

    func testEveryRankAndSuitHasItsOwnName() {
        XCTAssertEqual(Set(Rank.allCases.map(\.spokenName)).count, Rank.allCases.count)
        XCTAssertEqual(Set(Suit.allCases.map(\.spokenName)).count, Suit.allCases.count)
    }

    func testModeTitles() {
        XCTAssertEqual(DrawMode.allCases.map(\.title), ["Draw 1", "Draw 3"])
        XCTAssertEqual(ScoringMode.allCases.map(\.title), ["None", "Standard", "Vegas"])
    }

    func testMovesArePlural() {
        XCTAssertEqual(CountPhrase.moves(0), "0 moves")
        XCTAssertEqual(CountPhrase.moves(1), "1 move")
        XCTAssertEqual(CountPhrase.moves(Self.manyMoves), "12 moves")
    }

    func testPointsArePlural() {
        XCTAssertEqual(CountPhrase.points(1), "1 point")
        XCTAssertEqual(CountPhrase.points(Self.manyMoves), "12 points")
    }
}
