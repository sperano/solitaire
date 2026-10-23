import XCTest

final class SettingsUITests: SolitaireUITestCase {
    private func openSettings() -> XCUIElement {
        tap("settingsButton")
        let picker = element("drawModePicker")
        XCTAssertTrue(picker.waitForExistence(timeout: Self.timeout))
        return picker
    }

    func testChoosingDrawThreeAppliesToTheNextGame() {
        tapStock()
        expectCards(1, in: "waste")

        let picker = openSettings()
        picker.buttons["Draw 3"].tap()
        tap("settingsDoneButton")

        // The game in progress keeps drawing one card at a time.
        tapStock()
        expectCards(2, in: "waste")

        tap("newGameButton")
        tap("confirmNewGameButton")
        tapStock()
        expectCards(Self.cardsPerDrawThree, in: "waste")
        expectCards(Self.stockSize - Self.cardsPerDrawThree, in: "stock")
    }

    func testSettingsShowsTheSelectedDrawModeWhenReopened() {
        var picker = openSettings()
        XCTAssertTrue(picker.buttons["Draw 1"].isSelected)
        picker.buttons["Draw 3"].tap()
        tap("settingsDoneButton")

        picker = openSettings()
        XCTAssertTrue(picker.buttons["Draw 3"].isSelected)
        XCTAssertFalse(picker.buttons["Draw 1"].isSelected)
    }

    func testHapticsAreOnUntilTurnedOff() {
        _ = openSettings()
        let toggle = app.switches["hapticsToggle"]
        XCTAssertTrue(toggle.waitForExistence(timeout: Self.timeout))
        XCTAssertEqual(toggle.value as? String, "1")
        toggle.switches.firstMatch.tap()
        tap("settingsDoneButton")

        _ = openSettings()
        XCTAssertEqual(app.switches["hapticsToggle"].value as? String, "0")
    }
}
