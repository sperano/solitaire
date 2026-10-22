import XCTest

final class UndoAndNewGameUITests: SolitaireUITestCase {
    func testNewGameWithoutMovesAsksNoConfirmation() {
        tap("newGameButton")
        XCTAssertFalse(element("confirmNewGameButton").waitForExistence(timeout: 1))
        expectCards(Self.stockSize, in: "stock")
        XCTAssertEqual(moves, "0")
    }

    func testNewGameAfterAMoveAsksConfirmationAndResets() {
        tapStock()
        XCTAssertEqual(moves, "1")
        tap("newGameButton")
        XCTAssertTrue(element("confirmNewGameButton").waitForExistence(timeout: Self.timeout))
        tap("confirmNewGameButton")
        XCTAssertEqual(moves, "0")
        expectCards(Self.stockSize, in: "stock")
        expectCards(0, in: "waste")
    }
}
