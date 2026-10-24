import XCTest
@testable import SolitaireKit

final class CardTests: XCTestCase {
    func testSuitColors() {
        XCTAssertEqual(Suit.hearts.color, .red)
        XCTAssertEqual(Suit.diamonds.color, .red)
        XCTAssertEqual(Suit.clubs.color, .black)
        XCTAssertEqual(Suit.spades.color, .black)
    }

    func testCardColorFollowsSuit() {
        for suit in Suit.allCases {
            XCTAssertEqual(card(.five, suit).color, suit.color)
        }
    }

    func testSuitSymbols() {
        XCTAssertEqual(Suit.clubs.symbol, "♣")
        XCTAssertEqual(Suit.diamonds.symbol, "♦")
        XCTAssertEqual(Suit.hearts.symbol, "♥")
        XCTAssertEqual(Suit.spades.symbol, "♠")
    }

    func testRankSymbols() {
        XCTAssertEqual(Rank.ace.symbol, "A")
        XCTAssertEqual(Rank.ten.symbol, "10")
        XCTAssertEqual(Rank.jack.symbol, "J")
        XCTAssertEqual(Rank.queen.symbol, "Q")
        XCTAssertEqual(Rank.king.symbol, "K")
        XCTAssertEqual(Rank.seven.symbol, "7")
    }

    func testIdIsStableRegardlessOfFace() {
        let down = card(.seven, .hearts, up: false)
        XCTAssertEqual(down.id, "7♥")
        XCTAssertEqual(down.faceUp().id, down.id)
        XCTAssertEqual(down.faceUp().faceDown().id, down.id)
        XCTAssertEqual(down.description, down.id)
    }

    func testFaceUpAndFaceDown() {
        let down = card(.queen, .spades, up: false)
        XCTAssertFalse(down.isFaceUp)
        let up = down.faceUp()
        XCTAssertTrue(up.isFaceUp)
        XCTAssertEqual(up.rank, .queen)
        XCTAssertEqual(up.suit, .spades)
        XCTAssertEqual(up.faceDown(), down)
        XCTAssertNotEqual(up, down)
    }

    func testCardsDefaultToFaceDown() {
        XCTAssertFalse(Card(suit: .clubs, rank: .ace).isFaceUp)
    }

    func testRankNext() {
        XCTAssertEqual(Rank.ace.next, .two)
        XCTAssertEqual(Rank.queen.next, .king)
        XCTAssertNil(Rank.king.next)
    }

    func testRankNextCoversAllButKing() {
        for rank in Rank.allCases where rank != .king {
            XCTAssertEqual(rank.next?.rawValue, rank.rawValue + 1)
        }
    }

    func testRankComparison() {
        XCTAssertLessThan(Rank.ace, .two)
        XCTAssertLessThan(Rank.ten, .jack)
        XCTAssertGreaterThan(Rank.king, .queen)
        XCTAssertEqual(Rank.allCases.sorted(), Rank.allCases)
    }
}
