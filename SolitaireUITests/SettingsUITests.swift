import XCTest

final class SettingsUITests: SolitaireUITestCase {
    private func openSettings() -> XCUIElement {
        tap("settingsButton")
        let picker = element("drawModePicker")
        XCTAssertTrue(picker.waitForExistence(timeout: Self.timeout))
        return picker
    }

    func testChoosingDrawThreeAppliesToTheNextGame() {
        let picker = openSettings()
        picker.buttons["Draw 3"].tap()
        tap("settingsDoneButton")

        tap("newGameButton")
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
}
