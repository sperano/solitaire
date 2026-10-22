import XCTest
@testable import SolitaireKit

final class RulesTests: XCTestCase {
    // MARK: Tableau

    func testTableauAcceptsAlternatingDescending() {
        XCTAssertTrue(Rules.canPlace(card(.six, .hearts), onTableauTop: card(.seven, .spades)))
        XCTAssertTrue(Rules.canPlace(card(.six, .clubs), onTableauTop: card(.seven, .diamonds)))
    }

    func testTableauRejectsSameColor() {
        XCTAssertFalse(Rules.canPlace(card(.six, .hearts), onTableauTop: card(.seven, .diamonds)))
        XCTAssertFalse(Rules.canPlace(card(.six, .clubs), onTableauTop: card(.seven, .spades)))
    }

    func testTableauRejectsWrongRank() {
        XCTAssertFalse(Rules.canPlace(card(.five, .hearts), onTableauTop: card(.seven, .spades)))
        XCTAssertFalse(Rules.canPlace(card(.eight, .hearts), onTableauTop: card(.seven, .spades)))
        XCTAssertFalse(Rules.canPlace(card(.seven, .hearts), onTableauTop: card(.seven, .spades)))
    }

    func testTableauEmptyAcceptsOnlyKing() {
        XCTAssertTrue(Rules.canPlace(card(.king, .hearts), onTableauTop: nil))
        XCTAssertFalse(Rules.canPlace(card(.queen, .hearts), onTableauTop: nil))
        XCTAssertFalse(Rules.canPlace(card(.ace, .spades), onTableauTop: nil))
    }

    func testTableauRejectsFaceDownTop() {
        XCTAssertFalse(Rules.canPlace(card(.six, .hearts), onTableauTop: card(.seven, .spades, up: false)))
    }

    func testNothingGoesOnAnAceInTableau() {
        XCTAssertFalse(Rules.canPlace(card(.ace, .hearts), onTableauTop: card(.ace, .spades)))
    }

    // MARK: Foundation

    func testFoundationAcceptsAceOnEmpty() {
        XCTAssertTrue(Rules.canPlace(card(.ace, .clubs), onFoundationTop: nil))
        XCTAssertFalse(Rules.canPlace(card(.two, .clubs), onFoundationTop: nil))
    }

    func testFoundationAcceptsSameSuitAscending() {
        XCTAssertTrue(Rules.canPlace(card(.two, .clubs), onFoundationTop: card(.ace, .clubs)))
        XCTAssertTrue(Rules.canPlace(card(.king, .hearts), onFoundationTop: card(.queen, .hearts)))
    }

    func testFoundationRejectsWrongSuit() {
        XCTAssertFalse(Rules.canPlace(card(.two, .spades), onFoundationTop: card(.ace, .clubs)))
    }

    func testFoundationRejectsSkippedOrRepeatedRank() {
        XCTAssertFalse(Rules.canPlace(card(.three, .clubs), onFoundationTop: card(.ace, .clubs)))
        XCTAssertFalse(Rules.canPlace(card(.ace, .clubs), onFoundationTop: card(.ace, .clubs)))
        XCTAssertFalse(Rules.canPlace(card(.ace, .clubs), onFoundationTop: card(.two, .clubs)))
    }

    // MARK: Runs

    func testEmptyRunIsInvalid() {
        XCTAssertFalse(Rules.isValidRun([]))
    }

    func testSingleFaceUpCardIsValidRun() {
        XCTAssertTrue(Rules.isValidRun([card(.four, .clubs)]))
    }

    func testFaceDownCardInvalidatesRun() {
        XCTAssertFalse(Rules.isValidRun([card(.four, .clubs, up: false)]))
        XCTAssertFalse(Rules.isValidRun([card(.five, .hearts), card(.four, .clubs, up: false)]))
    }

    func testDescendingAlternatingRunIsValid() {
        let run = [card(.nine, .clubs), card(.eight, .hearts), card(.seven, .spades), card(.six, .diamonds)]
        XCTAssertTrue(Rules.isValidRun(run))
    }

    func testSameColorRunIsInvalid() {
        XCTAssertFalse(Rules.isValidRun([card(.nine, .clubs), card(.eight, .spades)]))
    }

    func testRunWithGapIsInvalid() {
        XCTAssertFalse(Rules.isValidRun([card(.nine, .clubs), card(.seven, .hearts)]))
    }

    func testAscendingRunIsInvalid() {
        XCTAssertFalse(Rules.isValidRun([card(.seven, .hearts), card(.eight, .clubs)]))
    }
}
