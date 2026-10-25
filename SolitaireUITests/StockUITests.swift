import XCTest

final class StockUITests: SolitaireUITestCase {
    private static let recycleDrawCount = SolitaireUITestCase.stockSize / SolitaireUITestCase.cardsPerDrawThree

    func testDrawOneMovesACardToTheWaste() {
        tapStock()
        expectCards(1, in: "waste")
        expectCards(Self.stockSize - 1, in: "stock")
        XCTAssertEqual(moves, "1")
        XCTAssertTrue(element("undoButton").isEnabled)
    }

    func testUndoRestoresTheStock() {
        tapStock()
        tap("undoButton")
        expectCards(Self.stockSize, in: "stock")
        expectCards(0, in: "waste")
    }

    func testRedoDrawsTheUndoneCardAgain() {
        XCTAssertFalse(element("redoButton").isEnabled)
        tapStock()
        XCTAssertFalse(element("redoButton").isEnabled)
        tap("undoButton")
        tap("redoButton")
        expectCards(1, in: "waste")
        expectCards(Self.stockSize - 1, in: "stock")
        XCTAssertEqual(moves, "1")
        XCTAssertFalse(element("redoButton").isEnabled)
    }

    func testDrawThreeMovesThreeCards() {
        app = launchApp(extraArguments: ["-drawMode", "3"])
        tapStock()
        expectCards(Self.cardsPerDrawThree, in: "waste")
        expectCards(Self.stockSize - Self.cardsPerDrawThree, in: "stock")
    }

    func testStockRecyclesAfterBeingEmptied() {
        app = launchApp(extraArguments: ["-drawMode", "3"])
        tapStock(times: Self.recycleDrawCount)
        expectCards(0, in: "stock")
        expectCards(Self.stockSize, in: "waste")
        tapStock()
        expectCards(Self.stockSize, in: "stock")
        expectCards(0, in: "waste")
    }
}
