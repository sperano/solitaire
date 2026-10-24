import XCTest

/// Hardware keyboard shortcuts: the space bar draws, ⌘Z undoes and ⌘N asks for a new game.
final class KeyboardUITests: SolitaireUITestCase {
    private static let spaceKey = " "
    private static let undoKey = "z"
    private static let newGameKey = "n"
    /// After a launch, the first ⌘ keystroke XCUITest synthesizes usually does nothing (19 of 20
    /// launches), whether the shortcut is a scene command or a view's, and however long after the
    /// launch it comes; a second one works. Later ones are not lost (0 of 180).
    private static let commandKeyAttempts = 3
    private static let commandKeyWait: TimeInterval = 2

    override func setUp() async throws {
        try await super.setUp()
        primeTheCommandKey()
    }

    /// Gets the ⌘ key working before a test, with a keystroke whose effect shows: a draw by tap,
    /// then ⌘Z until it is undone. The tests' own keystrokes are each sent once.
    private func primeTheCommandKey() {
        tapStock()
        let undone = NSPredicate(format: "value == %@", Self.cardCount(0))
        for _ in 0 ..< Self.commandKeyAttempts {
            app.typeKey(Self.undoKey, modifierFlags: .command)
            let expectation = XCTNSPredicateExpectation(predicate: undone, object: element("waste"))
            if XCTWaiter().wait(for: [expectation], timeout: Self.commandKeyWait) == .completed {
                XCTAssertEqual(moves, "0")
                return
            }
        }
        // Never undone: the shortcut itself is broken, not just the first keystroke.
        XCTFail("⌘Z did not undo the draw in \(Self.commandKeyAttempts) tries")
    }

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
