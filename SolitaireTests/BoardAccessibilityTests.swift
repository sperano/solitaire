import SolitaireKit
import XCTest
@testable import Solitaire

final class BoardAccessibilityTests: XCTestCase {
    private let dealt = GameState.deal(seed: 42, drawMode: .one)
    private let nearlyDone = FixturePosition.oneMoveFromCompletable.state()

    private func label(_ pile: PileID, _ state: GameState) -> String {
        BoardAccessibility.label(for: pile, in: state)
    }

    // MARK: Pile labels

    func testStockLabels() {
        XCTAssertEqual(label(.stock, dealt), "Stock")
        XCTAssertEqual(label(.stock, nearlyDone), "Stock, empty")
    }

    func testWasteLabels() {
        XCTAssertEqual(label(.waste, dealt), "Waste, empty")
        XCTAssertEqual(label(.waste, nearlyDone), "Waste, seven of hearts on top")
    }

    func testFoundationLabels() {
        XCTAssertEqual(label(.foundation(1), dealt), "Foundation 2, empty")
        XCTAssertEqual(label(.foundation(2), nearlyDone), "Foundation 3, six of hearts on top")
    }

    func testColumnLabelsCountTheFaceDownCards() {
        XCTAssertEqual(label(.tableau(0), dealt), "Column 1")
        XCTAssertEqual(label(.tableau(3), dealt), "Column 4, 3 face down")
        XCTAssertEqual(label(.tableau(6), nearlyDone), "Column 7, empty")
    }

    // MARK: Hints

    func testStockHints() {
        XCTAssertEqual(BoardAccessibility.stockHint(in: dealt, canDraw: true), "Double-tap to draw")
        XCTAssertEqual(BoardAccessibility.stockHint(in: nearlyDone, canDraw: true), "Double-tap to turn the waste over")
        XCTAssertEqual(BoardAccessibility.stockHint(in: nearlyDone, canDraw: false), "No passes left")
        XCTAssertEqual(BoardAccessibility.stockHint(in: FixturePosition.deadlocked.state(), canDraw: false), "")
    }

    func testCardHints() {
        XCTAssertEqual(BoardAccessibility.cardHint(destinations: [], from: .tableau(0)), "No legal move")
        XCTAssertEqual(
            BoardAccessibility.cardHint(destinations: [.foundation(0)], from: .waste),
            "Double-tap to move it to the best spot, or swipe up or down to choose"
        )
        XCTAssertEqual(
            BoardAccessibility.cardHint(destinations: [.tableau(1)], from: .foundation(0)),
            "Swipe up or down to choose where to move it"
        )
    }

    func testActionTitles() {
        XCTAssertEqual(BoardAccessibility.actionTitle(for: .foundation(3)), "Move to foundation")
        XCTAssertEqual(BoardAccessibility.actionTitle(for: .tableau(0)), "Move to column 1")
        XCTAssertEqual(BoardAccessibility.actionTitle(for: .tableau(6)), "Move to column 7")
    }
}
