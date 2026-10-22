import XCTest

final class LaunchUITests: SolitaireUITestCase {
    func testLaunchShowsTheBoard() {
        expectCards(Self.stockSize, in: "stock")
        expectCards(0, in: "waste")
        for column in 0 ..< Self.columnCount {
            expectCards(column + 1, in: "tableau-\(column)")
        }
        for foundation in 0 ..< Self.foundationCount {
            expectCards(0, in: "foundation-\(foundation)")
        }
        XCTAssertEqual(moves, "0")
        XCTAssertFalse(element("undoButton").isEnabled)
    }
}
