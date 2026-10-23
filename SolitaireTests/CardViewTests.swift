import SolitaireKit
import XCTest
@testable import Solitaire

@MainActor
final class CardViewTests: XCTestCase {
    func testFaceUpCardsAreNamed() {
        XCTAssertEqual(CardView.accessibilityLabel(for: Card(suit: .hearts, rank: .seven, isFaceUp: true)), "Seven of hearts, face up")
        XCTAssertEqual(CardView.accessibilityLabel(for: Card(suit: .spades, rank: .ace, isFaceUp: true)), "Ace of spades, face up")
    }

    func testFaceDownCardsDoNotGiveThemselvesAway() {
        XCTAssertEqual(CardView.accessibilityLabel(for: Card(suit: .hearts, rank: .seven)), "Face-down card")
    }
}
