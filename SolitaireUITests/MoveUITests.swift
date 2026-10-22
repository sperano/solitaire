import XCTest

/// Uses the known deal for `-seed 42`: tableau tops are 2C 8C QC 5H 6S 5C AH.
final class MoveUITests: SolitaireUITestCase {
    private static let lastColumn = SolitaireUITestCase.columnCount - 1
    private static let fiveOfHeartsColumnSize = 4
    private static let sixOfSpadesColumnSize = 5

    private func drag(_ card: String, to pile: String) {
        let source = element(card)
        let target = element(pile)
        XCTAssertTrue(source.waitForExistence(timeout: Self.timeout), "\(card) not found")
        XCTAssertTrue(target.waitForExistence(timeout: Self.timeout), "\(pile) not found")
        let center = CGVector(dx: 0.5, dy: 0.5)
        source.coordinate(withNormalizedOffset: center).press(
            forDuration: Self.dragHold,
            thenDragTo: target.coordinate(withNormalizedOffset: center)
        )
    }

    func testTappingAnAceSendsItToAFoundation() {
        tap("card-AH")
        expectCards(1, in: "foundation-0")
        expectCards(Self.lastColumn, in: "tableau-6")
        XCTAssertEqual(moves, "1")
    }

    func testDraggingAnAceToAFoundation() {
        drag("card-AH", to: "foundation-1")
        expectCards(1, in: "foundation-1")
        expectCards(Self.lastColumn, in: "tableau-6")
        XCTAssertEqual(moves, "1")
    }

    func testDraggingARedFiveOntoABlackSix() {
        drag("card-5H", to: "tableau-4")
        expectCards(Self.fiveOfHeartsColumnSize - 1, in: "tableau-3")
        expectCards(Self.sixOfSpadesColumnSize + 1, in: "tableau-4")
        XCTAssertEqual(moves, "1")
    }

    func testIllegalDragLeavesTheBoardUnchanged() {
        drag("card-2C", to: "foundation-1")
        expectCards(0, in: "foundation-1")
        expectCards(1, in: "tableau-0")
        XCTAssertEqual(moves, "0")
    }

    func testTappingACardWithNoDestinationDoesNothing() {
        tap("card-2C")
        XCTAssertEqual(moves, "0")
    }
}
