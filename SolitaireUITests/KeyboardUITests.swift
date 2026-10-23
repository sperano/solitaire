import XCTest

/// Hardware keyboard shortcuts: the space bar draws, ⌘Z undoes and ⌘N asks for a new game.
final class KeyboardUITests: SolitaireUITestCase {
    private static let spaceKey = " "
    private static let undoKey = "z"
    private static let newGameKey = "n"

    func testSpaceDrawsAndCommandZUndoes() {
        expectCards(0, in: "waste")
        app.typeKey(Self.spaceKey, modifierFlags: [])
        expectCards(1, in: "waste")
        XCTAssertEqual(moves, "1")

        app.typeKey(Self.undoKey, modifierFlags: .command)
        expectCards(0, in: "waste")
        XCTAssertEqual(moves, "0")
    }

    func testCommandNAsksBeforeLosingAStartedGame() {
        tapStock()
        XCTAssertEqual(moves, "1")
        app.typeKey(Self.newGameKey, modifierFlags: .command)
        XCTAssertTrue(element("confirmNewGameButton").waitForExistence(timeout: Self.timeout))
        tap("confirmNewGameButton")
        XCTAssertEqual(moves, "0")
        expectCards(Self.stockSize, in: "stock")
    }

    func testShortcutsAreOffWhileSettingsIsOpen() {
        tap("settingsButton")
        XCTAssertTrue(element("settingsDoneButton").waitForExistence(timeout: Self.timeout))
        app.typeKey(Self.spaceKey, modifierFlags: [])
        tap("settingsDoneButton")
        expectCards(0, in: "waste")
        XCTAssertEqual(moves, "0")
    }
}
