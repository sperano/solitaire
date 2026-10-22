import XCTest
@testable import SolitaireKit

final class DeckTests: XCTestCase {
    private let seedA: UInt64 = 42
    private let seedB: UInt64 = 43
    private let sampleCount = 16

    func testCardCountConstant() {
        XCTAssertEqual(Deck.cardCount, 52)
    }

    func testStandardHasAllUniqueCardsFaceDown() {
        let deck = Deck.standard()
        XCTAssertEqual(deck.count, Deck.cardCount)
        XCTAssertEqual(Set(deck.map(\.id)).count, Deck.cardCount)
        XCTAssertTrue(deck.allSatisfy { !$0.isFaceUp })
    }

    func testShuffledIsDeterministicForSameSeed() {
        XCTAssertEqual(Deck.shuffled(seed: seedA), Deck.shuffled(seed: seedA))
    }

    func testShuffledDiffersForDifferentSeeds() {
        XCTAssertNotEqual(Deck.shuffled(seed: seedA), Deck.shuffled(seed: seedB))
    }

    func testShuffledDiffersFromStandardOrder() {
        XCTAssertNotEqual(Deck.shuffled(seed: seedA), Deck.standard())
    }

    func testShuffledStillHasAllUniqueCards() {
        let deck = Deck.shuffled(seed: seedA)
        XCTAssertEqual(deck.count, Deck.cardCount)
        XCTAssertEqual(Set(deck), Set(Deck.standard()))
        XCTAssertTrue(deck.allSatisfy { !$0.isFaceUp })
    }

    func testGeneratorReproducesSequence() {
        var first = SeededRandomNumberGenerator(seed: seedA)
        var second = SeededRandomNumberGenerator(seed: seedA)
        let a = (0 ..< sampleCount).map { _ in first.next() }
        let b = (0 ..< sampleCount).map { _ in second.next() }
        XCTAssertEqual(a, b)
    }

    func testGeneratorDiffersAcrossSeedsAndAdvances() {
        var first = SeededRandomNumberGenerator(seed: seedA)
        var second = SeededRandomNumberGenerator(seed: seedB)
        XCTAssertNotEqual(first.next(), second.next())
        let values = (0 ..< sampleCount).map { _ in first.next() }
        XCTAssertEqual(Set(values).count, sampleCount)
    }

    func testIsCompleteAcceptsAShuffledDeck() {
        XCTAssertTrue(Deck.isComplete(Deck.shuffled(seed: 7)))
    }

    func testIsCompleteRejectsMissingOrDuplicateCards() {
        var deck = Deck.standard()
        deck.removeLast()
        XCTAssertFalse(Deck.isComplete(deck))
        deck.append(deck[0])
        XCTAssertFalse(Deck.isComplete(deck), "52 cards with a duplicate is not a deck")
    }
}
